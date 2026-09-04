#!/usr/bin/env bash
#
# Posts the one PR Lens comment on a pull request, or updates the one already
# there. Images are embedded as SHA-pinned github.com blob URLs with ?raw=true,
# the only form that renders for every viewer of a private repository;
# raw.githubusercontent.com links 404 without a token in the URL.
#
# Env: REPO (owner/name), PR_NUMBER, HEAD_SHA, DATA_SHA, ASSETS_DIR, GH_TOKEN.
# Optional: COMMENT_AUTHOR (default github-actions[bot]), MARKER.
set -euo pipefail

for v in REPO PR_NUMBER HEAD_SHA DATA_SHA ASSETS_DIR GH_TOKEN; do
  if [ -z "${!v:-}" ]; then
    echo "::error::${v} is required"
    exit 1
  fi
done
COMMENT_AUTHOR="${COMMENT_AUTHOR:-github-actions[bot]}"
MARKER="${MARKER:-<!-- pr-lens -->}"

manifest="${ASSETS_DIR}/manifest.json"
graph="${ASSETS_DIR}/drawn.graph.json"
for f in "${manifest}" "${graph}"; do
  if [ ! -f "${f}" ]; then
    echo "::error::${f} is missing; render before commenting."
    exit 1
  fi
done

# A run overtaken by a newer push has nothing useful to say: its diagrams show
# a commit that is no longer the head. Not knowing is a failure, not silence.
current="$(gh api "repos/${REPO}/pulls/${PR_NUMBER}" --jq .head.sha)"
if [ -z "${current}" ]; then
  echo "::error::GitHub named no head commit for #${PR_NUMBER}."
  exit 1
fi
if [ "${current}" != "${HEAD_SHA}" ]; then
  echo "::notice::#${PR_NUMBER} has moved on to ${current}; leaving the comment to the run drawing it."
  exit 0
fi

base="https://github.com/${REPO}/blob/${DATA_SHA}/pr/${PR_NUMBER}/${HEAD_SHA}"

# Root views open, their children collapsed one level down. Titles come from the
# document the diagrams were drawn from, so captions match the pictures.
body="$(jq -r \
  --arg base "${base}" \
  --arg marker "${MARKER}" \
  --arg head "${HEAD_SHA:0:8}" \
  --slurpfile m "${manifest}" '
  def asset($v; $t): [ $m[0].assets[] | select(.view == $v and .theme == $t) | .path ] | first // "";
  def block($v; $open):
    asset($v.id; "dark") as $d
    | asset($v.id; "light") as $l
    | if $d == "" then empty else
        "<details" + (if $open then " open" else "" end) + "><summary><b>" + ($v.title | @html) + "</b></summary>\n\n"
        + (if ($v.summary // "") == "" then "" else ($v.summary | @html) + "\n\n" end)
        + "<a href=\"" + $base + "/" + $d + "?raw=true\"><picture>"
        + "<source media=\"(prefers-color-scheme: dark)\" srcset=\"" + $base + "/" + $d + "?raw=true\">"
        + "<img alt=\"" + ($v.title | @html) + "\" src=\"" + $base + "/" + (if $l == "" then $d else $l end) + "?raw=true\">"
        + "</picture></a>\n\n</details>\n"
      end;
  [ $marker,
    "### PR Lens",
    "",
    "Architecture and data flow of this change at " + $head + ". Unchanged neighbours are drawn for blast radius. Click a diagram to open it full size.",
    "",
    (if (.summary // "") == "" then empty else "**What changed.** " + .summary end),
    "" ]
  + [ .views[] | block(.; true), ((.children // [])[] | block(.; false)) ]
  + [ "<sub>Rendered by <a href=\"https://prlens.dev/\">PR Lens</a> from the diff. Wrong node or lane? Correct .github/pr-lens.yml, not the picture.</sub>" ]
  | join("\n")' "${graph}")"

# Only a comment this identity owns is ever edited; a marker on somebody else's
# comment is not ours.
# gh api's --jq takes no --arg, so the filter runs in jq itself, over every page.
existing="$(gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" --paginate --jq '.[]' \
  | jq -rs --arg a "${COMMENT_AUTHOR}" --arg m "${MARKER}" \
    '[ .[] | select(.user.login == $a) | select(.body | startswith($m)) ] | first | .id // empty')"

if [ -n "${existing}" ]; then
  printf '%s' "${body}" | jq -Rs '{body: .}' \
    | gh api -X PATCH "repos/${REPO}/issues/comments/${existing}" --input - --silent
  echo "Updated comment ${existing} on #${PR_NUMBER}."
else
  printf '%s' "${body}" | jq -Rs '{body: .}' \
    | gh api -X POST "repos/${REPO}/issues/${PR_NUMBER}/comments" --input - --silent
  echo "Posted a new comment on #${PR_NUMBER}."
fi

#!/usr/bin/env bash
#
# Publishes rendered PR Lens SVGs to an orphan data branch that holds no code:
# one directory per pull request per head commit. GitHub caches comment images
# by URL and never revalidates, so a changed diagram must arrive at a new URL;
# the renderer names every file by content hash, so a directory is written once.
#
# Env: REPO (owner/name), PR_NUMBER, HEAD_SHA, DATA_BRANCH, ASSETS_DIR, GITHUB_TOKEN.
# Prints data_sha=<tip of the data branch> and appends it to GITHUB_OUTPUT when set.
set -euo pipefail

for v in REPO PR_NUMBER HEAD_SHA DATA_BRANCH ASSETS_DIR GITHUB_TOKEN; do
  if [ -z "${!v:-}" ]; then
    echo "::error::${v} is required"
    exit 1
  fi
done

shopt -s nullglob
svgs=("${ASSETS_DIR}"/*.svg)
if [ "${#svgs[@]}" -eq 0 ]; then
  echo "::error::No SVGs in ${ASSETS_DIR}; nothing to publish."
  exit 1
fi

dir="pr/${PR_NUMBER}/${HEAD_SHA}"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
remote="https://x-access-token:${GITHUB_TOKEN}@github.com/${REPO}.git"
data_sha=""

# Every run of every pull request shares one branch, so losing the push race is
# ordinary: pick the tip up again and replay. Two runs never write the same path.
for attempt in 1 2 3 4 5; do
  rm -rf "${work}"
  mkdir -p "${work}"
  git -C "${work}" init --quiet
  git -C "${work}" config user.name "github-actions[bot]"
  git -C "${work}" config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git -C "${work}" remote add origin "${remote}"
  if git -C "${work}" fetch --quiet --depth=1 origin "${DATA_BRANCH}" 2>/dev/null; then
    git -C "${work}" checkout --quiet -b "${DATA_BRANCH}" FETCH_HEAD
  else
    git -C "${work}" checkout --quiet --orphan "${DATA_BRANCH}"
  fi
  mkdir -p "${work}/${dir}"
  cp "${svgs[@]}" "${work}/${dir}/"
  git -C "${work}" add "${dir}"
  if git -C "${work}" diff --quiet --cached; then
    data_sha="$(git -C "${work}" rev-parse HEAD)"
    echo "This render is already published at ${data_sha}."
    break
  fi
  git -C "${work}" commit --quiet -m "PR Lens: #${PR_NUMBER} at ${HEAD_SHA}"
  if git -C "${work}" push --quiet origin "${DATA_BRANCH}" 2>/dev/null; then
    data_sha="$(git -C "${work}" rev-parse HEAD)"
    break
  fi
  echo "${DATA_BRANCH} moved under this run; retrying (${attempt}/5)."
  sleep "$((attempt * 3))"
done

if [ -z "${data_sha}" ]; then
  echo "::error::Could not publish the diagrams: ${DATA_BRANCH} kept moving."
  exit 1
fi

echo "data_sha=${data_sha}"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "data_sha=${data_sha}" >> "${GITHUB_OUTPUT}"
fi

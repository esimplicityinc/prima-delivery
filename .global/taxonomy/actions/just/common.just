# Common helpers for Just-based automation.

# Emit a banner similar to the STEP macro in Makefiles.
BANNER_DEF := '''
banner() {
  local message="$1"
  printf '\n\033[1;36m%s\033[0m\n' "$(printf '#%.0s' $(seq 1 ${BANNER_WIDTH:-60}))"
  printf '\033[1;36m## %s ##\033[0m\n' "$message"
  printf '\033[1;36m%s\033[0m\n' "$(printf '#%.0s' $(seq 1 ${BANNER_WIDTH:-60}))"
}
'''

# Convenience helper to raise a consistent "not yet implemented" error from
# placeholder recipes. Call with the module/recipe identifier for clarity.
TODO_DEF := '''
todo() {
  local recipe="$1"
  >&2 printf '\033[1;33mTODO:\033[0m %s\n' "$recipe"
  exit 2
}
'''

ENV_HELPERS := '''
	REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
	ENV_UTILS="$REPO_ROOT/.global/taxonomy/actions/just/scripts/env-utils.sh"
	if [ -f "$ENV_UTILS" ]; then
	  . "$ENV_UTILS"
	fi
'''

LOG_HELPERS := '''
	log_step() {
	  local message="$1"
	  printf '\033[1;35m» %s\033[0m\n' "$message"
	}

	log_substep() {
	  local message="$1"
	  printf '   \033[0;36m- %s\033[0m\n' "$message"
	}

	log_warn() {
	  local message="$1"
	  printf '\033[1;33m! %s\033[0m\n' "$message"
	}

	log_error() {
	  local message="$1"
	  printf '\033[1;31m✖ %s\033[0m\n' "$message"
	}
'''

LAYER_ENV_HELPERS := '''
	resolve_layer_env() {
	  local default="${1:-dev}"
	  if [ -n "${ENV:-}" ]; then
	    printf '%s\n' "$ENV"
	    return 0
	  fi
	  printf '%s\n' "$default"
	}
'''

AUTO_LAYER_README_HELPERS := '''
	update_auto_layer_section_from_file() {
	  local readme_path="$1"
	  local block_label="${2:-}"
	  local content_file="$3"
	  local repo_root="${REPO_ROOT:-$(pwd)}"
	  if [ ! -f "$content_file" ]; then
	    printf '\033[1;31m✖ Content file not found: %s\033[0m\n' "$content_file" >&2
	    exit 1
	  fi
	  python3 - "$readme_path" "$block_label" "$content_file" "$repo_root" <<'PY'
import re
import sys
from pathlib import Path

readme_arg, block_label, content_arg, repo_root_arg = sys.argv[1:5]
readme = Path(readme_arg)
block_label = block_label or ""
content_path = Path(content_arg)
repo_root = Path(repo_root_arg).resolve()

content = content_path.read_text(encoding="utf-8").rstrip()

begin = f"<!-- BEGIN AUTO-LAYER:{block_label} -->" if block_label else "<!-- BEGIN AUTO-LAYER -->"
end = f"<!-- END AUTO-LAYER:{block_label} -->" if block_label else "<!-- END AUTO-LAYER -->"
managed = "<!-- This section is managed by scripts. Manual edits inside may be overwritten. -->"
block = f"{begin}\n{managed}\n\n{content}\n\n{end}\n"

if not readme.exists():
    rel = ""
    try:
        rel = readme.parent.resolve().relative_to(repo_root)
    except ValueError:
        rel = readme.parent.name
    if not rel:
        rel = readme.parent.name or "Layer"
    heading = f"# {rel} layer"
    readme.parent.mkdir(parents=True, exist_ok=True)
    readme.write_text(f"{heading}\n\n", encoding="utf-8")

text = readme.read_text(encoding="utf-8")
pattern = re.compile(rf"{re.escape(begin)}.*?{re.escape(end)}", re.DOTALL)
replacement = block.rstrip() + "\n"

if pattern.search(text):
    updated = pattern.sub(replacement, text, count=1)
else:
    if not text.endswith("\n"):
        text += "\n"
    if not text.endswith("\n\n"):
        text += "\n"
    updated = text + replacement

readme.write_text(updated, encoding="utf-8")
PY
	}
'''

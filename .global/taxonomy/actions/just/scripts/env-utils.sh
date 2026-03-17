#!/usr/bin/env bash
# env-utils.sh — Environment utilities for Katalyst Just recipes.
#
# Sourced by common.just when present. Provides helpers that layer-type
# recipes depend on (e.g., reading values from environments.yaml).

# read_environment_value KEY [ENVIRONMENT]
#
# Reads a dotted key (e.g., "spec.layerTemplates.app-docker.imageRegistry")
# from the taxonomy environments.yaml for the given ENVIRONMENT.
#
# Falls back to the ENV variable or "dev" when ENVIRONMENT is omitted.
read_environment_value() {
  local key="$1"
  local env_name="${2:-${ENV:-dev}}"
  local repo_root="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
  local env_file="$repo_root/.global/taxonomy/environments.yaml"

  if [ ! -f "$env_file" ]; then
    return 1
  fi

  # Use Python to parse the multi-document YAML and extract the value.
  python3 - "$env_file" "$env_name" "$key" 2>/dev/null <<'PY'
import sys, yaml
from pathlib import Path

env_file, target_env, dotted_key = sys.argv[1], sys.argv[2], sys.argv[3]
keys = dotted_key.split(".")

for doc in yaml.safe_load_all(Path(env_file).read_text()):
    if not isinstance(doc, dict):
        continue
    name = (doc.get("metadata") or {}).get("name", "")
    if name != target_env:
        continue
    node = doc
    for k in keys:
        if not isinstance(node, dict):
            sys.exit(1)
        node = node.get(k)
        if node is None:
            sys.exit(1)
    print(node)
    sys.exit(0)

sys.exit(1)
PY
}

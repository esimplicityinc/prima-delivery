import "./common.just"

LAYER_DOCUMENTATION_HELPERS := '''
	layer_types_manifest_default="$REPO_ROOT/.global/taxonomy/layerTypes/layer-types.yaml"

	list_layers_for_type() {
	  local target_type="$1"
	  local manifest_root="${2:-$REPO_ROOT}"
	  python3 - "$manifest_root" "$target_type" <<'PY'
from __future__ import annotations

import fnmatch
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List

import yaml

repo_root = Path(sys.argv[1]).resolve()
target_type = sys.argv[2]

DEFAULT_SKIP = {".git", ".hg", ".svn", ".idea", "__pycache__", ".venv", "node_modules"}


@dataclass(frozen=True)
class Rule:
    base: Path
    pattern: str
    negated: bool
    dir_only: bool
    anchored: bool

    def matches(self, path: Path, is_dir: bool) -> bool:
        try:
            rel = path.relative_to(self.base)
        except ValueError:
            return False
        if self.dir_only and not is_dir:
            return False
        rel_str = rel.as_posix() or "."
        pattern = self.pattern
        if self.anchored or "/" in pattern:
            target = rel_str
            return fnmatch.fnmatch(target, pattern)
        if fnmatch.fnmatch(path.name, pattern):
            return True
        for part in rel_str.split("/"):
            if fnmatch.fnmatch(part, pattern):
                return True
        return False


def parse_taxignore(path: Path) -> list[Rule]:
    rules: list[Rule] = []
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except FileNotFoundError:
        return rules
    for raw in lines:
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        negated = stripped.startswith("!")
        if negated:
            stripped = stripped[1:]
        dir_only = stripped.endswith("/")
        if dir_only:
            stripped = stripped.rstrip("/")
        anchored = stripped.startswith("/")
        if anchored:
            stripped = stripped.lstrip("/")
        if not stripped:
            continue
        rules.append(
            Rule(
                base=path.parent,
                pattern=stripped,
                negated=negated,
                dir_only=dir_only,
                anchored=anchored,
            )
        )
    return rules


def is_ignored(path: Path, *, is_dir: bool, rules: Iterable[Rule]) -> bool:
    ignored = False
    for rule in rules:
        if rule.matches(path, is_dir):
            ignored = not rule.negated
    return ignored


def load_layer_document(layer_file: Path) -> dict | None:
    try:
        with layer_file.open("r", encoding="utf-8") as stream:
            for raw in yaml.safe_load_all(stream):
                if isinstance(raw, dict) and raw.get("taxonomyNodeType") == "layer":
                    return raw
    except (OSError, yaml.YAMLError):
        return None
    return None


def walk(directory: Path, rules: List[Rule], results: list[Path]) -> None:
    current_rules = list(rules)
    taxignore = directory / ".taxignore"
    current_rules.extend(parse_taxignore(taxignore))

    layer_file = directory / "layer.yaml"
    if layer_file.exists() and not is_ignored(layer_file, is_dir=False, rules=current_rules):
        document = load_layer_document(layer_file)
        if document:
            spec = document.get("spec") or {}
            layer_type = spec.get("layerType") or spec.get("type") or ""
            if layer_type == target_type:
                results.append(directory)

    for child in sorted(directory.iterdir()):
        if child.is_symlink():
            continue
        if child.is_dir():
            if child.name in DEFAULT_SKIP:
                continue
            if is_ignored(child, is_dir=True, rules=current_rules):
                continue
            walk(child, current_rules, results)


results: list[Path] = []
walk(repo_root, [], results)

seen = []
for path in results:
    try:
        rel = path.relative_to(repo_root)
    except ValueError:
        rel = path
    rel_str = rel.as_posix()
    if rel_str not in seen:
        seen.append(rel_str)

for rel in sorted(seen):
    print(rel)
PY
	}

	generate_layer_doc_content() {
	  local layer_dir="$1"
	  local manifest_file="${LAYER_TYPES_MANIFEST:-$layer_types_manifest_default}"
	  python3 - "$REPO_ROOT" "$layer_dir" "$manifest_file" <<'PY'
import sys
from pathlib import Path

import yaml

repo_root = Path(sys.argv[1]).resolve()
layer_dir = Path(sys.argv[2]).resolve()
manifest_path = Path(sys.argv[3]).resolve()

layer_file = layer_dir / "layer.yaml"
if not layer_file.exists():
    raise SystemExit(f"layer.yaml not found in {layer_dir}")

def _load_layer_document(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as stream:
        for raw in yaml.safe_load_all(stream):
            if isinstance(raw, dict) and raw.get("taxonomyNodeType") == "layer":
                return raw
    raise SystemExit(f"No layer taxonomy document found in {path}")

def _load_layer_types(path: Path) -> dict[str, dict]:
    result: dict[str, dict] = {}
    with path.open("r", encoding="utf-8") as stream:
        for raw in yaml.safe_load_all(stream):
            if not isinstance(raw, dict):
                continue
            metadata = raw.get("metadata")
            spec = raw.get("spec")
            if not isinstance(metadata, dict) or not isinstance(spec, dict):
                continue
            name = metadata.get("name")
            if isinstance(name, str) and name:
                result[name] = raw
    return result

document = _load_layer_document(layer_file)
spec = document.get("spec") or {}
metadata = document.get("metadata") or {}
layer_type = spec.get("layerType") or spec.get("type") or "unknown"
layer_types = _load_layer_types(manifest_path)
layer_type_doc = layer_types.get(layer_type)
layer_type_spec = layer_type_doc.get("spec") if isinstance(layer_type_doc, dict) else {}

def _format_list(values, empty="_none declared_"):
    if not values:
        return empty
    return ", ".join(f"`{item}`" for item in values)

rel_path = ""
try:
    rel_path = layer_dir.relative_to(repo_root)
except ValueError:
    rel_path = str(layer_dir)

description = spec.get("description") or ""
depends_on = []
depends_spec = spec.get("dependsOn")
if isinstance(depends_spec, dict):
    nodes = depends_spec.get("nodes")
    if isinstance(nodes, list):
        depends_on = [str(node) for node in nodes if node]

owners = []
owners_raw = spec.get("owners")
if isinstance(owners_raw, list):
    owners = [str(owner) for owner in owners_raw if owner]

annotations = {}
annotations_raw = spec.get("annotations")
if isinstance(annotations_raw, dict):
    annotations = {str(k): str(v) for k, v in annotations_raw.items()}

environments = []
env_raw = spec.get("environments")
if isinstance(env_raw, list):
    environments = [str(env) for env in env_raw if env]

parent = ""
parents_raw = spec.get("parents")
if isinstance(parents_raw, dict):
    parent = parents_raw.get("node") or ""

template_root = ""
optional_paths: list[str] = []
if isinstance(layer_type_spec, dict):
    template_root = layer_type_spec.get("template") or ""
    optional_raw = layer_type_spec.get("optionalPaths")
    if isinstance(optional_raw, list):
        optional_paths = [str(item) for item in optional_raw if item]
layer_type_description = ""
if isinstance(layer_type_spec, dict):
    layer_type_description = layer_type_spec.get("description") or ""

lines: list[str] = []
lines.append("### Layer Overview")
lines.append("")
lines.append("| Field | Value |")
lines.append("| --- | --- |")
lines.append(f"| Layer path | `{rel_path}` |")
if parent:
    lines.append(f"| Parent node | `{parent}` |")
summary = f"`{layer_type}`"
if layer_type_description:
    summary += f" — {layer_type_description}"
lines.append(f"| Layer type | {summary} |")
lines.append(f"| Description | {description.strip() if description else '_none_'} |")
lines.append(f"| Environments | {_format_list(environments, '_none declared_')} |")
lines.append(f"| Depends on | {_format_list(depends_on, '_none declared_')} |")
lines.append(f"| Owners | {_format_list(owners, '_none listed_')} |")
lines.append(f"| Template root | {f'`{template_root}`' if template_root else '_unspecified_'} |")
lines.append(f"| Optional template paths | {_format_list(optional_paths, '_none_')} |")

if annotations:
    annot_str = ", ".join(f"`{k}`: `{annotations[k]}`" for k in sorted(annotations))
    lines.append(f"| Annotations | {annot_str} |")

lines.append("")
lines.append("#### Environment overlays")
lines.append("")
lines.append("| Environment | Status | Directory |")
lines.append("| --- | --- | --- |")
if environments:
    for env in environments:
        candidate = layer_dir / env
        exists = candidate.exists()
        status = "present" if exists else "missing"
        rel_candidate = env
        if exists:
            rel_candidate = candidate.relative_to(layer_dir).as_posix()
            dir_val = f"[`{rel_candidate}`](./{rel_candidate})"
        else:
            dir_val = f"`{rel_candidate}`"
        lines.append(f"| `{env}` | {status} | {dir_val} |")
else:
    lines.append("| _none declared_ | – | – |")

print("\\n".join(lines).rstrip())
PY
	}
'''

import "../common.just"

# docs-subsystem layer recipes.
# Provides commands for validating and linting subsystem-level documentation.

DOCS_SUBSYSTEM_LAYER_SETUP := '''
setup_docs_subsystem_layer_context() {
  ENVIRONMENT="$(resolve_layer_env local)"
  local requested_layer="${DOCS_LAYER_DIR:-}"
  local stack_dir="${STACK_DIR:-}"
  if [ -z "$stack_dir" ] && [ -n "$requested_layer" ]; then
    stack_dir="$(cd "$(dirname "$requested_layer")" >/dev/null 2>&1 && pwd)"
  fi
  stack_dir="${stack_dir:-$PWD}"
  STACK_DIR="$stack_dir"
  local default_layer_dir="$STACK_DIR/docs"
  LAYER_DIR="${requested_layer:-$default_layer_dir}"
  if [ ! -d "$LAYER_DIR" ]; then
    printf '\\033[1;31mError:\\033[0m docs-subsystem layer directory not found: %s\\n' "$LAYER_DIR" >&2
    exit 1
  fi
  LAYER_DIR="$(cd "$LAYER_DIR" >/dev/null 2>&1 && pwd)"
  STACK_NAME="${STACK_NAME:-$(basename "$STACK_DIR")}"
  LAYER_NAME="${LAYER_NAME:-$(basename "$LAYER_DIR")}"

  export DOCS_WORKDIR="$LAYER_DIR"

  log_substep "docs-subsystem layer: $LAYER_DIR"
  log_substep "docs-subsystem environment: $ENVIRONMENT"
}

check_required_files() {
  local missing=0
  local required_files="user/index.md"
  
  for file in $required_files; do
    if [ ! -f "$LAYER_DIR/$file" ]; then
      printf '\\033[1;33mWarning:\\033[0m Required file missing: %s\\n' "$file" >&2
      missing=$((missing + 1))
    fi
  done
  
  return $missing
}

check_frontmatter() {
  local file="$1"
  if ! head -1 "$file" | grep -q "^---$"; then
    printf '\\033[1;33mWarning:\\033[0m Missing frontmatter in: %s\\n' "$file" >&2
    return 1
  fi
  return 0
}
'''

# Validation commands
docs-subsystem-validate:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_SUBSYSTEM_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_subsystem_layer_context
	log_step "Validating docs-subsystem layer structure"
	
	errors=0
	
	# Check layer.yaml exists
	if [ ! -f "$LAYER_DIR/layer.yaml" ]; then
	  log_substep "Error: layer.yaml not found"
	  errors=$((errors + 1))
	else
	  log_substep "✓ layer.yaml found"
	fi
	
	# Check required directories
	for dir in user taxonomy; do
	  if [ ! -d "$LAYER_DIR/$dir" ]; then
	    log_substep "Error: $dir/ directory not found"
	    errors=$((errors + 1))
	  else
	    log_substep "✓ $dir/ directory found"
	  fi
	done
	
	# Check required files
	if check_required_files; then
	  log_substep "✓ All required files present"
	else
	  errors=$((errors + 1))
	fi
	
	if [ $errors -gt 0 ]; then
	  log_step "Validation failed with $errors error(s)"
	  exit 1
	fi
	
	log_step "docs-subsystem validation passed"

docs-subsystem-lint:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_SUBSYSTEM_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_subsystem_layer_context
	log_step "Linting docs-subsystem layer"
	
	warnings=0
	
	# Check frontmatter in all markdown files
	while IFS= read -r -d '' file; do
	  if ! check_frontmatter "$file"; then
	    warnings=$((warnings + 1))
	  fi
	done < <(find "$LAYER_DIR" -name "*.md" -print0)
	
	if [ $warnings -gt 0 ]; then
	  log_step "Linting completed with $warnings warning(s)"
	else
	  log_step "docs-subsystem linting passed"
	fi

docs-subsystem-list:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_SUBSYSTEM_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_subsystem_layer_context
	log_step "Listing docs in subsystem"
	
	echo ""
	echo "User Documentation:"
	find "$LAYER_DIR/user" -name "*.md" 2>/dev/null | sort | while read -r file; do
	  title=$(grep -m1 "^title:" "$file" 2>/dev/null | sed 's/title: *["]*//;s/["]*$//' || basename "$file")
	  printf "  - %s (%s)\n" "$title" "${file#$LAYER_DIR/}"
	done
	
	echo ""
	echo "Taxonomy Documentation:"
	find "$LAYER_DIR/taxonomy" -name "*.md" 2>/dev/null | sort | while read -r file; do
	  title=$(grep -m1 "^title:" "$file" 2>/dev/null | sed 's/title: *["]*//;s/["]*$//' || basename "$file")
	  printf "  - %s (%s)\n" "$title" "${file#$LAYER_DIR/}"
	done

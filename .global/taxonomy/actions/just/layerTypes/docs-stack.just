import "../common.just"

# docs-stack layer recipes.
# Provides commands for validating and linting stack-level documentation.

DOCS_STACK_LAYER_SETUP := '''
setup_docs_stack_layer_context() {
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
    printf '\\033[1;31mError:\\033[0m docs-stack layer directory not found: %s\\n' "$LAYER_DIR" >&2
    exit 1
  fi
  LAYER_DIR="$(cd "$LAYER_DIR" >/dev/null 2>&1 && pwd)"
  STACK_NAME="${STACK_NAME:-$(basename "$STACK_DIR")}"
  LAYER_NAME="${LAYER_NAME:-$(basename "$LAYER_DIR")}"

  # docs-stack has content in docs/ subdirectory
  DOCS_CONTENT_DIR="$LAYER_DIR/docs"
  if [ ! -d "$DOCS_CONTENT_DIR" ]; then
    DOCS_CONTENT_DIR="$LAYER_DIR"
  fi

  export DOCS_WORKDIR="$LAYER_DIR"
  export DOCS_CONTENT_DIR

  log_substep "docs-stack layer: $LAYER_DIR"
  log_substep "docs-stack content: $DOCS_CONTENT_DIR"
  log_substep "docs-stack environment: $ENVIRONMENT"
}

check_required_files() {
  local missing=0
  local required_files="user/index.md taxonomy/index.md"
  
  for file in $required_files; do
    if [ ! -f "$DOCS_CONTENT_DIR/$file" ]; then
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

check_doc_type() {
  local file="$1"
  if ! grep -q "^doc_type:" "$file" 2>/dev/null; then
    printf '\\033[1;33mWarning:\\033[0m Missing doc_type in: %s\\n' "$file" >&2
    return 1
  fi
  return 0
}
'''

# Validation commands
docs-stack-validate:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_STACK_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_stack_layer_context
	log_step "Validating docs-stack layer structure"
	
	errors=0
	
	# Check layer.yaml exists
	if [ ! -f "$LAYER_DIR/layer.yaml" ]; then
	  log_substep "Error: layer.yaml not found"
	  errors=$((errors + 1))
	else
	  log_substep "✓ layer.yaml found"
	fi
	
	# Check sidebars config exists
	if [ -f "$LAYER_DIR/sidebars.ts" ] || [ -f "$LAYER_DIR/sidebars.js" ]; then
	  log_substep "✓ sidebars config found"
	else
	  log_substep "Warning: sidebars.ts/js not found"
	fi
	
	# Check required directories
	for dir in user taxonomy; do
	  if [ ! -d "$DOCS_CONTENT_DIR/$dir" ]; then
	    log_substep "Error: $dir/ directory not found in content"
	    errors=$((errors + 1))
	  else
	    log_substep "✓ $dir/ directory found"
	  fi
	done
	
	# Check taxonomy subdirectories
	for dir in adrs capabilities domain; do
	  if [ -d "$DOCS_CONTENT_DIR/taxonomy/$dir" ]; then
	    log_substep "✓ taxonomy/$dir/ directory found"
	  else
	    log_substep "Note: taxonomy/$dir/ not found (optional)"
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
	
	log_step "docs-stack validation passed"

docs-stack-lint:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_STACK_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_stack_layer_context
	log_step "Linting docs-stack layer"
	
	warnings=0
	checked=0
	
	# Check frontmatter and doc_type in all markdown files
	while IFS= read -r -d '' file; do
	  checked=$((checked + 1))
	  if ! check_frontmatter "$file"; then
	    warnings=$((warnings + 1))
	  elif ! check_doc_type "$file"; then
	    warnings=$((warnings + 1))
	  fi
	done < <(find "$DOCS_CONTENT_DIR" -name "*.md" -print0 2>/dev/null)
	
	log_substep "Checked $checked markdown files"
	
	if [ $warnings -gt 0 ]; then
	  log_step "Linting completed with $warnings warning(s)"
	else
	  log_step "docs-stack linting passed"
	fi

docs-stack-list:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_STACK_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_stack_layer_context
	log_step "Listing docs in stack"
	
	echo ""
	echo "User Documentation:"
	find "$DOCS_CONTENT_DIR/user" -name "*.md" 2>/dev/null | sort | while read -r file; do
	  title=$(grep -m1 "^title:" "$file" 2>/dev/null | sed 's/title: *["]*//;s/["]*$//' || basename "$file")
	  printf "  - %s (%s)\n" "$title" "${file#$DOCS_CONTENT_DIR/}"
	done
	
	echo ""
	echo "Taxonomy - ADRs:"
	find "$DOCS_CONTENT_DIR/taxonomy/adrs" -name "*.md" 2>/dev/null | sort | while read -r file; do
	  title=$(grep -m1 "^title:" "$file" 2>/dev/null | sed 's/title: *["]*//;s/["]*$//' || basename "$file")
	  status=$(grep -m1 "status:" "$file" 2>/dev/null | head -1 | sed 's/.*status: *//;s/ *$//' || echo "-")
	  printf "  - %s [%s] (%s)\n" "$title" "$status" "${file#$DOCS_CONTENT_DIR/}"
	done
	
	echo ""
	echo "Taxonomy - Capabilities:"
	find "$DOCS_CONTENT_DIR/taxonomy/capabilities" -name "*.md" 2>/dev/null | sort | while read -r file; do
	  title=$(grep -m1 "^title:" "$file" 2>/dev/null | sed 's/title: *["]*//;s/["]*$//' || basename "$file")
	  printf "  - %s (%s)\n" "$title" "${file#$DOCS_CONTENT_DIR/}"
	done
	
	echo ""
	echo "Taxonomy - Domain:"
	find "$DOCS_CONTENT_DIR/taxonomy/domain" -name "*.md" 2>/dev/null | sort | while read -r file; do
	  title=$(grep -m1 "^title:" "$file" 2>/dev/null | sed 's/title: *["]*//;s/["]*$//' || basename "$file")
	  printf "  - %s (%s)\n" "$title" "${file#$DOCS_CONTENT_DIR/}"
	done

docs-stack-stats:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_STACK_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_stack_layer_context
	log_step "Documentation statistics"
	
	echo ""
	printf "%-20s %s\n" "Category" "Count"
	printf "%-20s %s\n" "--------" "-----"
	
	user_count=$(find "$DOCS_CONTENT_DIR/user" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-20s %s\n" "User docs" "$user_count"
	
	adr_count=$(find "$DOCS_CONTENT_DIR/taxonomy/adrs" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-20s %s\n" "ADRs" "$adr_count"
	
	cap_count=$(find "$DOCS_CONTENT_DIR/taxonomy/capabilities" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-20s %s\n" "Capabilities" "$cap_count"
	
	domain_count=$(find "$DOCS_CONTENT_DIR/taxonomy/domain" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-20s %s\n" "Domain docs" "$domain_count"
	
	total=$((user_count + adr_count + cap_count + domain_count))
	printf "%-20s %s\n" "--------" "-----"
	printf "%-20s %s\n" "Total" "$total"

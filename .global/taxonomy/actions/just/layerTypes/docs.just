import "../common.just"
import "../tools/npm.just"

# docs layer type recipes.
# Provides commands for developing, building, and serving documentation with
# composable views, DDD artifacts, roadmap tracking, and agent changelogs.
#
# This layer type replaces docs-stack and docs-subsystem (both deprecated).

DOCS_LAYER_SETUP := '''
setup_docs_layer_context() {
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
    printf '\033[1;31mError:\033[0m docs layer directory not found: %s\n' "$LAYER_DIR" >&2
    exit 1
  fi
  LAYER_DIR="$(cd "$LAYER_DIR" >/dev/null 2>&1 && pwd)"
  STACK_NAME="${STACK_NAME:-$(basename "$STACK_DIR")}"
  LAYER_NAME="${LAYER_NAME:-$(basename "$LAYER_DIR")}"

  # docs layer has content in docs/ subdirectory
  DOCS_CONTENT_DIR="$LAYER_DIR/docs"
  if [ ! -d "$DOCS_CONTENT_DIR" ]; then
    DOCS_CONTENT_DIR="$LAYER_DIR"
  fi

  export NPM_WORKDIR="$LAYER_DIR"
  export DOCS_WORKDIR="$LAYER_DIR"
  export DOCS_CONTENT_DIR

  # Docusaurus configuration
  DOCS_PORT="${DOCS_PORT:-3000}"
  DOCS_HOST="${DOCS_HOST:-localhost}"

  log_substep "docs layer: $LAYER_DIR"
  log_substep "docs content: $DOCS_CONTENT_DIR"
  log_substep "docs environment: $ENVIRONMENT"
}

ensure_docusaurus() {
  if [ ! -f "$LAYER_DIR/docusaurus.config.ts" ] && [ ! -f "$LAYER_DIR/docusaurus.config.js" ]; then
    printf '\033[1;31mError:\033[0m docusaurus.config.ts/js not found in %s\n' "$LAYER_DIR" >&2
    exit 1
  fi
}

check_required_files() {
  local missing=0
  local required_files="index.md"
  
  for file in $required_files; do
    if [ ! -f "$DOCS_CONTENT_DIR/$file" ]; then
      printf '\033[1;33mWarning:\033[0m Required file missing: %s\n' "$file" >&2
      missing=$((missing + 1))
    fi
  done
  
  return $missing
}

check_frontmatter() {
  local file="$1"
  if ! head -1 "$file" | grep -q "^---$"; then
    printf '\033[1;33mWarning:\033[0m Missing frontmatter in: %s\n' "$file" >&2
    return 1
  fi
  return 0
}

check_doc_type() {
  local file="$1"
  if ! grep -q "^doc_type:" "$file" 2>/dev/null; then
    printf '\033[1;33mWarning:\033[0m Missing doc_type in: %s\n' "$file" >&2
    return 1
  fi
  return 0
}
'''

# =============================================================================
# Development Commands
# =============================================================================

docs-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	log_step "Installing docs dependencies"
	just npm-install

docs-install-ci:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	log_step "Installing docs dependencies (CI mode)"
	just npm-install-ci

docs-dev:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	ensure_docusaurus
	log_step "Starting docs development server"
	(cd "$LAYER_DIR" && npm start -- --host "$DOCS_HOST" --port "$DOCS_PORT")

docs-start:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	ensure_docusaurus
	log_step "Starting docs development server"
	(cd "$LAYER_DIR" && npm start)

docs-build:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	ensure_docusaurus
	log_step "Building docs site"
	(cd "$LAYER_DIR" && npm run build)

docs-serve:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	ensure_docusaurus
	log_step "Serving docs production build"
	(cd "$LAYER_DIR" && npm run serve)

docs-clear:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	ensure_docusaurus
	log_step "Clearing docs cache"
	(cd "$LAYER_DIR" && npm run clear)

docs-clean:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	log_step "Cleaning docs artifacts"
	(cd "$LAYER_DIR" && rm -rf build .docusaurus node_modules)

docs-typecheck:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	log_step "Running TypeScript type check"
	(cd "$LAYER_DIR" && npm run typecheck)

# =============================================================================
# Validation Commands
# =============================================================================

docs-validate:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	log_step "Validating docs layer structure"
	
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
	  if [ -d "$DOCS_CONTENT_DIR/$dir" ]; then
	    log_substep "✓ $dir/ directory found"
	  else
	    log_substep "Note: $dir/ directory not found (recommended)"
	  fi
	done
	
	# Check taxonomy subdirectories
	for dir in adrs capabilities domain events architecture integration patterns; do
	  if [ -d "$DOCS_CONTENT_DIR/taxonomy/$dir" ]; then
	    log_substep "✓ taxonomy/$dir/ directory found"
	  fi
	done
	
	# Check roadmap and changelog directories (new in docs layer type)
	for dir in roadmap changelog; do
	  if [ -d "$DOCS_CONTENT_DIR/$dir" ]; then
	    log_substep "✓ $dir/ directory found"
	  else
	    log_substep "Note: $dir/ directory not found (recommended)"
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
	
	log_step "docs validation passed"

docs-lint:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	log_step "Linting docs layer"
	
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
	  log_step "docs linting passed"
	fi

# =============================================================================
# Aggregation Commands (for composable documentation)
# =============================================================================

docs-aggregate:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	log_step "Aggregating child documentation"
	
	# Find child docs layers and copy their content
	# This is used by subsystem docs to aggregate stack docs
	AGGREGATE_DIR="$LAYER_DIR/.aggregated"
	rm -rf "$AGGREGATE_DIR"
	mkdir -p "$AGGREGATE_DIR"
	
	# Look for child stack docs
	parent_dir="$(dirname "$STACK_DIR")"
	for stack_dir in "$parent_dir"/*/docs; do
	  if [ -d "$stack_dir" ] && [ "$stack_dir" != "$LAYER_DIR" ]; then
	    stack_name="$(basename "$(dirname "$stack_dir")")"
	    log_substep "Aggregating: $stack_name"
	    mkdir -p "$AGGREGATE_DIR/$stack_name"
	    if [ -d "$stack_dir/docs" ]; then
	      cp -r "$stack_dir/docs"/* "$AGGREGATE_DIR/$stack_name/" 2>/dev/null || true
	    fi
	  fi
	done
	
	log_step "Aggregation complete: $AGGREGATE_DIR"

docs-changelog-aggregate:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	log_step "Generating combined changelog view"
	
	# Collect all changelog entries from child docs
	COMBINED_CHANGELOG="$DOCS_CONTENT_DIR/changelog/_combined.md"
	
	echo "---" > "$COMBINED_CHANGELOG"
	echo "title: Combined Changelog" >> "$COMBINED_CHANGELOG"
	echo "sidebar_position: 0" >> "$COMBINED_CHANGELOG"
	echo "---" >> "$COMBINED_CHANGELOG"
	echo "" >> "$COMBINED_CHANGELOG"
	echo "# Combined Changelog" >> "$COMBINED_CHANGELOG"
	echo "" >> "$COMBINED_CHANGELOG"
	echo "Aggregated activity from all child documentation layers." >> "$COMBINED_CHANGELOG"
	echo "" >> "$COMBINED_CHANGELOG"
	
	# Find all changelog entries and sort by date
	parent_dir="$(dirname "$STACK_DIR")"
	for stack_dir in "$parent_dir"/*/docs/docs/changelog; do
	  if [ -d "$stack_dir" ]; then
	    stack_name="$(basename "$(dirname "$(dirname "$stack_dir")")")"
	    for entry in "$stack_dir"/*.md; do
	      if [ -f "$entry" ] && [ "$(basename "$entry")" != "index.md" ]; then
	        date=$(grep -m1 "^date:" "$entry" 2>/dev/null | sed 's/date: *//' || basename "$entry" .md)
	        title=$(grep -m1 "^title:" "$entry" 2>/dev/null | sed 's/title: *["]*//;s/["]*$//' || basename "$entry")
	        echo "- **$date** - [$title](../$stack_name/changelog/$(basename "$entry" .md)) ($stack_name)" >> "$COMBINED_CHANGELOG"
	      fi
	    done
	  fi
	done
	
	log_step "Combined changelog generated: $COMBINED_CHANGELOG"

# =============================================================================
# Listing Commands
# =============================================================================

docs-list:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	log_step "Listing documentation"
	
	echo ""
	echo "User Documentation:"
	find "$DOCS_CONTENT_DIR/user" -name "*.md" 2>/dev/null | sort | while read -r file; do
	  title=$(grep -m1 "^title:" "$file" 2>/dev/null | sed 's/title: *["]*//;s/["]*$//' || basename "$file")
	  printf "  - %s (%s)\n" "$title" "${file#$DOCS_CONTENT_DIR/}"
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
	
	echo ""
	echo "Taxonomy - ADRs:"
	find "$DOCS_CONTENT_DIR/taxonomy/adrs" -name "*.md" 2>/dev/null | sort | while read -r file; do
	  title=$(grep -m1 "^title:" "$file" 2>/dev/null | sed 's/title: *["]*//;s/["]*$//' || basename "$file")
	  status=$(grep -m1 "status:" "$file" 2>/dev/null | head -1 | sed 's/.*status: *//;s/ *$//' || echo "-")
	  printf "  - %s [%s] (%s)\n" "$title" "$status" "${file#$DOCS_CONTENT_DIR/}"
	done
	
	echo ""
	echo "Roadmap:"
	find "$DOCS_CONTENT_DIR/roadmap" -name "*.md" 2>/dev/null | sort | while read -r file; do
	  title=$(grep -m1 "^title:" "$file" 2>/dev/null | sed 's/title: *["]*//;s/["]*$//' || basename "$file")
	  status=$(grep -m1 "^status:" "$file" 2>/dev/null | sed 's/status: *//' || echo "-")
	  printf "  - %s [%s] (%s)\n" "$title" "$status" "${file#$DOCS_CONTENT_DIR/}"
	done
	
	echo ""
	echo "Changelog:"
	find "$DOCS_CONTENT_DIR/changelog" -name "*.md" 2>/dev/null | sort -r | head -10 | while read -r file; do
	  title=$(grep -m1 "^title:" "$file" 2>/dev/null | sed 's/title: *["]*//;s/["]*$//' || basename "$file")
	  printf "  - %s (%s)\n" "$title" "${file#$DOCS_CONTENT_DIR/}"
	done

docs-stats:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	log_step "Documentation statistics"
	
	echo ""
	printf "%-25s %s\n" "Category" "Count"
	printf "%-25s %s\n" "--------" "-----"
	
	user_count=$(find "$DOCS_CONTENT_DIR/user" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-25s %s\n" "User docs" "$user_count"
	
	cap_count=$(find "$DOCS_CONTENT_DIR/taxonomy/capabilities" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-25s %s\n" "Capabilities" "$cap_count"
	
	domain_count=$(find "$DOCS_CONTENT_DIR/taxonomy/domain" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-25s %s\n" "Domain docs" "$domain_count"
	
	events_count=$(find "$DOCS_CONTENT_DIR/taxonomy/events" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-25s %s\n" "Events" "$events_count"
	
	arch_count=$(find "$DOCS_CONTENT_DIR/taxonomy/architecture" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-25s %s\n" "Architecture" "$arch_count"
	
	integration_count=$(find "$DOCS_CONTENT_DIR/taxonomy/integration" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-25s %s\n" "Integration" "$integration_count"
	
	patterns_count=$(find "$DOCS_CONTENT_DIR/taxonomy/patterns" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-25s %s\n" "Patterns" "$patterns_count"
	
	adr_count=$(find "$DOCS_CONTENT_DIR/taxonomy/adrs" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-25s %s\n" "ADRs" "$adr_count"
	
	roadmap_count=$(find "$DOCS_CONTENT_DIR/roadmap" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-25s %s\n" "Roadmap items" "$roadmap_count"
	
	changelog_count=$(find "$DOCS_CONTENT_DIR/changelog" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
	printf "%-25s %s\n" "Changelog entries" "$changelog_count"
	
	total=$((user_count + cap_count + domain_count + events_count + arch_count + integration_count + patterns_count + adr_count + roadmap_count + changelog_count))
	printf "%-25s %s\n" "--------" "-----"
	printf "%-25s %s\n" "Total" "$total"

# =============================================================================
# CI/CD Commands
# =============================================================================

docs-ci:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_layer_context
	ensure_docusaurus
	log_step "Running docs CI pipeline"
	log_substep "Installing dependencies"
	just npm-install-ci
	log_substep "Validating structure"
	just docs-validate || true
	log_substep "Linting frontmatter"
	just docs-lint || true
	log_substep "Type checking"
	(cd "$LAYER_DIR" && npm run typecheck || true)
	log_substep "Building site"
	(cd "$LAYER_DIR" && npm run build)
	log_step "docs CI pipeline complete"

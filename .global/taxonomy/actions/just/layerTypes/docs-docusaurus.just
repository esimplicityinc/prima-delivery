import "../common.just"
import "../tools/npm.just"

# Docusaurus documentation layer recipes.
# Provides commands for developing, building, and serving Docusaurus documentation sites.

DOCS_DOCUSAURUS_LAYER_SETUP := '''
setup_docs_docusaurus_layer_context() {
  ENVIRONMENT="$(resolve_layer_env local)"
  # Prefer DOCS_LAYER_DIR over generic LAYER_DIR to avoid conflicts with other layer types
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
    printf '\033[1;31mError:\033[0m docs-docusaurus layer directory not found: %s\n' "$LAYER_DIR" >&2
    exit 1
  fi
  LAYER_DIR="$(cd "$LAYER_DIR" >/dev/null 2>&1 && pwd)"
  STACK_NAME="${STACK_NAME:-$(basename "$STACK_DIR")}"
  LAYER_NAME="${LAYER_NAME:-$(basename "$LAYER_DIR")}"

  if [ ! -f "$LAYER_DIR/package.json" ]; then
    printf '\033[1;31mError:\033[0m package.json not found in %s\n' "$LAYER_DIR" >&2
    exit 1
  fi

  export NPM_WORKDIR="$LAYER_DIR"
  export DOCS_WORKDIR="$LAYER_DIR"

  # Docusaurus configuration
  DOCS_PORT="${DOCS_PORT:-3000}"
  DOCS_HOST="${DOCS_HOST:-localhost}"

  log_substep "docs-docusaurus layer: $LAYER_DIR"
  log_substep "docs-docusaurus environment: $ENVIRONMENT"
}

ensure_docusaurus() {
  if [ ! -f "$LAYER_DIR/docusaurus.config.ts" ] && [ ! -f "$LAYER_DIR/docusaurus.config.js" ]; then
    printf '\033[1;31mError:\033[0m docusaurus.config.ts/js not found in %s\n' "$LAYER_DIR" >&2
    exit 1
  fi
}
'''

# Development commands
docs-docusaurus-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_DOCUSAURUS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_docusaurus_layer_context
	log_step "Installing Docusaurus dependencies"
	just npm-install

docs-docusaurus-install-ci:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_DOCUSAURUS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_docusaurus_layer_context
	log_step "Installing Docusaurus dependencies (CI mode)"
	just npm-install-ci

docs-docusaurus-dev:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_DOCUSAURUS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_docusaurus_layer_context
	ensure_docusaurus
	log_step "Starting Docusaurus development server"
	(cd "$LAYER_DIR" && npm start -- --host "$DOCS_HOST" --port "$DOCS_PORT")

docs-docusaurus-start:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_DOCUSAURUS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_docusaurus_layer_context
	ensure_docusaurus
	log_step "Starting Docusaurus development server"
	(cd "$LAYER_DIR" && npm start)

docs-docusaurus-build:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_DOCUSAURUS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_docusaurus_layer_context
	ensure_docusaurus
	log_step "Building Docusaurus site"
	(cd "$LAYER_DIR" && npm run build)

docs-docusaurus-serve:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_DOCUSAURUS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_docusaurus_layer_context
	ensure_docusaurus
	log_step "Serving Docusaurus production build"
	(cd "$LAYER_DIR" && npm run serve)

docs-docusaurus-clear:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_DOCUSAURUS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_docusaurus_layer_context
	ensure_docusaurus
	log_step "Clearing Docusaurus cache"
	(cd "$LAYER_DIR" && npm run clear)

docs-docusaurus-typecheck:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_DOCUSAURUS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_docusaurus_layer_context
	log_step "Running TypeScript type check"
	(cd "$LAYER_DIR" && npm run typecheck)

docs-docusaurus-clean:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_DOCUSAURUS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_docusaurus_layer_context
	log_step "Cleaning Docusaurus artifacts"
	(cd "$LAYER_DIR" && rm -rf build .docusaurus node_modules)

docs-docusaurus-deploy:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_DOCUSAURUS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_docusaurus_layer_context
	ensure_docusaurus
	log_step "Deploying Docusaurus site"
	(cd "$LAYER_DIR" && npm run deploy)

# CI/CD pipeline commands
docs-docusaurus-ci:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{DOCS_DOCUSAURUS_LAYER_SETUP}}
	set -euo pipefail
	setup_docs_docusaurus_layer_context
	ensure_docusaurus
	log_step "Running Docusaurus CI pipeline"
	log_substep "Installing dependencies"
	just npm-install-ci
	log_substep "Type checking"
	(cd "$LAYER_DIR" && npm run typecheck || true)
	log_substep "Building site"
	(cd "$LAYER_DIR" && npm run build)
	log_step "Docusaurus CI pipeline complete"

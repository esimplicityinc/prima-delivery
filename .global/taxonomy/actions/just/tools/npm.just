import "../common.just"

# Low-level npm/node utilities intended to be composed by higher-level recipes.

NPM_TOOL_HELPERS := '''
setup_npm_context() {
  NPM_DIR="${NPM_WORKDIR:-$(pwd)}"
  if [ ! -d "$NPM_DIR" ]; then
    log_error "npm project directory not found: $NPM_DIR"
    exit 1
  fi
  log_substep "npm working dir requested: $NPM_DIR"
  NPM_DIR="$(cd "$NPM_DIR" && pwd)"
  log_substep "npm working dir resolved: $NPM_DIR"
  export NPM_WORKDIR="$NPM_DIR"
}

ensure_npm() {
  NPM_BIN="${NPM_BIN:-npm}"
  if ! command -v "$NPM_BIN" >/dev/null 2>&1; then
    log_error "npm binary not found in PATH"
    exit 1
  fi
}

ensure_node() {
  NODE_BIN="${NODE_BIN:-node}"
  if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
    log_error "node binary not found in PATH"
    exit 1
  fi
}

check_npm_installed() {
  local npm_bin="${NPM_BIN:-npm}"
  command -v "$npm_bin" >/dev/null 2>&1
}

ensure_package_json() {
  if [ ! -f "$NPM_WORKDIR/package.json" ]; then
    log_error "package.json not found in $NPM_WORKDIR"
    exit 1
  fi
}
'''

npm-version:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{NPM_TOOL_HELPERS}}
	set -euo pipefail
	setup_npm_context
	ensure_npm
	ensure_node
	log_substep "npm: $(npm --version)"
	log_substep "node: $(node --version)"

npm-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{NPM_TOOL_HELPERS}}
	set -euo pipefail
	setup_npm_context
	ensure_npm
	ensure_package_json
	log_step "Installing npm dependencies"
	(cd "$NPM_WORKDIR" && npm install)

npm-install-ci:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{NPM_TOOL_HELPERS}}
	set -euo pipefail
	setup_npm_context
	ensure_npm
	ensure_package_json
	log_step "Installing npm dependencies (CI mode)"
	(cd "$NPM_WORKDIR" && npm ci)

npm-run script:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{NPM_TOOL_HELPERS}}
	set -euo pipefail
	setup_npm_context
	ensure_npm
	ensure_package_json
	log_step "Running npm script: {{script}}"
	(cd "$NPM_WORKDIR" && npm run {{script}})

npm-start:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{NPM_TOOL_HELPERS}}
	set -euo pipefail
	setup_npm_context
	ensure_npm
	ensure_package_json
	log_step "Starting npm project"
	(cd "$NPM_WORKDIR" && npm start)

npm-build:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{NPM_TOOL_HELPERS}}
	set -euo pipefail
	setup_npm_context
	ensure_npm
	ensure_package_json
	log_step "Building npm project"
	(cd "$NPM_WORKDIR" && npm run build)

npm-test:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{NPM_TOOL_HELPERS}}
	set -euo pipefail
	setup_npm_context
	ensure_npm
	ensure_package_json
	log_step "Running npm tests"
	(cd "$NPM_WORKDIR" && npm test)

npm-lint:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{NPM_TOOL_HELPERS}}
	set -euo pipefail
	setup_npm_context
	ensure_npm
	ensure_package_json
	log_step "Running npm lint"
	(cd "$NPM_WORKDIR" && npm run lint)

npm-typecheck:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{NPM_TOOL_HELPERS}}
	set -euo pipefail
	setup_npm_context
	ensure_npm
	ensure_package_json
	log_step "Running TypeScript type check"
	(cd "$NPM_WORKDIR" && npm run typecheck)

npm-clean:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{NPM_TOOL_HELPERS}}
	set -euo pipefail
	setup_npm_context
	log_step "Cleaning npm artifacts"
	(cd "$NPM_WORKDIR" && rm -rf node_modules dist build .cache)

npm-audit:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{NPM_TOOL_HELPERS}}
	set -euo pipefail
	setup_npm_context
	ensure_npm
	ensure_package_json
	log_step "Running npm security audit"
	(cd "$NPM_WORKDIR" && npm audit)

npm-outdated:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{NPM_TOOL_HELPERS}}
	set -euo pipefail
	setup_npm_context
	ensure_npm
	ensure_package_json
	log_step "Checking for outdated packages"
	(cd "$NPM_WORKDIR" && npm outdated || true)

import "../common.just"

# Low-level Bun runtime utilities intended to be composed by higher-level recipes.

BUN_TOOL_HELPERS := '''
setup_bun_context() {
  BUN_DIR="${BUN_WORKDIR:-$(pwd)}"
  if [ ! -d "$BUN_DIR" ]; then
    log_error "Bun project directory not found: $BUN_DIR"
    exit 1
  fi
  log_substep "bun working dir requested: $BUN_DIR"
  BUN_DIR="$(cd "$BUN_DIR" && pwd)"
  log_substep "bun working dir resolved: $BUN_DIR"
  export BUN_WORKDIR="$BUN_DIR"
}

ensure_bun() {
  BUN_BIN="${BUN_BIN:-bun}"
  if ! command -v "$BUN_BIN" >/dev/null 2>&1; then
    log_error "bun binary not found in PATH"
    exit 1
  fi
}

check_bun_installed() {
  local bun_bin="${BUN_BIN:-bun}"
  command -v "$bun_bin" >/dev/null 2>&1
}

require_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew (brew) must be installed to manage bun"
    exit 1
  fi
}

ensure_package_json() {
  if [ ! -f "$BUN_WORKDIR/package.json" ]; then
    log_error "package.json not found in $BUN_WORKDIR"
    exit 1
  fi
}
'''

bun-version:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	BUN_BIN="${BUN_BIN:-bun}"
	log_step "$BUN_BIN --version"
	"$BUN_BIN" --version

bun-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	ensure_package_json
	BUN_BIN="${BUN_BIN:-bun}"
	BUN_INSTALL_ARGS="${BUN_INSTALL_ARGS:-}"
	log_step "bun install $BUN_INSTALL_ARGS"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" install $BUN_INSTALL_ARGS)

bun-install-frozen:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	ensure_package_json
	BUN_BIN="${BUN_BIN:-bun}"
	log_step "bun install --frozen-lockfile"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" install --frozen-lockfile)

bun-install-production:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	ensure_package_json
	BUN_BIN="${BUN_BIN:-bun}"
	log_step "bun install --frozen-lockfile --production"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" install --frozen-lockfile --production)

bun-run:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	BUN_BIN="${BUN_BIN:-bun}"
	BUN_SCRIPT="${BUN_SCRIPT:-}"
	BUN_RUN_ARGS="${BUN_RUN_ARGS:-}"
	if [ -z "$BUN_SCRIPT" ]; then
		log_error "BUN_SCRIPT must be provided"
		exit 1
	fi
	log_step "bun run $BUN_SCRIPT $BUN_RUN_ARGS"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" run "$BUN_SCRIPT" $BUN_RUN_ARGS)

bun-dev:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	ensure_package_json
	BUN_BIN="${BUN_BIN:-bun}"
	BUN_DEV_ARGS="${BUN_DEV_ARGS:-}"
	log_step "bun run dev $BUN_DEV_ARGS"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" run dev $BUN_DEV_ARGS)

bun-start:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	ensure_package_json
	BUN_BIN="${BUN_BIN:-bun}"
	BUN_START_ARGS="${BUN_START_ARGS:-}"
	log_step "bun run start $BUN_START_ARGS"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" run start $BUN_START_ARGS)

bun-build:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	ensure_package_json
	BUN_BIN="${BUN_BIN:-bun}"
	BUN_BUILD_ARGS="${BUN_BUILD_ARGS:-}"
	log_step "bun run build $BUN_BUILD_ARGS"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" run build $BUN_BUILD_ARGS)

bun-test:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	BUN_BIN="${BUN_BIN:-bun}"
	BUN_TEST_ARGS="${BUN_TEST_ARGS:-}"
	log_step "bun test $BUN_TEST_ARGS"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" test $BUN_TEST_ARGS)

bun-test-coverage:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	BUN_BIN="${BUN_BIN:-bun}"
	BUN_TEST_ARGS="${BUN_TEST_ARGS:-}"
	log_step "bun test --coverage $BUN_TEST_ARGS"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" test --coverage $BUN_TEST_ARGS)

bun-typecheck:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	ensure_package_json
	BUN_BIN="${BUN_BIN:-bun}"
	log_step "bun run typecheck"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" run typecheck)

bun-lint:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	ensure_package_json
	BUN_BIN="${BUN_BIN:-bun}"
	BUN_LINT_ARGS="${BUN_LINT_ARGS:-}"
	log_step "bun run lint $BUN_LINT_ARGS"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" run lint $BUN_LINT_ARGS)

bun-lint-fix:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	ensure_package_json
	BUN_BIN="${BUN_BIN:-bun}"
	log_step "bun run lint:fix"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" run lint:fix)

bun-format:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	ensure_package_json
	BUN_BIN="${BUN_BIN:-bun}"
	log_step "bun run format"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" run format)

bun-check:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	ensure_bun
	ensure_package_json
	BUN_BIN="${BUN_BIN:-bun}"
	log_step "bun run check"
	(cd "$BUN_WORKDIR" && "$BUN_BIN" run check)

bun-clean:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	setup_bun_context
	log_step "Cleaning bun artifacts"
	log_substep "Removing node_modules"
	rm -rf "$BUN_WORKDIR/node_modules"
	log_substep "Removing dist"
	rm -rf "$BUN_WORKDIR/dist"
	log_substep "Removing bun.lock"
	rm -f "$BUN_WORKDIR/bun.lock"

bun-verify-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	if ! check_bun_installed; then
		log_error "bun not found in PATH"
		exit 1
	fi
	if ! version_out="$(${BUN_BIN:-bun} --version 2>/dev/null)"; then
		log_error "bun detected but failed to run '--version'"
		exit 1
	fi
	log_step "bun installation verified: ${version_out}"

bun-tool-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	if check_bun_installed; then
		log_step "bun already installed: $(${BUN_BIN:-bun} --version 2>/dev/null || echo 'version check unavailable')"
		exit 0
	fi
	require_homebrew
	log_step "Installing bun via Homebrew"
	brew install oven-sh/bun/bun

bun-upgrade:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{BUN_TOOL_HELPERS}}
	set -euo pipefail
	ensure_bun
	BUN_BIN="${BUN_BIN:-bun}"
	log_step "bun upgrade"
	"$BUN_BIN" upgrade

import "../common.just"

TERRAGRUNT_TOOL_HELPERS := '''
setup_terragrunt_context() {
  TG_DIR="${IAC_TERRAGRUNT_WORKDIR:-${TERRAGRUNT_DIR:-$(pwd)}}"
  if [ ! -d "$TG_DIR" ]; then
    log_error "Terragrunt directory not found: $TG_DIR"
    exit 1
  fi
  log_substep "terragrunt working dir requested: $TG_DIR"
  TG_DIR="$(cd "$TG_DIR" && pwd)"
  log_substep "terragrunt working dir resolved: $TG_DIR"
  export TERRAGRUNT_WORKDIR="$TG_DIR"
}

ensure_terragrunt() {
  TERRAGRUNT_BIN="${TERRAGRUNT_BIN:-terragrunt}"
  if ! command -v "$TERRAGRUNT_BIN" >/dev/null 2>&1; then
    log_error "terragrunt binary not found in PATH"
    exit 1
  fi
}

check_terragrunt_installed() {
  local terragrunt_bin="${TERRAGRUNT_BIN:-terragrunt}"
  command -v "$terragrunt_bin" >/dev/null 2>&1
}

require_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew (brew) must be installed to manage terragrunt"
    exit 1
  fi
}
'''

terragrunt-version:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAGRUNT_TOOL_HELPERS}}
	set -euo pipefail
	setup_terragrunt_context
	ensure_terragrunt
	TG_BIN="${TERRAGRUNT_BIN:-terragrunt}"
	log_step "$TG_BIN --version"
	(cd "$TERRAGRUNT_WORKDIR" && "$TG_BIN" --version)

terragrunt-plan:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAGRUNT_TOOL_HELPERS}}
	set -euo pipefail
	setup_terragrunt_context
	ensure_terragrunt
	TERRAGRUNT_PLAN_ARGS="${TERRAGRUNT_PLAN_ARGS:-}"
	log_step "terragrunt plan $TERRAGRUNT_PLAN_ARGS"
	TG_BIN="${TERRAGRUNT_BIN:-terragrunt}"
	(cd "$TERRAGRUNT_WORKDIR" && "$TG_BIN" --version >/dev/null && "$TG_BIN" plan $TERRAGRUNT_PLAN_ARGS)

terragrunt-apply:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAGRUNT_TOOL_HELPERS}}
	set -euo pipefail
	setup_terragrunt_context
	ensure_terragrunt
	TERRAGRUNT_APPLY_ARGS="${TERRAGRUNT_APPLY_ARGS:---non-interactive}"
	AUTO="${TERRAGRUNT_AUTO_APPROVE:-true}"
	if [ "$AUTO" = "true" ]; then AUTO_FLAG="-auto-approve"; else AUTO_FLAG=""; fi
	TG_BIN="${TERRAGRUNT_BIN:-terragrunt}"
	log_step "terragrunt apply $AUTO_FLAG $TERRAGRUNT_APPLY_ARGS"
	(cd "$TERRAGRUNT_WORKDIR" && "$TG_BIN" --version >/dev/null && "$TG_BIN" apply $AUTO_FLAG $TERRAGRUNT_APPLY_ARGS)

terragrunt-destroy:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAGRUNT_TOOL_HELPERS}}
	set -euo pipefail
	setup_terragrunt_context
	ensure_terragrunt
	TERRAGRUNT_DESTROY_ARGS="${TERRAGRUNT_DESTROY_ARGS:---non-interactive}"
	AUTO="${TERRAGRUNT_AUTO_APPROVE:-true}"
	if [ "$AUTO" = "true" ]; then AUTO_FLAG="-auto-approve"; else AUTO_FLAG=""; fi
	TG_BIN="${TERRAGRUNT_BIN:-terragrunt}"
	log_step "terragrunt destroy $AUTO_FLAG $TERRAGRUNT_DESTROY_ARGS"
	(cd "$TERRAGRUNT_WORKDIR" && "$TG_BIN" --version >/dev/null && "$TG_BIN" destroy $AUTO_FLAG $TERRAGRUNT_DESTROY_ARGS)

terragrunt-hclfmt:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAGRUNT_TOOL_HELPERS}}
	set -euo pipefail
	setup_terragrunt_context
	ensure_terragrunt
	TERRAGRUNT_HCLFMT_ARGS="${TERRAGRUNT_HCLFMT_ARGS:---check --diff}"
	TG_BIN="${TERRAGRUNT_BIN:-terragrunt}"
	log_step "terragrunt hcl format $TERRAGRUNT_HCLFMT_ARGS"
	(cd "$TERRAGRUNT_WORKDIR" && "$TG_BIN" --version >/dev/null && "$TG_BIN" hcl format $TERRAGRUNT_HCLFMT_ARGS)

terragrunt-fmt:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAGRUNT_TOOL_HELPERS}}
	set -euo pipefail
	setup_terragrunt_context
	ensure_terragrunt
	TERRAGRUNT_FMT_ARGS="${TERRAGRUNT_FMT_ARGS:-}"
	TG_BIN="${TERRAGRUNT_BIN:-terragrunt}"
	log_step "terragrunt fmt $TERRAGRUNT_FMT_ARGS"
	(cd "$TERRAGRUNT_WORKDIR" && "$TG_BIN" --version >/dev/null && "$TG_BIN" fmt $TERRAGRUNT_FMT_ARGS)

terragrunt-run-all-plan:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAGRUNT_TOOL_HELPERS}}
	set -euo pipefail
	setup_terragrunt_context
	ensure_terragrunt
	TERRAGRUNT_PLAN_ARGS="${TERRAGRUNT_PLAN_ARGS:-}"
	TG_BIN="${TERRAGRUNT_BIN:-terragrunt}"
	RUN_ALL_FLAGS="${TERRAGRUNT_RUN_ALL_FLAGS:-}"
	log_step "terragrunt run-all plan $RUN_ALL_FLAGS $TERRAGRUNT_PLAN_ARGS"
	(cd "$TERRAGRUNT_WORKDIR" && "$TG_BIN" run-all plan $RUN_ALL_FLAGS $TERRAGRUNT_PLAN_ARGS)

terragrunt-run-all-apply:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAGRUNT_TOOL_HELPERS}}
	set -euo pipefail
	setup_terragrunt_context
	ensure_terragrunt
	TERRAGRUNT_APPLY_ARGS="${TERRAGRUNT_APPLY_ARGS:---non-interactive}"
	TG_BIN="${TERRAGRUNT_BIN:-terragrunt}"
	NON_INTERACTIVE="${TERRAGRUNT_NON_INTERACTIVE:-true}"
	RUN_ALL_FLAGS="${TERRAGRUNT_RUN_ALL_FLAGS:-}"
	if [ "$NON_INTERACTIVE" = "true" ]; then
	  RUN_ALL_FLAGS="--terragrunt-non-interactive ${RUN_ALL_FLAGS}"
	fi
	log_step "terragrunt run-all apply $RUN_ALL_FLAGS $TERRAGRUNT_APPLY_ARGS"
	(cd "$TERRAGRUNT_WORKDIR" && "$TG_BIN" run-all apply $RUN_ALL_FLAGS $TERRAGRUNT_APPLY_ARGS)

terragrunt-clean:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAGRUNT_TOOL_HELPERS}}
	set -euo pipefail
	setup_terragrunt_context
	log_step "Removing .terragrunt-cache directories"
	find "$TERRAGRUNT_WORKDIR" -name '.terragrunt-cache' -prune -exec rm -rf {} +

terragrunt-verify-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAGRUNT_TOOL_HELPERS}}
	set -euo pipefail
	if ! check_terragrunt_installed; then
	  log_error "terragrunt not found in PATH"
	  exit 1
	fi
	if ! version_out="$(${TERRAGRUNT_BIN:-terragrunt} --version 2>/dev/null)"; then
		log_error "terragrunt detected but failed to run '--version'"
		exit 1
	fi
	log_step "terragrunt installation verified: ${version_out}"

terragrunt-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAGRUNT_TOOL_HELPERS}}
	set -euo pipefail
	if check_terragrunt_installed; then
	  log_step "terragrunt already installed: $(${TERRAGRUNT_BIN:-terragrunt} --version 2>/dev/null || echo 'version check unavailable')"
	  exit 0
	fi
	require_homebrew
	log_step "Installing terragrunt via Homebrew"
	brew install terragrunt

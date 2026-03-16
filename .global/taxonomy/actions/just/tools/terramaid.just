import "../common.just"

TERRAMAID_TOOL_HELPERS := '''
has_homebrew() {
  command -v brew >/dev/null 2>&1
}

terramaid_bin() {
  echo "${TERRAMAID_BIN:-terramaid}"
}

check_terramaid_installed() {
  command -v "$(terramaid_bin)" >/dev/null 2>&1
}

install_terramaid_with_brew() {
  if ! has_homebrew; then
    return 1
  fi
  local formula="${TERRAMAID_BREW_FORMULA:-terramaid}"
  if brew list "$formula" >/dev/null 2>&1; then
    log_substep "${formula} already installed via Homebrew"
    return 0
  fi
  log_substep "Installing ${formula} via Homebrew"
  if brew install "$formula"; then
    return 0
  fi
  return 1
}
'''

terramaid-verify-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAMAID_TOOL_HELPERS}}
	set -euo pipefail
	if ! check_terramaid_installed; then
	  log_error "terramaid binary not found in PATH"
	  exit 1
	fi
	bin="$(terramaid_bin)"
	if version_out="$("$bin" --version 2>/dev/null)"; then
	  log_step "terramaid installation verified: ${version_out}"
	else
	  log_step "terramaid binary detected at ${bin}"
	fi

terramaid-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAMAID_TOOL_HELPERS}}
	set -euo pipefail
	if check_terramaid_installed; then
	  bin="$(terramaid_bin)"
	  if version_out="$("$bin" --version 2>/dev/null)"; then
	    log_step "terramaid already installed: ${version_out}"
	  else
	    log_step "terramaid already installed (binary: ${bin})"
	  fi
	  exit 0
	fi
	log_step "Installing terramaid via Homebrew"
	if install_terramaid_with_brew; then
	  exit 0
	fi
	log_error "Failed to install terramaid via Homebrew"
	exit 1

terramaid-docs:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{TERRAMAID_TOOL_HELPERS}}
	set -euo pipefail
	if ! check_terramaid_installed; then
	  log_error "terramaid is required to render documentation; run 'just terramaid-install' first."
	  exit 1
	fi
	plan_file="${TERRAMAID_PLAN_FILE:-}"
	if [ -z "$plan_file" ]; then
	  log_error "TERRAMAID_PLAN_FILE must point to a Terraform plan produced by terragrunt/terraform."
	  exit 1
	fi
	if [ ! -f "$plan_file" ]; then
	  log_error "Terraform plan not found: $plan_file"
	  exit 1
	fi
	output="${TERRAMAID_DOC_OUTPUT:-}"
	if [ -z "$output" ]; then
	  output="$(pwd)/Terramaid.md"
	fi
	working_dir="${TERRAMAID_WORKING_DIR:-$PWD}"
	direction_args=()
	if [ -n "${TERRAMAID_DIRECTION:-}" ]; then
	  direction_args+=("--direction" "${TERRAMAID_DIRECTION}")
	fi
	if [ -n "${TERRAMAID_SUBGRAPH_NAME:-}" ]; then
	  direction_args+=("--subgraph-name" "${TERRAMAID_SUBGRAPH_NAME}")
	fi
	if [ -n "${TERRAMAID_CHART_TYPE:-}" ]; then
	  direction_args+=("--chart-type" "${TERRAMAID_CHART_TYPE}")
	fi
	mkdir -p "$(dirname "$output")"
	bin="$(terramaid_bin)"
	log_step "Rendering Terramaid documentation (plan=$(basename "$plan_file"))"
	cmd=("$bin" run "--tf-plan" "$plan_file" "--working-dir" "$working_dir" "--output" "$output")
	if [ ${#direction_args[@]} -gt 0 ]; then
	  cmd+=("${direction_args[@]}")
	fi
	"${cmd[@]}"
	log_substep "Terramaid output written to $output"

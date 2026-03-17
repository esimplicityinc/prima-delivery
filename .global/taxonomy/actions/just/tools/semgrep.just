import "../common.just"

# Semgrep static analysis tool for security and code quality scanning.

SEMGREP_TOOL_HELPERS := '''
setup_semgrep_context() {
  SEMGREP_DIR="${SEMGREP_WORKDIR:-$(pwd)}"
  if [ ! -d "$SEMGREP_DIR" ]; then
    log_error "Semgrep target directory not found: $SEMGREP_DIR"
    exit 1
  fi
  log_substep "semgrep working dir requested: $SEMGREP_DIR"
  SEMGREP_DIR="$(cd "$SEMGREP_DIR" && pwd)"
  log_substep "semgrep working dir resolved: $SEMGREP_DIR"
  export SEMGREP_WORKDIR="$SEMGREP_DIR"
}

ensure_semgrep() {
  SEMGREP_BIN="${SEMGREP_BIN:-semgrep}"
  if ! command -v "$SEMGREP_BIN" >/dev/null 2>&1; then
    log_error "semgrep binary not found in PATH"
    exit 1
  fi
}

check_semgrep_installed() {
  local semgrep_bin="${SEMGREP_BIN:-semgrep}"
  command -v "$semgrep_bin" >/dev/null 2>&1
}

require_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew (brew) must be installed to manage semgrep"
    exit 1
  fi
}
'''

semgrep-version:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{SEMGREP_TOOL_HELPERS}}
	set -euo pipefail
	ensure_semgrep
	SEMGREP_BIN="${SEMGREP_BIN:-semgrep}"
	log_step "$SEMGREP_BIN --version"
	"$SEMGREP_BIN" --version

semgrep-scan:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{SEMGREP_TOOL_HELPERS}}
	set -euo pipefail
	setup_semgrep_context
	ensure_semgrep
	SEMGREP_BIN="${SEMGREP_BIN:-semgrep}"
	config="${SEMGREP_CONFIG:-auto}"
	format="${SEMGREP_FORMAT:-text}"
	output="${SEMGREP_OUTPUT:-}"
	severity="${SEMGREP_SEVERITY:-}"
	exclude="${SEMGREP_EXCLUDE:-}"
	include="${SEMGREP_INCLUDE:-}"
	max_target_bytes="${SEMGREP_MAX_TARGET_BYTES:-}"
	timeout="${SEMGREP_TIMEOUT:-}"
	jobs="${SEMGREP_JOBS:-}"
	cmd=("$SEMGREP_BIN" scan)
	cmd+=(--config "$config")
	cmd+=(--"$format")
	if [ -n "$output" ]; then
		cmd+=(--output "$output")
		log_substep "Output file: $output"
	fi
	if [ -n "$severity" ]; then
		cmd+=(--severity "$severity")
	fi
	if [ -n "$exclude" ]; then
		for pattern in $exclude; do
			cmd+=(--exclude "$pattern")
		done
	fi
	if [ -n "$include" ]; then
		for pattern in $include; do
			cmd+=(--include "$pattern")
		done
	fi
	if [ -n "$max_target_bytes" ]; then
		cmd+=(--max-target-bytes "$max_target_bytes")
	fi
	if [ -n "$timeout" ]; then
		cmd+=(--timeout "$timeout")
	fi
	if [ -n "$jobs" ]; then
		cmd+=(--jobs "$jobs")
	fi
	if [ "${SEMGREP_VERBOSE:-}" = "true" ]; then
		cmd+=(--verbose)
	fi
	if [ "${SEMGREP_QUIET:-}" = "true" ]; then
		cmd+=(--quiet)
	fi
	if [ -n "${SEMGREP_EXTRA_ARGS:-}" ]; then
		# shellcheck disable=SC2086
		cmd+=($SEMGREP_EXTRA_ARGS)
	fi
	cmd+=("$SEMGREP_WORKDIR")
	log_step "Running Semgrep scan with config: $config"
	log_substep "${cmd[*]}"
	"${cmd[@]}"

semgrep-scan-security:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{SEMGREP_TOOL_HELPERS}}
	set -euo pipefail
	setup_semgrep_context
	ensure_semgrep
	SEMGREP_BIN="${SEMGREP_BIN:-semgrep}"
	format="${SEMGREP_FORMAT:-text}"
	output="${SEMGREP_OUTPUT:-}"
	cmd=("$SEMGREP_BIN" scan)
	cmd+=(--config "p/security-audit")
	cmd+=(--config "p/secrets")
	cmd+=(--"$format")
	if [ -n "$output" ]; then
		cmd+=(--output "$output")
		log_substep "Output file: $output"
	fi
	if [ -n "${SEMGREP_EXTRA_ARGS:-}" ]; then
		# shellcheck disable=SC2086
		cmd+=($SEMGREP_EXTRA_ARGS)
	fi
	cmd+=("$SEMGREP_WORKDIR")
	log_step "Running Semgrep security scan"
	log_substep "${cmd[*]}"
	"${cmd[@]}"

semgrep-scan-ci:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{SEMGREP_TOOL_HELPERS}}
	set -euo pipefail
	setup_semgrep_context
	ensure_semgrep
	SEMGREP_BIN="${SEMGREP_BIN:-semgrep}"
	config="${SEMGREP_CONFIG:-auto}"
	output="${SEMGREP_OUTPUT:-semgrep-results.json}"
	cmd=("$SEMGREP_BIN" ci)
	if [ -n "${SEMGREP_APP_TOKEN:-}" ]; then
		log_substep "Using Semgrep App token for CI"
	else
		cmd+=(--config "$config")
	fi
	cmd+=(--json --output "$output")
	if [ "${SEMGREP_SUPPRESS_ERRORS:-}" = "true" ]; then
		cmd+=(--suppress-errors)
	fi
	if [ -n "${SEMGREP_EXTRA_ARGS:-}" ]; then
		# shellcheck disable=SC2086
		cmd+=($SEMGREP_EXTRA_ARGS)
	fi
	log_step "Running Semgrep CI scan"
	log_substep "Output file: $output"
	log_substep "${cmd[*]}"
	set +e
	(cd "$SEMGREP_WORKDIR" && "${cmd[@]}")
	status=$?
	set -e
	if [ -n "${CI:-}" ] && [ -f "$output" ]; then
		log_substep "Emitting Semgrep results from $output"
		cat "$output" || true
	fi
	exit "$status"

semgrep-scan-json:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{SEMGREP_TOOL_HELPERS}}
	set -euo pipefail
	setup_semgrep_context
	ensure_semgrep
	SEMGREP_BIN="${SEMGREP_BIN:-semgrep}"
	config="${SEMGREP_CONFIG:-auto}"
	output="${SEMGREP_OUTPUT:-semgrep-results.json}"
	cmd=("$SEMGREP_BIN" scan)
	cmd+=(--config "$config")
	cmd+=(--json --output "$output")
	if [ -n "${SEMGREP_EXTRA_ARGS:-}" ]; then
		# shellcheck disable=SC2086
		cmd+=($SEMGREP_EXTRA_ARGS)
	fi
	cmd+=("$SEMGREP_WORKDIR")
	log_step "Running Semgrep scan (JSON output)"
	log_substep "Output file: $output"
	"${cmd[@]}"

semgrep-scan-sarif:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{SEMGREP_TOOL_HELPERS}}
	set -euo pipefail
	setup_semgrep_context
	ensure_semgrep
	SEMGREP_BIN="${SEMGREP_BIN:-semgrep}"
	config="${SEMGREP_CONFIG:-auto}"
	output="${SEMGREP_OUTPUT:-semgrep-results.sarif}"
	cmd=("$SEMGREP_BIN" scan)
	cmd+=(--config "$config")
	cmd+=(--sarif --output "$output")
	if [ -n "${SEMGREP_EXTRA_ARGS:-}" ]; then
		# shellcheck disable=SC2086
		cmd+=($SEMGREP_EXTRA_ARGS)
	fi
	cmd+=("$SEMGREP_WORKDIR")
	log_step "Running Semgrep scan (SARIF output)"
	log_substep "Output file: $output"
	"${cmd[@]}"

semgrep-list-rules:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{SEMGREP_TOOL_HELPERS}}
	set -euo pipefail
	ensure_semgrep
	SEMGREP_BIN="${SEMGREP_BIN:-semgrep}"
	config="${SEMGREP_CONFIG:-auto}"
	log_step "Listing rules for config: $config"
	"$SEMGREP_BIN" scan --config "$config" --dump-config | head -100

semgrep-verify-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{SEMGREP_TOOL_HELPERS}}
	set -euo pipefail
	if ! check_semgrep_installed; then
		log_error "semgrep not found in PATH"
		exit 1
	fi
	if ! version_out="$(${SEMGREP_BIN:-semgrep} --version 2>/dev/null)"; then
		log_error "semgrep detected but failed to run '--version'"
		exit 1
	fi
	log_step "semgrep installation verified: ${version_out}"

semgrep-tool-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{SEMGREP_TOOL_HELPERS}}
	set -euo pipefail
	if check_semgrep_installed; then
		log_step "semgrep already installed: $(${SEMGREP_BIN:-semgrep} --version 2>/dev/null || echo 'version check unavailable')"
		exit 0
	fi
	require_homebrew
	log_step "Installing semgrep via Homebrew"
	brew install semgrep

semgrep-tool-install-pip:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{SEMGREP_TOOL_HELPERS}}
	set -euo pipefail
	if check_semgrep_installed; then
		log_step "semgrep already installed: $(${SEMGREP_BIN:-semgrep} --version 2>/dev/null || echo 'version check unavailable')"
		exit 0
	fi
	if ! command -v pip3 >/dev/null 2>&1 && ! command -v pip >/dev/null 2>&1; then
		log_error "pip not found in PATH"
		exit 1
	fi
	log_step "Installing semgrep via pip"
	pip3 install semgrep || pip install semgrep

semgrep-login:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{SEMGREP_TOOL_HELPERS}}
	set -euo pipefail
	ensure_semgrep
	SEMGREP_BIN="${SEMGREP_BIN:-semgrep}"
	log_step "Logging into Semgrep App"
	"$SEMGREP_BIN" login

semgrep-logout:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{SEMGREP_TOOL_HELPERS}}
	set -euo pipefail
	ensure_semgrep
	SEMGREP_BIN="${SEMGREP_BIN:-semgrep}"
	log_step "Logging out of Semgrep App"
	"$SEMGREP_BIN" logout

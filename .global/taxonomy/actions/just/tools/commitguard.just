import "../common.just"

# ---------------------------------------------------------------------------
# CommitGuard — Git hook management via Katalyst taxonomy
# ---------------------------------------------------------------------------
# These recipes are the entry points referenced by the bundled commitguard
# Action definitions (hooks-install, hooks-generate, hooks-run-all,
# hooks-update).  They delegate to `kata tax hooks` CLI commands.
# ---------------------------------------------------------------------------

hooks-install:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	log_step "Installing git hooks"

	# Detect active tool from .katalyst-hooks.yaml
	tool=$(kata tax hooks detect-tool 2>/dev/null || true)
	if [ -z "$tool" ]; then
		log_warn "No hook tool configured in .katalyst-hooks.yaml"
		log_substep "Run 'kata tax hooks generate' first to create a config"
		exit 0
	fi

	log_substep "Detected hook tool: $tool"

	case "$tool" in
		pre-commit)
			if command -v pre-commit >/dev/null 2>&1; then
				pre-commit install
				log_substep "pre-commit hooks installed"
			else
				log_error "pre-commit not found — install with: pip install pre-commit"
				exit 1
			fi
			;;
		husky)
			if command -v npx >/dev/null 2>&1; then
				npx husky install
				log_substep "Husky hooks installed"
			else
				log_error "npx not found — install Node.js first"
				exit 1
			fi
			;;
		lefthook)
			if command -v lefthook >/dev/null 2>&1; then
				lefthook install
				log_substep "Lefthook hooks installed"
			else
				log_error "lefthook not found — install with: go install github.com/evilmartians/lefthook@latest"
				exit 1
			fi
			;;
		*)
			log_error "Unknown hook tool: $tool"
			exit 1
			;;
	esac

hooks-generate:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	log_step "Generating hook configuration"

	tool="${COMMITGUARD_TOOL:-}"
	if [ -z "$tool" ]; then
		tool=$(kata tax hooks detect-tool 2>/dev/null || true)
	fi
	if [ -z "$tool" ]; then
		log_error "No hook tool configured — set COMMITGUARD_TOOL or add tool to .katalyst-hooks.yaml"
		exit 1
	fi

	log_substep "Generating config for: $tool"
	kata tax hooks generate --tool "$tool" --path "${REPO_ROOT:-.}"

hooks-run-all:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	log_step "Running hook actions on staged files"

	tool="${COMMITGUARD_TOOL:-}"
	if [ -z "$tool" ]; then
		tool=$(kata tax hooks detect-tool 2>/dev/null || true)
	fi

	extra_args=""
	if [ -n "$tool" ]; then
		extra_args="--tool $tool"
	fi

	# Resolve staged files and run matching layer actions
	# shellcheck disable=SC2086
	kata tax hooks run --path "${REPO_ROOT:-.}" $extra_args

hooks-update:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	log_step "Updating hook configuration"

	log_substep "Regenerating hook configs"
	just hooks-generate

	log_substep "Reinstalling hooks"
	just hooks-install

	log_step "Hook configuration updated"

hooks-validate:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	log_step "Validating hook configuration"
	kata tax hooks validate --path "${REPO_ROOT:-.}"

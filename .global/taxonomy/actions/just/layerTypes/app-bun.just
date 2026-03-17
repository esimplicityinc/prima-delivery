import "../common.just"
import "../tools/bun.just"
import "../tools/docker.just"
import "../tools/semgrep.just"
import "../tools/trivy.just"

APP_BUN_LAYER_SETUP := '''
setup_app_bun_layer_context() {
  ENVIRONMENT="$(resolve_layer_env local)"
  local requested_layer="${LAYER_DIR:-${APP_LAYER_DIR:-}}"
  local stack_dir="${STACK_DIR:-}"
  if [ -z "$stack_dir" ] && [ -n "$requested_layer" ]; then
    stack_dir="$(cd "$(dirname "$requested_layer")" >/dev/null 2>&1 && pwd)"
  fi
  stack_dir="${stack_dir:-$PWD}"
  STACK_DIR="$stack_dir"
  local default_layer_dir="$STACK_DIR/app"
  LAYER_DIR="${requested_layer:-$default_layer_dir}"
  if [ ! -d "$LAYER_DIR" ]; then
    printf '\033[1;31mError:\033[0m app-bun layer directory not found: %s\n' "$LAYER_DIR" >&2
    exit 1
  fi
  LAYER_DIR="$(cd "$LAYER_DIR" >/dev/null 2>&1 && pwd)"
  STACK_NAME="${STACK_NAME:-$(basename "$STACK_DIR")}"
  LAYER_NAME="${LAYER_NAME:-$(basename "$LAYER_DIR")}"

  if [ ! -f "$LAYER_DIR/package.json" ]; then
    printf '\033[1;31mError:\033[0m package.json not found in %s\n' "$LAYER_DIR" >&2
    exit 1
  fi

  export BUN_WORKDIR="$LAYER_DIR"
  export APP_BUN_WORKDIR="$LAYER_DIR"

  # Docker image configuration
  env_registry="$(read_environment_value "spec.layerTemplates.app-bun.imageRegistry" "$ENVIRONMENT" 2>/dev/null || printf '')"
  env_prefix="$(read_environment_value "spec.layerTemplates.app-bun.repositoryPrefix" "$ENVIRONMENT" 2>/dev/null || printf '')"
  env_repository="$(read_environment_value "spec.layerTemplates.app-bun.repository" "$ENVIRONMENT" 2>/dev/null || printf '')"
  env_tag="$(read_environment_value "spec.layerTemplates.app-bun.imageTag" "$ENVIRONMENT" 2>/dev/null || printf '')"

  IMAGE_REGISTRY="${IMAGE_REGISTRY:-$env_registry}"
  IMAGE_REGISTRY="${IMAGE_REGISTRY%/}"
  IMAGE_TAG="${IMAGE_TAG:-${env_tag:-$ENVIRONMENT}}"

  repository="$env_repository"
  if [ -z "$repository" ]; then
    default_repo="$STACK_NAME-$LAYER_NAME"
    trimmed_prefix="${env_prefix%/}"
    if [ -n "$trimmed_prefix" ]; then
      default_repo="$trimmed_prefix/$default_repo"
    fi
    repository="$default_repo"
  fi
  repository="${repository#/}"
  repository="${repository%/}"
  IMAGE_REPOSITORY="${repository:-$STACK_NAME-$LAYER_NAME}"

  if [ -n "$IMAGE_REGISTRY" ]; then
    IMAGE_REF="${IMAGE_REGISTRY}/${IMAGE_REPOSITORY}:${IMAGE_TAG}"
  else
    IMAGE_REF="${IMAGE_REPOSITORY}:${IMAGE_TAG}"
  fi

  # Port configuration
  APP_PORT="${APP_PORT:-${PORT:-3000}}"

  log_substep "app-bun layer: $LAYER_DIR"
  log_substep "app-bun environment: $ENVIRONMENT"
  log_substep "app-bun image: $IMAGE_REF"
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    printf '\033[1;31mError:\033[0m docker CLI not found in PATH.\n' >&2
    exit 1
  fi
}

ensure_image() {
  local ref="$1"
  if ! docker image inspect "$ref" >/dev/null 2>&1; then
    printf '\033[1;31mError:\033[0m image %s not found locally. Run `just app-bun-build-image` first.\n' "$ref" >&2
    exit 1
  fi
}
'''

# Development commands
app-bun-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Installing dependencies"
	just bun-install

app-bun-install-frozen:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Installing dependencies (frozen lockfile)"
	just bun-install-frozen

app-bun-dev:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Starting development server"
	just bun-dev

app-bun-start:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Starting production server"
	just bun-start

app-bun-build:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Building application"
	just bun-build

# Testing commands
app-bun-test:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Running tests"
	just bun-test

app-bun-test-coverage:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Running tests with coverage"
	just bun-test-coverage

# Code quality commands
app-bun-typecheck:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Running type check"
	just bun-typecheck

app-bun-lint:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Running linter"
	just bun-lint

app-bun-lint-fix:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Running linter with auto-fix"
	just bun-lint-fix

app-bun-format:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Formatting code"
	just bun-format

app-bun-fmt:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Running format and type checks"
	just bun-format
	just bun-typecheck

app-bun-check:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Running all checks (lint, format, typecheck)"
	just bun-check

# Security scanning
app-bun-security:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Running security scan with Semgrep"
	SEMGREP_WORKDIR="$LAYER_DIR/src" SEMGREP_CONFIG="${SEMGREP_CONFIG:-p/typescript}" just semgrep-scan

app-bun-security-full:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Running full security scan"
	log_substep "Semgrep security audit"
	SEMGREP_WORKDIR="$LAYER_DIR/src" just semgrep-scan-security
	log_substep "Semgrep TypeScript rules"
	SEMGREP_WORKDIR="$LAYER_DIR/src" SEMGREP_CONFIG="p/typescript" just semgrep-scan

# Docker commands
app-bun-build-image:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	require_docker
	if [ ! -f "$LAYER_DIR/Dockerfile" ]; then
	  printf '\033[1;31mError:\033[0m Dockerfile not found in %s\n' "$LAYER_DIR" >&2
	  exit 1
	fi
	log_step "Building Docker image $IMAGE_REF"
	IMAGE_REF="$IMAGE_REF" DOCKERFILE="$LAYER_DIR/Dockerfile" DOCKER_BUILD_CONTEXT="$LAYER_DIR" just docker-build-image

app-bun-push-image:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	require_docker
	if [ -z "$IMAGE_REGISTRY" ]; then
	  log_warn "No image registry configured for environment $ENVIRONMENT; skipping push."
	  exit 0
	fi
	ensure_image "$IMAGE_REF"
	log_step "Pushing Docker image $IMAGE_REF"
	IMAGE_REF="$IMAGE_REF" just docker-push-image

app-bun-scan-image:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	require_docker
	if ! docker image inspect "$IMAGE_REF" >/dev/null 2>&1; then
	  log_step "Image $IMAGE_REF not found locally; building first"
	  just app-bun-build-image
	fi
	log_step "Scanning Docker image $IMAGE_REF with Trivy"
	tmp_tar="$(mktemp "trivy-image-XXXXXX.tar")"
	trap 'rm -f "$tmp_tar"' EXIT
	log_substep "Saving $IMAGE_REF to $tmp_tar"
	docker save "$IMAGE_REF" -o "$tmp_tar"
	TRIVY_IMAGE_REF="$IMAGE_REF" TRIVY_IMAGE_INPUT="$tmp_tar" just trivy-scan-image

# Docker Compose commands
app-bun-compose-up:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	require_docker
	if [ ! -f "$LAYER_DIR/docker-compose.yml" ] && [ ! -f "$LAYER_DIR/docker-compose.yaml" ]; then
	  printf '\033[1;31mError:\033[0m docker-compose.yml not found in %s\n' "$LAYER_DIR" >&2
	  exit 1
	fi
	log_step "Starting Docker Compose services"
	(cd "$LAYER_DIR" && docker compose up -d)

app-bun-compose-down:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	require_docker
	log_step "Stopping Docker Compose services"
	(cd "$LAYER_DIR" && docker compose down)

app-bun-compose-logs:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	require_docker
	log_step "Showing Docker Compose logs"
	(cd "$LAYER_DIR" && docker compose logs -f)

app-bun-compose-ps:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	require_docker
	(cd "$LAYER_DIR" && docker compose ps)

# Utility commands
app-bun-clean:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Cleaning build artifacts"
	just bun-clean

app-bun-version:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	just bun-version

# CI/CD pipeline commands
app-bun-ci:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Running CI pipeline"
	log_substep "Installing dependencies"
	just bun-install-frozen
	log_substep "Type checking"
	just bun-typecheck
	log_substep "Linting"
	just bun-lint
	log_substep "Running tests"
	just bun-test
	log_substep "Building"
	just bun-build
	log_step "CI pipeline complete"

app-bun-ci-security:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_BUN_LAYER_SETUP}}
	set -euo pipefail
	setup_app_bun_layer_context
	log_step "Running CI security pipeline"
	log_substep "Semgrep scan"
	SEMGREP_WORKDIR="$LAYER_DIR/src" just semgrep-scan-ci
	log_step "CI security pipeline complete"

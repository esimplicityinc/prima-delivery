import "../common.just"
import "../tools/docker.just"
import "../tools/ghcr.just"
import "../tools/ecr.just"
import "../tools/trivy.just"

APP_DOCKER_LAYER_SETUP := '''
	setup_app_docker_layer_context() {
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
	    printf '\033[1;31mError:\033[0m app-docker layer directory not found: %s\n' "$LAYER_DIR" >&2
	    exit 1
	  fi
	  LAYER_DIR="$(cd "$LAYER_DIR" >/dev/null 2>&1 && pwd)"
	  STACK_NAME="${STACK_NAME:-$(basename "$STACK_DIR")}" 
	  LAYER_NAME="${LAYER_NAME:-$(basename "$LAYER_DIR")}" 

	  BASE_CONTEXT="$LAYER_DIR/base"
	  BASE_DOCKERFILE_PATH="$BASE_CONTEXT/Dockerfile"
	  if [ ! -f "$BASE_DOCKERFILE_PATH" ]; then
	    printf '\033[1;31mError:\033[0m base Dockerfile missing: %s\n' "$BASE_DOCKERFILE_PATH" >&2
	    exit 1
	  fi

	  RUNTIME_CONTEXT="$LAYER_DIR/$ENVIRONMENT"
	  RUNTIME_DOCKERFILE_PATH="$RUNTIME_CONTEXT/Dockerfile"
	  if [ ! -f "$RUNTIME_DOCKERFILE_PATH" ]; then
	    printf '\033[1;31mError:\033[0m environment overlay missing: %s\n' "$RUNTIME_DOCKERFILE_PATH" >&2
	    exit 1
	  fi

	  USER_STACK_IMAGE="${STACK_IMAGE:-}"
	  env_registry="$(read_environment_value "spec.layerTemplates.app-docker.imageRegistry" "$ENVIRONMENT" || printf '')"
	  env_prefix="$(read_environment_value "spec.layerTemplates.app-docker.repositoryPrefix" "$ENVIRONMENT" || printf '')"
	  env_runtime="$(read_environment_value "spec.layerTemplates.app-docker.runtimeRepository" "$ENVIRONMENT" || printf '')"
	  env_tag_setting="$(read_environment_value "spec.layerTemplates.app-docker.imageTag" "$ENVIRONMENT" || printf '')"

  IMAGE_REGISTRY="${IMAGE_REGISTRY:-$env_registry}"
  IMAGE_REGISTRY="${IMAGE_REGISTRY%/}"
  if [ -z "$IMAGE_REGISTRY" ]; then
    printf '\033[1;31mError:\033[0m spec.layerTemplates.app-docker.imageRegistry not configured for environment %s (layer %s)\n' "$ENVIRONMENT" "$LAYER_NAME" >&2
    exit 1
  fi
	  IMAGE_TAG="${IMAGE_TAG:-${env_tag_setting:-$ENVIRONMENT}}"

	  runtime_repo="$env_runtime"
	  if [ -n "$USER_STACK_IMAGE" ]; then
	    runtime_repo="$USER_STACK_IMAGE"
	  elif [ -z "$runtime_repo" ]; then
	    default_repo="$STACK_NAME-$LAYER_NAME"
	    trimmed_prefix="${env_prefix%/}"
	    if [ -n "$trimmed_prefix" ]; then
	      default_repo="$trimmed_prefix/$default_repo"
	    fi
	    runtime_repo="$default_repo"
	  fi

	  runtime_repo="${runtime_repo#/}"
	  runtime_repo="${runtime_repo%/}"
	  if [ -z "$runtime_repo" ]; then
	    runtime_repo="$STACK_NAME-$LAYER_NAME"
	  fi
	  RUNTIME_REPOSITORY="$runtime_repo"

	  if [[ "$runtime_repo" == */* ]]; then
	    base_repo_prefix="${runtime_repo%/*}"
	    base_repo_name="${runtime_repo##*/}"
	    BASE_REPOSITORY="$base_repo_prefix/${base_repo_name}-base"
	  else
	    BASE_REPOSITORY="${runtime_repo}-base"
	  fi

	  REGISTRY_ACCOUNT=""
	  REGISTRY_REGION="${AWS_REGION:-}"
	  REGISTRY_URI="$IMAGE_REGISTRY"
	  if [[ "$IMAGE_REGISTRY" =~ ^([0-9]+)\.dkr\.ecr\.([^.]+)\.amazonaws\.com$ ]]; then
	    REGISTRY_ACCOUNT="${BASH_REMATCH[1]}"
	    REGISTRY_REGION="${BASH_REMATCH[2]}"
	  fi

	  if [ -n "$IMAGE_REGISTRY" ]; then
	    BASE_IMAGE_REF="${IMAGE_REGISTRY}/${BASE_REPOSITORY}:${IMAGE_TAG}"
	    RUNTIME_IMAGE_REF="${IMAGE_REGISTRY}/${RUNTIME_REPOSITORY}:${IMAGE_TAG}"
	  else
	    BASE_IMAGE_REF="${BASE_REPOSITORY}:${IMAGE_TAG}"
	    RUNTIME_IMAGE_REF="${RUNTIME_REPOSITORY}:${IMAGE_TAG}"
	  fi

	  IMAGE_PLATFORM="${IMAGE_PLATFORM:-linux/amd64}"
	  BASE_LOCAL_REF="${BASE_REPOSITORY}:${IMAGE_TAG}"

	  APP_DOCKER_ADDITIONAL_REGISTRIES=""
	  additional_registries_raw="$(read_environment_value "spec.layerTemplates.app-docker.additionalRegistries" "$ENVIRONMENT" || printf '[]')"
	  if [ -n "$additional_registries_raw" ] && [ "$additional_registries_raw" != "[]" ]; then
	    APP_DOCKER_ADDITIONAL_REGISTRIES="$(APP_DOCKER_REGISTRIES_JSON="$additional_registries_raw" python3 <<'PY'
import json
import os
import sys

raw = os.environ.get("APP_DOCKER_REGISTRIES_JSON", "[]")
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)

if not isinstance(data, list):
    sys.exit(0)

def norm(value):
    if value in (None, "", "null"):
        return ""
    return str(value)

for entry in data:
    if not isinstance(entry, dict):
        continue
    registry = entry.get("registry")
    if not registry:
        continue
    fields = [
        norm(registry),
        norm(entry.get("type")),
        norm(entry.get("usernameEnv")),
        norm(entry.get("passwordEnv")),
        norm(entry.get("awsProfileEnv")),
    ]
    print("|".join(fields))
PY
)"
	  fi
	}

	ensure_ecr_repository() {
	  local repository="$1"
	  if [ -z "$repository" ]; then
	    return 0
	  fi
	  if [ -z "$IMAGE_REGISTRY" ]; then
	    return 0
	  fi
	  if [ -z "$REGISTRY_REGION" ] || [ -z "$REGISTRY_ACCOUNT" ]; then
	    log_substep "Registry $IMAGE_REGISTRY is not ECR; skipping $repository."
	    return 0
	  fi
	  if ! command -v aws >/dev/null 2>&1; then
	    log_warn "AWS CLI not found; skipping ensure for $repository."
	    return 0
	  fi
	  if aws ecr describe-repositories --repository-names "$repository" --region "$REGISTRY_REGION" >/dev/null 2>&1; then
	    log_substep "ECR repository $repository already exists in $REGISTRY_REGION."
	    return 0
	  fi
	  log_substep "Creating ECR repository $repository in $REGISTRY_REGION."
	  printf '   => aws ecr create-repository --repository-name %s --region %s\n' "$repository" "$REGISTRY_REGION"
	  aws ecr create-repository --repository-name "$repository" --region "$REGISTRY_REGION" >/dev/null
	}

	app_docker_seen_registries_reset() {
	  APP_DOCKER_SEEN_REGISTRIES=""
	}

	app_docker_registry_seen() {
	  local registry="$1"
	  for entry in $APP_DOCKER_SEEN_REGISTRIES; do
	    if [ "$entry" = "$registry" ]; then
	      return 0
	    fi
	  done
	  return 1
	}

	app_docker_registry_mark_seen() {
	  local registry="$1"
	  if ! app_docker_registry_seen "$registry"; then
	    APP_DOCKER_SEEN_REGISTRIES="$APP_DOCKER_SEEN_REGISTRIES $registry"
	  fi
	}

	app_docker_login_additional_registries() {
	  local login_disabled="${1:-0}"
	  if [ -z "${APP_DOCKER_ADDITIONAL_REGISTRIES:-}" ]; then
	    return 0
	  fi
	  while IFS= read -r registry_entry; do
	    [ -z "$registry_entry" ] && continue
	    IFS='|' read -r registry reg_type user_env pass_env aws_profile_env <<< "$registry_entry"
	    if [ -z "$registry" ]; then
	      continue
	    fi
	    app_docker_attempt_login "$registry" "$login_disabled" "$user_env" "$pass_env" "$reg_type" "$aws_profile_env"
	  done <<< "$APP_DOCKER_ADDITIONAL_REGISTRIES"
	}

	app_docker_attempt_login() {
	  local registry="$1"
	  local login_disabled="${2:-0}"
	  local user_env="${3:-}"
	  local pass_env="${4:-}"
	  local registry_type_raw="${5:-}"
	  local aws_profile_env="${6:-}"
	  local registry_type=""
	  if [ -n "$registry_type_raw" ]; then
	    registry_type="$(printf '%s' "$registry_type_raw" | tr '[:upper:]' '[:lower:]')"
	  fi
	  local aws_profile_override=""
	  if [ -n "$aws_profile_env" ]; then
	    aws_profile_override="${!aws_profile_env:-}"
	  fi

	  if [ "$login_disabled" -eq 1 ]; then
	    return 0
	  fi

	  registry="${registry%/}"
	  if [ -z "$registry" ]; then
	    return 0
	  fi
	  if [[ "$registry" =~ ^(localhost|127\.0\.0\.1)(:[0-9]+)?$ ]]; then
	    return 0
	  fi

	  local registry_host="$registry"
	  if [[ "$registry_host" == */* ]]; then
	    registry_host="${registry_host%%/*}"
	  fi

	  if app_docker_registry_seen "$registry_host"; then
	    return 0
	  fi

	  if [ "$registry_host" = "ghcr.io" ] || [ "$registry_type" = "ghcr" ]; then
	    app_docker_registry_mark_seen "$registry_host"
	    local ghcr_env=("GHCR_REGISTRY_HOST=$registry_host")
	    if [ -n "$user_env" ] && [ -n "${!user_env:-}" ]; then
	      ghcr_env+=("GHCR_USERNAME=${!user_env}")
	    fi
	    if [ -n "$pass_env" ] && [ -n "${!pass_env:-}" ]; then
	      ghcr_env+=("GHCR_TOKEN=${!pass_env}")
	    fi
	    if ! env "${ghcr_env[@]}" just ghcr-login-check >/dev/null 2>&1; then
	      log_step "Authenticating with registry $registry_host"
	      if ! env "${ghcr_env[@]}" just ghcr-login; then
	        log_warn "Docker login to $registry_host failed; continuing without registry auth."
	      fi
	    else
	      log_substep "Already authenticated with $registry_host"
	    fi
	    return 0
	  fi

	  if [[ "$registry_host" =~ ^([0-9]+)\.dkr\.ecr\.([^.]+)\.amazonaws\.com$ ]] || [ "$registry_type" = "ecr" ]; then
	    app_docker_registry_mark_seen "$registry_host"
	    local ecr_env=("ECR_REGISTRY=$registry_host")
	    local profile_to_use=""
	    if [ -n "$aws_profile_override" ]; then
	      profile_to_use="$aws_profile_override"
	    elif [ -n "${DOCKER_AWS_PROFILE:-}" ]; then
	      profile_to_use="${DOCKER_AWS_PROFILE}"
	    fi
	    if [ -n "$profile_to_use" ]; then
	      ecr_env+=("ECR_AWS_PROFILE=$profile_to_use")
	    fi
	    if ! env "${ecr_env[@]}" just ecr-login-check >/dev/null 2>&1; then
	      log_step "Authenticating with registry $registry_host"
	      if ! env "${ecr_env[@]}" just ecr-login; then
	        log_warn "Docker login to $registry_host failed; continuing without registry auth."
	      fi
	    else
	      log_substep "Already authenticated with $registry_host"
	    fi
	    return 0
	  fi

	  app_docker_registry_mark_seen "$registry_host"

	  local env_args=("DOCKER_REGISTRY=$registry_host")
	  if [ -n "$user_env" ]; then
	    if [ -n "${!user_env:-}" ]; then
	      env_args+=("DOCKER_USERNAME=${!user_env}")
	    else
	      log_warn "Environment variable $user_env is unset; attempting anonymous login to $registry_host."
	    fi
	  fi
	  if [ -n "$pass_env" ]; then
	    if [ -n "${!pass_env:-}" ]; then
	      env_args+=("DOCKER_PASSWORD=${!pass_env}")
	    else
	      log_warn "Environment variable $pass_env is unset; attempting anonymous login to $registry_host."
	    fi
	  fi

	  log_step "Authenticating with registry $registry_host"
	  if ! env "${env_args[@]}" just docker-login; then
	    log_warn "Docker login to $registry_host failed; continuing without registry auth."
	  fi
	}
'''

app-docker-build:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_DOCKER_LAYER_SETUP}}
	require_docker() {
	  if ! command -v docker >/dev/null 2>&1; then
	    printf '\033[1;31mError:\033[0m docker CLI not found in PATH.\n' >&2
	    exit 1
	  fi
	}
	set -euo pipefail
	require_docker
	setup_app_docker_layer_context
	login_disabled=0
	if [ "${APP_DOCKER_DISABLE_LOGIN:-0}" = "1" ] || [ "${SKIP_DOCKER_LOGIN:-0}" = "1" ]; then
	  login_disabled=1
	fi

	app_docker_seen_registries_reset
	app_docker_attempt_login "$IMAGE_REGISTRY" "$login_disabled"
	app_docker_login_additional_registries "$login_disabled"

	log_step "Building base image $BASE_IMAGE_REF"
	IMAGE_REF="$BASE_IMAGE_REF" DOCKERFILE="$BASE_DOCKERFILE_PATH" DOCKER_BUILD_CONTEXT="$BASE_CONTEXT" DOCKER_PLATFORM="$IMAGE_PLATFORM" just docker-build-image
	docker tag "$BASE_IMAGE_REF" "$BASE_LOCAL_REF"
	log_step "Building runtime image $RUNTIME_IMAGE_REF"
	IMAGE_REF="$RUNTIME_IMAGE_REF" DOCKERFILE="$RUNTIME_DOCKERFILE_PATH" DOCKER_BUILD_CONTEXT="$RUNTIME_CONTEXT" DOCKER_PLATFORM="$IMAGE_PLATFORM" BUILD_ARGS="$(printf 'BASE_IMAGE=%s' "$BASE_LOCAL_REF")" just docker-build-image
	log_substep "Built base image $BASE_IMAGE_REF"
	log_substep "Built runtime image $RUNTIME_IMAGE_REF"

app-docker-push:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_DOCKER_LAYER_SETUP}}
	require_docker() {
	  if ! command -v docker >/dev/null 2>&1; then
	    printf '\033[1;31mError:\033[0m docker CLI not found in PATH.\n' >&2
	    exit 1
	  fi
	}
	ensure_image() {
	  local ref="$1"
	  if ! docker image inspect "$ref" >/dev/null 2>&1; then
	    printf '\033[1;31mError:\033[0m image %s not found locally. Run `just docker-build` first.\n' "$ref" >&2
	    exit 1
	  fi
	}
	set -euo pipefail
	require_docker
	setup_app_docker_layer_context
	if [ -z "$IMAGE_REGISTRY" ]; then
	  log_warn "No image registry configured for environment $ENVIRONMENT; skipping push."
	  exit 0
	fi
	login_disabled=0
	if [ "${APP_DOCKER_DISABLE_LOGIN:-0}" = "1" ] || [ "${SKIP_DOCKER_LOGIN:-0}" = "1" ]; then
	  login_disabled=1
	fi
	app_docker_seen_registries_reset
	app_docker_attempt_login "$IMAGE_REGISTRY" "$login_disabled"
	app_docker_login_additional_registries "$login_disabled"
	log_step "Ensuring repositories for $IMAGE_REGISTRY"
	ensure_ecr_repository "$BASE_REPOSITORY"
	ensure_ecr_repository "$RUNTIME_REPOSITORY"
	ensure_image "$BASE_IMAGE_REF"
	ensure_image "$RUNTIME_IMAGE_REF"
	log_step "Pushing $BASE_IMAGE_REF"
	IMAGE_REF="$BASE_IMAGE_REF" just docker-push-image
	log_step "Pushing $RUNTIME_IMAGE_REF"
	IMAGE_REF="$RUNTIME_IMAGE_REF" just docker-push-image

app-docker-load:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_DOCKER_LAYER_SETUP}}
	require_docker() {
	  if ! command -v docker >/dev/null 2>&1; then
	    printf '\033[1;31mError:\033[0m docker CLI not found in PATH.\n' >&2
	    exit 1
	  fi
	}
	set -euo pipefail
	require_docker
	setup_app_docker_layer_context
	if ! command -v kind >/dev/null 2>&1; then
	  log_warn "kind CLI not found; skipping load"
	  exit 0
	fi
	log_step "Loading images into kind cluster"
	IMAGE_REF="$BASE_IMAGE_REF" just docker-load-image
	IMAGE_REF="$RUNTIME_IMAGE_REF" just docker-load-image

app-docker-security:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{APP_DOCKER_LAYER_SETUP}}
	require_docker() {
	  if ! command -v docker >/dev/null 2>&1; then
	    printf '\033[1;31mError:\033[0m docker CLI not found in PATH.\n' >&2
	    exit 1
	  fi
	}
	set -euo pipefail
	require_docker
	setup_app_docker_layer_context
	if ! docker image inspect "$RUNTIME_IMAGE_REF" >/dev/null 2>&1; then
	  log_step "Runtime image $RUNTIME_IMAGE_REF not found locally; building"
	  just app-docker-build
	  docker image inspect "$RUNTIME_IMAGE_REF" >/dev/null 2>&1 || {
	    log_error "Failed to build runtime image $RUNTIME_IMAGE_REF"
	    exit 1
	  }
	fi
	target_ref="${TRIVY_IMAGE_REF:-$RUNTIME_IMAGE_REF}"
	log_step "Scanning image $target_ref with Trivy"
	tmp_tar="$(mktemp "trivy-image-XXXXXX.tar")"
	trap 'rm -f "$tmp_tar"' EXIT
	log_substep "Saving $target_ref to $tmp_tar"
	docker save "$target_ref" -o "$tmp_tar"
	TRIVY_IMAGE_REF="$target_ref" TRIVY_IMAGE_INPUT="$tmp_tar" just trivy-scan-image

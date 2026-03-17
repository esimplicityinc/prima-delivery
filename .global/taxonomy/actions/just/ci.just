import "./common.just"

# CI-oriented helpers so GitHub workflows can mirror local just recipes.

ci-pre-commit:
	@PYTHON_BIN="${PYTHON_BIN:-python3}" bash "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/scripts/ci/pre-commit.sh"

ci-short-sha:
	@git rev-parse --short=7 "${GITHUB_SHA:-HEAD}"

ci-detect-language directory:
	@bash "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/scripts/ci/detect-language.sh" "{{directory}}"

ci-unit-test directory language package_manager="auto":
	@DIR="{{directory}}" LANGUAGE="{{language}}" PACKAGE_MANAGER="{{package_manager}}" PYTHON_BIN="${PYTHON_BIN:-python3}" bash "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/scripts/ci/run-tests.sh"

ci-semgrep directory project_type="auto":
	@DIR="{{directory}}" PYTHON_BIN="${PYTHON_BIN:-python3}" bash "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/scripts/ci/run-semgrep.sh"

ci-build-app-layer:
	@bash "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/scripts/ci/build-app-layer.sh"

ci-promote-docker-layer system sub_system stack layer environment prev_environment image_tag ghcr_repo ghcr_username ghcr_password aws_account_id aws_region:
	@SYSTEM="{{system}}" SUB_SYSTEM="{{sub_system}}" STACK="{{stack}}" LAYER="{{layer}}" ENVIRONMENT="{{environment}}" PREV_ENVIRONMENT="{{prev_environment}}" IMAGE_TAG="{{image_tag}}" GHCR_REPO="{{ghcr_repo}}" GHCR_USERNAME="{{ghcr_username}}" GHCR_PASSWORD="{{ghcr_password}}" AWS_ACCOUNT_ID="{{aws_account_id}}" AWS_REGION="{{aws_region}}" bash "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/scripts/ci/promote-docker-layer.sh"

ci-terragrunt-layer system sub_system stack layer environment aws_region version="":
	@SYSTEM="{{system}}" SUB_SYSTEM="{{sub_system}}" STACK="{{stack}}" LAYER="{{layer}}" ENVIRONMENT="{{environment}}" AWS_REGION="{{aws_region}}" VERSION="{{version}}" PRE_EXEC="${PRE_EXEC:-}" bash "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/scripts/ci/promote-terragrunt-layer.sh"

ci-argocd-layer system sub_system stack layer environment aws_region github_username github_token:
	@SYSTEM="{{system}}" SUB_SYSTEM="{{sub_system}}" STACK="{{stack}}" LAYER="{{layer}}" ENVIRONMENT="{{environment}}" AWS_REGION="{{aws_region}}" GITHUB_USERNAME="{{github_username}}" GITHUB_TOKEN="{{github_token}}" EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-}" EKS_CLUSTER_PREFIX_SYSTEM="${EKS_CLUSTER_PREFIX_SYSTEM:-prima}" PORT_FORWARD_PORT="${PORT_FORWARD_PORT:-8080}" WAIT_TIMEOUT="${WAIT_TIMEOUT:-600}" GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-}" bash "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/scripts/ci/promote-argocd-layer.sh"

import "../common.just"

KUBECTL_HELPERS := '''
setup_kubectl_context() {
  STACK_DIR="${STACK_DIR:-$(pwd)}"
  if [ -z "${STACK_NAME:-}" ]; then
    export STACK_NAME="$(basename "$STACK_DIR")"
  fi
  PARENT_DIR="$(dirname "$STACK_DIR")"
  if [ -z "${SUBSYSTEM_NAME:-}" ] && [ -n "$PARENT_DIR" ] && [ "$PARENT_DIR" != "$STACK_DIR" ]; then
    export SUBSYSTEM_NAME="$(basename "$PARENT_DIR")"
  fi
  local env_name="$(resolve_layer_env local)"
  export K8S_ENV="$env_name"
  default_layer_dir="$STACK_DIR/k8s"
  export K8S_ROOT="${K8S_ROOT:-$default_layer_dir}"
  if [ -z "${K8S_NAMESPACE:-}" ]; then
    export K8S_NAMESPACE="$(resolve_k8s_namespace "$env_name")"
  fi
}

ensure_kubectl() {
  local kubectl_bin="${KUBECTL:-kubectl}"
  if ! command -v "$kubectl_bin" >/dev/null 2>&1; then
    log_error "kubectl binary not found in PATH"
    exit 1
  fi
}

ensure_kustomize() {
  local kustomize_bin="${KUSTOMIZE:-kustomize}"
  if ! command -v "$kustomize_bin" >/dev/null 2>&1; then
    log_error "kustomize binary not found in PATH"
    exit 1
  fi
}

check_kubectl_installed() {
  local kubectl_bin="${KUBECTL:-kubectl}"
  command -v "$kubectl_bin" >/dev/null 2>&1
}

require_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew (brew) must be installed to manage kubectl"
    exit 1
  fi
}

render_k8s_manifests() {
  if [ -n "${KUBECTL_MANIFEST:-}" ]; then
    if [ ! -f "$KUBECTL_MANIFEST" ]; then
      log_error "Manifest not found: $KUBECTL_MANIFEST"
      exit 1
    fi
    cat "$KUBECTL_MANIFEST"
    return
  fi
  ensure_kustomize
  local kustomize_bin="${KUSTOMIZE:-kustomize}"
  local kustomize_flags="${KUSTOMIZE_FLAGS:---enable-helm}"
  if [ ! -d "$K8S_ROOT" ]; then
    log_error "K8S_ROOT not found: $K8S_ROOT"
    exit 1
  fi
  if [ ! -d "$K8S_ROOT/$K8S_ENV" ]; then
    log_error "Environment overlay not found: $K8S_ROOT/$K8S_ENV"
    exit 1
  fi
  "$kustomize_bin" build $kustomize_flags "$K8S_ROOT/$K8S_ENV"
}

resolve_k8s_namespace() {
  local env_name="${1:-local}"
  local stack_dir="${STACK_DIR:-$(pwd)}"
  if [ -n "${K8S_NAMESPACE:-}" ]; then
    printf '%s\n' "$K8S_NAMESPACE"
    return 0
  fi
  local ns_value=""
  if command -v read_environment_value >/dev/null 2>&1; then
    if ns_value="$(read_environment_value "spec.templateReplacements.namespace" "$env_name" 2>/dev/null)"; then
      ns_value="${ns_value## }"
    else
      ns_value=""
    fi
    if [ -z "$ns_value" ]; then
      if ns_value="$(read_environment_value "spec.layerTemplates.k8s-kustomize.namespace" "$env_name" 2>/dev/null)"; then
        ns_value="${ns_value## }"
      else
        ns_value=""
      fi
    fi
  fi
  if [ -n "$ns_value" ]; then
    printf '%s\n' "$ns_value"
    return 0
  fi
  local prefix="${SYSTEM_NAMESPACE_PREFIX:-${SYSTEM_NAME:-${SUBSYSTEM_NAME:-prima}}}"
  printf '%s-%s\n' "$prefix" "$env_name"
}

ensure_namespace_exists() {
  local kubectl_bin="${KUBECTL:-kubectl}"
  local namespace="${K8S_NAMESPACE:-}"
  if [ -z "$namespace" ]; then
    namespace="$(resolve_k8s_namespace "${K8S_ENV:-$(resolve_layer_env local)}")"
    export K8S_NAMESPACE="$namespace"
  fi
  if "$kubectl_bin" get namespace "$namespace" >/dev/null 2>&1; then
    return 0
  fi
  log_warn "Namespace ${namespace} not found; creating it"
  "$kubectl_bin" create namespace "$namespace" >/dev/null 2>&1
}
'''

kubectl-apply:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUBECTL_HELPERS}}
	set -euo pipefail
	setup_kubectl_context
	ensure_kubectl
	ensure_namespace_exists
	KUBECTL_BIN="${KUBECTL:-kubectl}"
	KUBECTL_APPLY_FLAGS="${KUBECTL_APPLY_FLAGS:-${K8S_APPLY_FLAGS:-}}"
	log_step "kubectl apply for environment ${K8S_ENV} (namespace: ${K8S_NAMESPACE})"
	render_k8s_manifests | "$KUBECTL_BIN" apply $KUBECTL_APPLY_FLAGS -f -

kubectl-delete:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUBECTL_HELPERS}}
	set -euo pipefail
	setup_kubectl_context
	ensure_kubectl
	KUBECTL_BIN="${KUBECTL:-kubectl}"
	KUBECTL_DELETE_FLAGS="${KUBECTL_DELETE_FLAGS:-${K8S_DELETE_FLAGS:---ignore-not-found}}"
	log_step "kubectl delete for environment ${K8S_ENV} (namespace: ${K8S_NAMESPACE})"
	render_k8s_manifests | "$KUBECTL_BIN" delete $KUBECTL_DELETE_FLAGS -f -

kubectl-diff:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUBECTL_HELPERS}}
	set -euo pipefail
	setup_kubectl_context
	ensure_kubectl
	ensure_namespace_exists
	KUBECTL_BIN="${KUBECTL:-kubectl}"
	KUBECTL_DIFF_FLAGS="${KUBECTL_DIFF_FLAGS:-${K8S_DIFF_FLAGS:-}}"
	log_step "kubectl diff for environment ${K8S_ENV} (namespace: ${K8S_NAMESPACE})"
	render_k8s_manifests | "$KUBECTL_BIN" diff $KUBECTL_DIFF_FLAGS -f -

kubectl-rollout-status:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUBECTL_HELPERS}}
	set -euo pipefail
	setup_kubectl_context
	ensure_kubectl
	KUBECTL_BIN="${KUBECTL:-kubectl}"
	if [ -z "${KUBECTL_ROLLOUT_TARGETS:-}" ]; then
	  DEFAULT_NAME="prima-${STACK_NAME:-$(basename "$PWD")}"
	  if [ -d "$K8S_ROOT/base" ] && grep -Rqs --include '*.yaml' 'kind:[[:space:]]*StatefulSet' "$K8S_ROOT/base"; then
	    KUBECTL_ROLLOUT_TARGETS="statefulset/$DEFAULT_NAME"
	  elif [ -d "$K8S_ROOT/base" ] && grep -Rqs --include '*.yaml' 'kind:[[:space:]]*DaemonSet' "$K8S_ROOT/base"; then
	    KUBECTL_ROLLOUT_TARGETS="daemonset/$DEFAULT_NAME"
	  else
	    KUBECTL_ROLLOUT_TARGETS="deployment/$DEFAULT_NAME"
	  fi
	fi
	if [ -z "${KUBECTL_ROLLOUT_TARGETS:-}" ]; then
	  log_error "KUBECTL_ROLLOUT_TARGETS not set and unable to infer a default resource."
	  exit 1
	fi
	log_step "kubectl rollout status for namespace ${K8S_NAMESPACE}"
	for res in $KUBECTL_ROLLOUT_TARGETS; do
	  log_substep "kubectl rollout status $res"
	  "$KUBECTL_BIN" rollout status "$res" -n "$K8S_NAMESPACE" --timeout="${KUBECTL_ROLLOUT_TIMEOUT:-120s}"
	done

kubectl-port-forward:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUBECTL_HELPERS}}
	set -euo pipefail
	setup_kubectl_context
	ensure_kubectl
	KUBECTL_BIN="${KUBECTL:-kubectl}"
	if [ -z "${KUBECTL_PORT_FORWARD_TARGET:-}" ]; then
	  log_error "KUBECTL_PORT_FORWARD_TARGET must be provided (e.g. deployment/my-app)."
	  exit 1
	fi
	local_port="${KUBECTL_PORT_FORWARD_LOCAL:-8080}"
	remote_port="${KUBECTL_PORT_FORWARD_REMOTE:-8080}"
	KUBECTL_PORT_FORWARD_FLAGS="${KUBECTL_PORT_FORWARD_FLAGS:-}"
	log_step "kubectl port-forward $KUBECTL_PORT_FORWARD_TARGET ${local_port}:${remote_port} (namespace: ${K8S_NAMESPACE})"
	"$KUBECTL_BIN" port-forward $KUBECTL_PORT_FORWARD_FLAGS -n "$K8S_NAMESPACE" "$KUBECTL_PORT_FORWARD_TARGET" "${local_port}:${remote_port}"

kubectl-logs:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUBECTL_HELPERS}}
	set -euo pipefail
	setup_kubectl_context
	ensure_kubectl
	KUBECTL_BIN="${KUBECTL:-kubectl}"
	if [ -z "${KUBECTL_LOG_TARGET:-}" ]; then
	  log_error "KUBECTL_LOG_TARGET must be provided (e.g. deployment/my-app)."
	  exit 1
	fi
	KUBECTL_LOG_FLAGS="${KUBECTL_LOG_FLAGS:-}"
	log_step "kubectl logs ${KUBECTL_LOG_TARGET} (namespace: ${K8S_NAMESPACE})"
	"$KUBECTL_BIN" logs $KUBECTL_LOG_FLAGS -n "$K8S_NAMESPACE" "$KUBECTL_LOG_TARGET"

kubectl-verify-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUBECTL_HELPERS}}
	set -euo pipefail
	if ! check_kubectl_installed; then
	  log_error "kubectl not found in PATH"
	  exit 1
	fi
	KUBECTL_BIN="${KUBECTL:-kubectl}"
	if ! version_out="$("$KUBECTL_BIN" version --client --short 2>/dev/null)"; then
	  log_error "kubectl detected but failed to run 'kubectl version --client --short'"
	  exit 1
	fi
	log_step "kubectl installation verified: ${version_out}"

kubectl-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUBECTL_HELPERS}}
	set -euo pipefail
	if check_kubectl_installed; then
	  log_step "kubectl already installed: $(${KUBECTL:-kubectl} version --client --short 2>/dev/null || echo 'version check unavailable')"
	  exit 0
	fi
	require_homebrew
	log_step "Installing kubectl via Homebrew"
	brew install kubectl

kubectl-ensure-namespace:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUBECTL_HELPERS}}
	set -euo pipefail
	setup_kubectl_context
	ensure_kubectl
	ensure_namespace_exists
	log_step "Namespace ${K8S_NAMESPACE} verified"

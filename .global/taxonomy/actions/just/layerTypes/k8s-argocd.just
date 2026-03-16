import "../common.just"
import "../tools/argocd.just"
import "../tools/kubectl.just"

ARGO_LAYER_SETUP := '''
resolve_argo_layer_context() {
  local ensure_layer="${1:-1}"
  local requested_layer="${LAYER_DIR:-${K8S_ROOT:-}}"
  local stack_dir="${STACK_DIR:-}"
  if [ -z "$stack_dir" ] && [ -n "$requested_layer" ]; then
    stack_dir="$(cd "$(dirname "$requested_layer")" >/dev/null 2>&1 && pwd)"
  fi
  stack_dir="${stack_dir:-$PWD}"
  STACK_DIR="$stack_dir"
  if [ -z "${STACK_NAME:-}" ]; then
    STACK_NAME="$(basename "$STACK_DIR")"
  fi
  local default_layer_dir="$STACK_DIR/k8s"
  local layer_dir="${requested_layer:-$default_layer_dir}"
  local require_dir="$ensure_layer"
  if [ -n "$requested_layer" ] || [ -n "${K8S_ROOT:-}" ]; then
    require_dir=1
  fi
  if [ "$require_dir" -eq 1 ]; then
    if [ ! -d "$layer_dir" ]; then
      log_error "Kubernetes layer directory not found: $layer_dir"
      exit 1
    fi
    layer_dir="$(cd "$layer_dir" >/dev/null 2>&1 && pwd)"
    export K8S_ROOT="$layer_dir"
  fi
}
'''

argo-apply:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{ARGO_LAYER_SETUP}}
	set -euo pipefail
	resolve_argo_layer_context 1
	layer_env="$(resolve_layer_env local)"
	ARGO_APP_FILE="${ARGO_APP_FILE:-$K8S_ROOT/$layer_env/argocd-application.yaml}"
	KUBECTL_BIN="${KUBECTL:-kubectl}"
	if [ ! -f "$ARGO_APP_FILE" ]; then
	  log_warn "No Argo Application manifest found for ${STACK_NAME:-$(basename "$PWD")} ($ARGO_APP_FILE)."
	  exit 0
	fi
	ARGO_APPLY_FLAGS="${ARGO_APPLY_FLAGS:-}"
	log_step "Applying Argo CD Application manifest $ARGO_APP_FILE"
	"$KUBECTL_BIN" apply $ARGO_APPLY_FLAGS -f "$ARGO_APP_FILE"

argo-sync:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{ARGO_LAYER_SETUP}}
	set -euo pipefail
	resolve_argo_layer_context 0
	ARGO_APP="${ARGO_APP:-}"
	if [ -z "$ARGO_APP" ]; then
	  log_warn "ARGO_APP not set for ${STACK_NAME:-$(basename "$PWD")}"; exit 0
	fi
	ARGOCTL_BIN="${ARGOCTL:-argocd}"
	KUBECTL_BIN="${KUBECTL:-kubectl}"
	ARGO_NAMESPACE="${ARGO_NAMESPACE:-argocd}"
	if command -v "$ARGOCTL_BIN" >/dev/null 2>&1; then
	  log_step "Syncing Argo CD application $ARGO_APP"
	  "$ARGOCTL_BIN" app sync ${ARGO_SYNC_FLAGS:-} "$ARGO_APP"
	else
	  log_warn "argocd CLI not found; falling back to kubectl annotation for $ARGO_APP"
	  "$KUBECTL_BIN" -n "$ARGO_NAMESPACE" annotate application "$ARGO_APP" argocd.argoproj.io/refresh=hard --overwrite
	fi

argo-wait:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{ARGO_LAYER_SETUP}}
	set -euo pipefail
	resolve_argo_layer_context 0
	ARGO_APP="${ARGO_APP:-}"
	if [ -z "$ARGO_APP" ]; then
	  log_warn "ARGO_APP not set for ${STACK_NAME:-$(basename "$PWD")}"; exit 0
	fi
	KUBECTL_BIN="${KUBECTL:-kubectl}"
	if ! command -v "$KUBECTL_BIN" >/dev/null 2>&1; then
	  log_error "kubectl is required for argo-wait"
	  exit 1
	fi
	ARGO_NAMESPACE="${ARGO_NAMESPACE:-argocd}"
	ARGO_WAIT_ATTEMPTS="${ARGO_WAIT_ATTEMPTS:-30}"
	ARGO_WAIT_INTERVAL="${ARGO_WAIT_INTERVAL:-10}"
	for ((i=1; i<=ARGO_WAIT_ATTEMPTS; i++)); do
	  sync=$($KUBECTL_BIN -n "$ARGO_NAMESPACE" get application "$ARGO_APP" -o jsonpath="{.status.sync.status}" 2>/dev/null || echo unknown)
	  health=$($KUBECTL_BIN -n "$ARGO_NAMESPACE" get application "$ARGO_APP" -o jsonpath="{.status.health.status}" 2>/dev/null || echo unknown)
	  if [ "$sync" = "Synced" ] && [ "$health" = "Healthy" ]; then
	    log_step "$ARGO_APP is Synced/Healthy"
	    exit 0
	  fi
	  log_substep "$ARGO_APP pending (sync=$sync health=$health)"
	  if [ $i -lt $ARGO_WAIT_ATTEMPTS ]; then
	    sleep "$ARGO_WAIT_INTERVAL"
	  fi
	done
	log_error "$ARGO_APP did not reach Synced/Healthy"
	exit 1

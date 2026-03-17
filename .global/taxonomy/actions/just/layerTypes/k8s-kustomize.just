import "../common.just"
import "../tools/kubectl.just"
import "../tools/kube-linter.just"
import "../tools/kubeconform.just"
import "../tools/kubesec.just"
import "../tools/kustomize.just"
import "../tools/polaris.just"

k8s-kustomize-build:
	#!/usr/bin/env bash
	set -euo pipefail
	just kustomize-build

k8s-kustomize-apply:
	#!/usr/bin/env bash
	set -euo pipefail
	just kubectl-ensure-namespace
	just kubectl-apply

k8s-kustomize-delete:
	#!/usr/bin/env bash
	set -euo pipefail
	just kubectl-delete

k8s-kustomize-diff:
	#!/usr/bin/env bash
	set -euo pipefail
	just kubectl-ensure-namespace
	just kubectl-diff

k8s-kustomize-fmt:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUSTOMIZE_HELPERS}}
	{{KUBECONFORM_TOOL_HELPERS}}
	set -euo pipefail
	setup_kustomize_context
	if ! check_kubeconform_installed; then
	  log_error "kubeconform binary not found; run 'just kubeconform-install'"
	  exit 1
	fi
	tmp_dir="$(mktemp -d)"
	trap 'rm -rf "$tmp_dir"' EXIT
	output="$tmp_dir/rendered.yaml"
	render_kustomize > "$output"
	KUBECONFORM_BIN_PATH="$(kubeconform_bin)"
	KUBECONFORM_FLAGS="${KUBECONFORM_FLAGS:--strict -summary -ignore-missing-schemas -skip argoproj.io/v1alpha1/Application,argoproj.io/v1alpha1/AppProject}"
	log_step "Validating rendered manifests with kubeconform"
	if ! "$KUBECONFORM_BIN_PATH" $KUBECONFORM_FLAGS "$output"; then
	  status=$?
	  exit $status
	fi

k8s-kustomize-lint:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUSTOMIZE_HELPERS}}
	{{KUBE_LINTER_TOOL_HELPERS}}
	set -euo pipefail
	tmp_dir="$(mktemp -d)"
	trap 'rm -rf "$tmp_dir"' EXIT
	setup_kustomize_context
	if ! check_kubelinter_installed; then
	  log_error "kube-linter binary not found; run 'just kube-linter-install'"
	  exit 1
	fi
	output="$tmp_dir/rendered.yaml"
	render_kustomize > "$output"
	KUBE_LINTER_BIN_PATH="$(kubelinter_bin)"
	log_step "Running kube-linter against rendered manifests"
	if ! "$KUBE_LINTER_BIN_PATH" lint "$output"; then
	  status=$?
	  exit $status
	fi

k8s-kustomize-security:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUSTOMIZE_HELPERS}}
	{{KUBESEC_TOOL_HELPERS}}
	set -euo pipefail
	setup_kustomize_context
	if ! check_kubesec_installed; then
	  log_error "kubesec binary not found; run 'just kubesec-install'"
	  exit 1
	fi
	tmp_dir="$(mktemp -d)"
	trap 'rm -rf "$tmp_dir"' EXIT
	output="$tmp_dir/rendered.yaml"
	render_kustomize > "$output"
	KUBESEC_BIN_PATH="$(kubesec_bin)"
	log_step "Running kubesec scan against rendered manifests"
	"$KUBESEC_BIN_PATH" scan "$output"

k8s-kustomize-polaris:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUSTOMIZE_HELPERS}}
	{{POLARIS_TOOL_HELPERS}}
	set -euo pipefail
	setup_kustomize_context
	if ! check_polaris_installed; then
	  log_error "polaris binary not found; run 'just polaris-install'"
	  exit 1
	fi
	tmp_dir="$(mktemp -d)"
	trap 'rm -rf "$tmp_dir"' EXIT
	render_kustomize > "$tmp_dir/rendered.yaml"
	POLARIS_BIN_PATH="$(polaris_bin)"
	POLARIS_FLAGS="${POLARIS_FLAGS:---only-show-failed-tests --set-exit-code-on-danger}"
	log_step "Running Polaris audit"
	if ! "$POLARIS_BIN_PATH" audit --audit-path "$tmp_dir" $POLARIS_FLAGS; then
	  status=$?
	  exit $status
	fi

k8s-kustomize-check:
	#!/usr/bin/env bash
	set -euo pipefail
	just k8s-kustomize-fmt
	just k8s-kustomize-lint
	just k8s-kustomize-security

k8s-kustomize-restart:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	set -euo pipefail
	stack_dir="${STACK_DIR:-}"
	if [ -z "$stack_dir" ] && [ -n "${LAYER_DIR:-}" ]; then
	  stack_dir="$(cd "$(dirname "$LAYER_DIR")" >/dev/null 2>&1 && pwd)"
	fi
	STACK_DIR="${stack_dir:-$PWD}"
	if [ -n "${LAYER_DIR:-}" ] && [ -z "${K8S_ROOT:-}" ]; then
	  K8S_ROOT="$(cd "$LAYER_DIR" >/dev/null 2>&1 && pwd)"
	fi
	if [ -z "${STACK_NAME:-}" ]; then
	  STACK_NAME="$(basename "$STACK_DIR")"
	fi
	if [ -z "${SUBSYSTEM_NAME:-}" ]; then
	  SUBSYSTEM_NAME="$(basename "$(dirname "$STACK_DIR")")"
	fi
	layer_env="$(resolve_layer_env local)"
	system_prefix="${SYSTEM_NAMESPACE_PREFIX:-${SYSTEM_NAME:-prima}}"
	K8S_NAMESPACE="${K8S_NAMESPACE:-${system_prefix}-${layer_env}}"
	K8S_RESTART_TARGETS="${K8S_RESTART_TARGETS:-}"
	if [ -z "$K8S_RESTART_TARGETS" ]; then
	  DEFAULT="prima-${STACK_NAME}"
	  KUSTOMIZE_ROOT="${KUSTOMIZE_ROOT:-${K8S_ROOT:-$STACK_DIR/k8s}}"
	  if [ -d "$KUSTOMIZE_ROOT/base" ] && grep -Rqs --include '*.yaml' 'kind:[[:space:]]*StatefulSet' "$KUSTOMIZE_ROOT/base"; then
	    K8S_RESTART_TARGETS="statefulset/$DEFAULT"
	  elif [ -d "$KUSTOMIZE_ROOT/base" ] && grep -Rqs --include '*.yaml' 'kind:[[:space:]]*DaemonSet' "$KUSTOMIZE_ROOT/base"; then
	    K8S_RESTART_TARGETS="daemonset/$DEFAULT"
	  else
	  K8S_RESTART_TARGETS="deployment/$DEFAULT"
	  fi
	fi
	if [ -z "$K8S_RESTART_TARGETS" ]; then
	  log_error "K8S_RESTART_TARGETS not set and unable to infer default resource."
	  exit 1
	fi
	KUBECTL_BIN="${KUBECTL:-kubectl}"
	log_step "kubectl rollout restart for namespace ${K8S_NAMESPACE}"
	for res in $K8S_RESTART_TARGETS; do
	  log_substep "Restarting $res"
	  "$KUBECTL_BIN" rollout restart "$res" -n "$K8S_NAMESPACE"
	  "$KUBECTL_BIN" rollout status "$res" -n "$K8S_NAMESPACE" --timeout="${KUBECTL_ROLLOUT_TIMEOUT:-120s}"
	done

k8s-kustomize-clean-jobs:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	set -euo pipefail
	stack_dir="${STACK_DIR:-}"
	if [ -z "$stack_dir" ] && [ -n "${LAYER_DIR:-}" ]; then
	  stack_dir="$(cd "$(dirname "$LAYER_DIR")" >/dev/null 2>&1 && pwd)"
	fi
	STACK_DIR="${stack_dir:-$PWD}"
	if [ -n "${LAYER_DIR:-}" ] && [ -z "${K8S_ROOT:-}" ]; then
	  K8S_ROOT="$(cd "$LAYER_DIR" >/dev/null 2>&1 && pwd)"
	fi
	if [ -z "${SUBSYSTEM_NAME:-}" ]; then
	  SUBSYSTEM_NAME="$(basename "$(dirname "$STACK_DIR")")"
	fi
	if [ -z "${K8S_JOBS_TO_CLEAN:-}" ]; then
	  log_warn "K8S_JOBS_TO_CLEAN not set; nothing to clean."
	  exit 0
	fi
	layer_env="$(resolve_layer_env local)"
	system_prefix="${SYSTEM_NAMESPACE_PREFIX:-${SYSTEM_NAME:-prima}}"
	K8S_NAMESPACE="${K8S_NAMESPACE:-${system_prefix}-${layer_env}}"
	KUBECTL_BIN="${KUBECTL:-kubectl}"
	for job in $K8S_JOBS_TO_CLEAN; do
	  log_step "Deleting job $job in namespace $K8S_NAMESPACE"
	  "$KUBECTL_BIN" delete job "$job" -n "$K8S_NAMESPACE" --ignore-not-found
	  "$KUBECTL_BIN" wait --for=delete "job/$job" -n "$K8S_NAMESPACE" --timeout=60s || true
	done

import "../common.just"

KUSTOMIZE_HELPERS := '''
setup_kustomize_context() {
  local stack_dir="${STACK_DIR:-}"
  if [ -z "$stack_dir" ] && [ -n "${LAYER_DIR:-}" ]; then
    stack_dir="$(cd "$(dirname "$LAYER_DIR")" >/dev/null 2>&1 && pwd)"
  fi
  STACK_DIR="${stack_dir:-$(pwd)}"
  local env_name="$(resolve_layer_env local)"
  export K8S_ENV="$env_name"
  local default_layer_dir="$STACK_DIR/k8s"
  local layer_dir="${LAYER_DIR:-${K8S_ROOT:-$default_layer_dir}}"
  if [ ! -d "$layer_dir" ]; then
    log_error "Kustomize root not found: $layer_dir"
    exit 1
  fi
  layer_dir="$(cd "$layer_dir" >/dev/null 2>&1 && pwd)"
  export KUSTOMIZE_ROOT="$layer_dir"
  if [ ! -d "$KUSTOMIZE_ROOT/base" ]; then
    log_error "Kustomize base directory missing: $KUSTOMIZE_ROOT/base"
    exit 1
  fi
  if [ ! -d "$KUSTOMIZE_ROOT/$K8S_ENV" ]; then
    log_error "Environment overlay not found: $KUSTOMIZE_ROOT/$K8S_ENV"
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

ensure_kubectl() {
  local kubectl_bin="${KUBECTL:-kubectl}"
  if ! command -v "$kubectl_bin" >/dev/null 2>&1; then
    log_error "kubectl binary not found in PATH"
    exit 1
  fi
}

render_kustomize() {
  ensure_kustomize
  local kustomize_bin="${KUSTOMIZE:-kustomize}"
  local kustomize_flags="${KUSTOMIZE_FLAGS:---enable-helm}"
  "$kustomize_bin" build $kustomize_flags "$KUSTOMIZE_ROOT/$K8S_ENV"
}

check_kustomize_installed() {
  local kustomize_bin="${KUSTOMIZE:-kustomize}"
  command -v "$kustomize_bin" >/dev/null 2>&1
}

require_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew (brew) must be installed to manage kustomize"
    exit 1
  fi
}
'''

kustomize-build:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUSTOMIZE_HELPERS}}
	set -euo pipefail
	setup_kustomize_context
	log_step "Rendering Kustomize manifests for ${K8S_ENV}"
	if [ -n "${KUSTOMIZE_OUTPUT:-}" ]; then
	  tmp_file="$(mktemp)"
	  trap 'rm -f "$tmp_file"' EXIT
	  render_kustomize > "$tmp_file"
	  mv "$tmp_file" "$KUSTOMIZE_OUTPUT"
	  trap - EXIT
	  log_substep "Wrote manifests to ${KUSTOMIZE_OUTPUT}"
	else
	  render_kustomize
	fi

kustomize-diff:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUSTOMIZE_HELPERS}}
	set -euo pipefail
	setup_kustomize_context
	diff_strategy="${KUSTOMIZE_DIFF_STRATEGY:-cluster}"
	case "$diff_strategy" in
	  cluster)
	    ensure_kubectl
	    KUBECTL_BIN="${KUBECTL:-kubectl}"
	    KUBECTL_DIFF_FLAGS="${KUBECTL_DIFF_FLAGS:-${K8S_DIFF_FLAGS:-}}"
	    log_step "kubectl diff for rendered manifests in ${K8S_ENV}"
	    render_kustomize | "$KUBECTL_BIN" diff $KUBECTL_DIFF_FLAGS -f -
	    ;;
	  file)
	    if [ -z "${KUSTOMIZE_DIFF_BASELINE:-}" ]; then
	      log_error "KUSTOMIZE_DIFF_BASELINE must be provided when KUSTOMIZE_DIFF_STRATEGY=file"
	      exit 1
	    fi
	    if [ ! -f "$KUSTOMIZE_DIFF_BASELINE" ]; then
	      log_error "Baseline file not found: $KUSTOMIZE_DIFF_BASELINE"
	      exit 1
	    fi
	    tmp_file="$(mktemp)"
	    trap 'rm -f "$tmp_file"' EXIT
	    render_kustomize > "$tmp_file"
	    log_step "Diffing rendered manifests against ${KUSTOMIZE_DIFF_BASELINE}"
	    if ! diff -u "$KUSTOMIZE_DIFF_BASELINE" "$tmp_file"; then
	      status=$?
	      rm -f "$tmp_file"
	      exit $status
	    fi
	    rm -f "$tmp_file"
	    trap - EXIT
	    ;;
	  *)
	    log_error "Unknown KUSTOMIZE_DIFF_STRATEGY: $diff_strategy"
	    exit 1
	    ;;
	esac

kustomize-validate:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUSTOMIZE_HELPERS}}
	set -euo pipefail
	setup_kustomize_context
	KUBECONFORM_IMAGE="${KUBECONFORM_IMAGE:-ghcr.io/yannh/kubeconform:latest}"
	KUBECONFORM_FLAGS="${KUBECONFORM_FLAGS:--strict -summary -ignore-missing-schemas -skip argoproj.io/v1alpha1/Application,argoproj.io/v1alpha1/AppProject}"
	log_step "Validating rendered manifests with kubeconform"
	render_kustomize | docker run --rm -i "$KUBECONFORM_IMAGE" ${KUBECONFORM_FLAGS}

kustomize-verify-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUSTOMIZE_HELPERS}}
	set -euo pipefail
	if ! check_kustomize_installed; then
	  log_error "kustomize not found in PATH"
	  exit 1
	fi
	KUSTOMIZE_BIN="${KUSTOMIZE:-kustomize}"
	if ! version_out="$("$KUSTOMIZE_BIN" version 2>/dev/null)"; then
	  log_error "kustomize detected but failed to run 'kustomize version'"
	  exit 1
	fi
	log_step "kustomize installation verified: ${version_out}"

kustomize-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{KUSTOMIZE_HELPERS}}
	set -euo pipefail
	if check_kustomize_installed; then
	  log_step "kustomize already installed: $(${KUSTOMIZE:-kustomize} version 2>/dev/null || echo 'version check unavailable')"
	  exit 0
	fi
	require_homebrew
	log_step "Installing kustomize via Homebrew"
	brew install kustomize

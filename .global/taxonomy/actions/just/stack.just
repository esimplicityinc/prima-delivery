import "./common.just"
import "./layerTypes/app-bun.just"
import "./layerTypes/app-docker.just"
import "./layerTypes/k8s-kustomize.just"
import "./layerTypes/k8s-argocd.just"
import "./layerTypes/iac-terragrunt.just"
import "./layerTypes/docs-docusaurus.just"
import "./layerTypes/docs-subsystem.just"
import "./layerTypes/docs-stack.just"
import "./layerTypes/tests-bdd.just"

# Stack orchestration helpers mirroring .global/make/stack.mk.

STACK_SETUP := '''
stack_name="${STACK_NAME:-$(basename "$PWD")}" 
stack_layers="$(printf '%s' "${STACK_LAYERS:-app-docker k8s-kustomize k8s-argocd}" | xargs)"

has_layer() {
  case " $stack_layers " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

has_layer_alias() {
  local aliases="$1"
  for candidate in $aliases; do
    if has_layer "$candidate"; then
      return 0
    fi
  done
  return 1
}

stack_has_app=0; has_layer_alias "app app-docker" && stack_has_app=1
stack_has_k8s=0; has_layer_alias "k8s k8s-kustomize k8s-argo k8s-argocd" && stack_has_k8s=1
stack_has_argo=0; has_layer_alias "argo k8s-argocd k8s-argo" && stack_has_argo=1
stack_has_iac=0
if has_layer iac || has_layer iac-terragrunt || has_layer terragrunt; then
  stack_has_iac=1
fi

stack_include_k8s_apply=""
if [ "$stack_has_k8s" -eq 1 ] && [ "$stack_has_argo" -eq 0 ]; then
  stack_include_k8s_apply="k8s-kustomize-apply"
fi

default_sync=()
if [ "$stack_has_app" -eq 1 ]; then
  default_sync+=(app-docker-build app-docker-push)
fi
if [ -n "$stack_include_k8s_apply" ]; then
  default_sync+=("$stack_include_k8s_apply")
fi
if [ "$stack_has_argo" -eq 1 ]; then
  default_sync+=(argo-apply argo-sync argo-wait)
fi
if [ "$stack_has_iac" -eq 1 ]; then
  default_sync+=(iac-terragrunt-plan)
fi
default_sync_str="${default_sync[*]}"

default_bootstrap="$default_sync_str"

default_wait=""
if [ "$stack_has_argo" -eq 1 ]; then
  default_wait="argo-wait"
fi

default_clean=""

trim() { printf '%s' "$1" | xargs; }

stack_sync_targets_raw="${STACK_SYNC_TARGETS:-}"
if [ -n "$stack_sync_targets_raw" ] && [ -n "$(trim "$stack_sync_targets_raw")" ]; then
  stack_sync_targets="$stack_sync_targets_raw"
else
  stack_sync_targets="$default_sync_str"
fi

stack_bootstrap_targets_raw="${STACK_BOOTSTRAP_TARGETS:-}"
if [ -n "$stack_bootstrap_targets_raw" ] && [ -n "$(trim "$stack_bootstrap_targets_raw")" ]; then
  stack_bootstrap_targets="$stack_bootstrap_targets_raw"
else
  stack_bootstrap_targets="$default_bootstrap"
fi

stack_wait_targets_raw="${STACK_WAIT_TARGETS:-}"
if [ -n "$stack_wait_targets_raw" ] && [ -n "$(trim "$stack_wait_targets_raw")" ]; then
  stack_wait_targets="$stack_wait_targets_raw"
else
  stack_wait_targets="$default_wait"
fi

stack_clean_targets_raw="${STACK_CLEAN_TARGETS:-}"
if [ -n "$stack_clean_targets_raw" ] && [ -n "$(trim "$stack_clean_targets_raw")" ]; then
  stack_clean_targets="$stack_clean_targets_raw"
else
  stack_clean_targets="$default_clean"
fi

stack_sync_empty_message="${STACK_SYNC_EMPTY_MESSAGE:-$stack_name: no sync steps defined; override STACK_SYNC_TARGETS.}"
stack_bootstrap_empty_message="${STACK_BOOTSTRAP_EMPTY_MESSAGE:-$stack_name: no bootstrap steps defined; override STACK_BOOTSTRAP_TARGETS.}"
stack_wait_empty_message="${STACK_WAIT_EMPTY_MESSAGE:-$stack_name: no wait steps defined; override STACK_WAIT_TARGETS.}"
stack_clean_empty_message="${STACK_CLEAN_EMPTY_MESSAGE:-$stack_name: no additional cleanup steps defined.}"

run_steps() {
  local sequence="$1"
  local empty_message="$2"
  if [ -z "$(trim "$sequence")" ]; then
    if [ -n "$empty_message" ]; then
      echo "$empty_message"
    fi
    return 0
  fi
  set -e
  for tgt in $sequence; do
    if [ -n "$tgt" ]; then
      echo "==> $tgt"
      just "$tgt"
    fi
  done
}
'''

stack-sync:
	echo "==> Running stack sync sequence"
	{{STACK_SETUP}}
	run_steps "$stack_sync_targets" "$stack_sync_empty_message"

stack-bootstrap:
	echo "==> Running stack bootstrap sequence"
	{{STACK_SETUP}}
	run_steps "$stack_bootstrap_targets" "$stack_bootstrap_empty_message"

stack-wait:
	echo "==> Running stack wait sequence"
	{{STACK_SETUP}}
	run_steps "$stack_wait_targets" "$stack_wait_empty_message"

stack-clean:
	echo "==> Running stack clean sequence"
	{{STACK_SETUP}}
	run_steps "$stack_clean_targets" "$stack_clean_empty_message"

stack-run-sequence:
	echo "==> Running custom stack sequence"
	{{STACK_SETUP}}
	if [ -z "${STACK_SEQUENCE:-}" ]; then
	echo "STACK_SEQUENCE not set; provide space-separated steps."
	exit 1
	fi
	stack_sync_empty_message=""
	run_steps "$STACK_SEQUENCE" ""

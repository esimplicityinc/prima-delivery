import "../common.just"
import "../documentation.just"
import "../tools/terragrunt.just"
import "../tools/trivy.just"
import "../tools/terramaid.just"

IAC_TERRAGRUNT_LAYER_SETUP := '''
setup_iac_terragrunt_layer_context() {
	ENVIRONMENT="$(resolve_layer_env local)"
  local requested_layer="${LAYER_DIR:-${IAC_LAYER_DIR:-}}"
  local stack_dir="${STACK_DIR:-}"
  if [ -z "$stack_dir" ] && [ -n "$requested_layer" ]; then
    stack_dir="$(cd "$(dirname "$requested_layer")" >/dev/null 2>&1 && pwd)"
  fi
  stack_dir="${stack_dir:-$PWD}"
  STACK_DIR="$stack_dir"
  local default_layer_dir="$STACK_DIR/iac"
  local layer_root="${requested_layer:-$default_layer_dir}"
  if [ ! -d "$layer_root" ]; then
    printf '\033[1;31mError:\033[0m iac-terragrunt layer directory not found: %s\n' "$layer_root" >&2
    exit 1
  fi
  layer_root="$(cd "$layer_root" >/dev/null 2>&1 && pwd)"
  log_substep "iac-terragrunt environment: $ENVIRONMENT"
  log_substep "iac-terragrunt layer root: $layer_root"
  local target_dir="${IAC_TERRAGRUNT_DIR:-}"
  if [ -z "$target_dir" ]; then
    if [ -d "$layer_root/$ENVIRONMENT" ]; then
      target_dir="$layer_root/$ENVIRONMENT"
    else
      target_dir="$layer_root"
    fi
  fi
  log_substep "iac-terragrunt target dir: $target_dir"
  if [ ! -d "$target_dir" ]; then
    printf '\033[1;31mError:\033[0m Terragrunt target directory not found: %s\n' "$target_dir" >&2
    exit 1
  fi
  if [ ! -f "$target_dir/terragrunt.hcl" ]; then
    printf '\033[1;33mWarning:\033[0m No terragrunt.hcl found in %s; Terragrunt may fail.\n' "$target_dir" >&2
  fi
  export IAC_LAYER_ROOT="$layer_root"
  export IAC_TERRAGRUNT_WORKDIR="$target_dir"
  export TERRAGRUNT_DIR="$target_dir"
}
'''

iac-terragrunt-version:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{IAC_TERRAGRUNT_LAYER_SETUP}}
	set -euo pipefail
	setup_iac_terragrunt_layer_context
	just terragrunt-version

iac-terragrunt-plan:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{IAC_TERRAGRUNT_LAYER_SETUP}}
	set -euo pipefail
	setup_iac_terragrunt_layer_context
	just terragrunt-plan

iac-terragrunt-apply:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{IAC_TERRAGRUNT_LAYER_SETUP}}
	set -euo pipefail
	setup_iac_terragrunt_layer_context
	just terragrunt-apply

iac-terragrunt-destroy:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{IAC_TERRAGRUNT_LAYER_SETUP}}
	set -euo pipefail
	setup_iac_terragrunt_layer_context
	just terragrunt-destroy

iac-terragrunt-hclfmt:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{IAC_TERRAGRUNT_LAYER_SETUP}}
	set -euo pipefail
	setup_iac_terragrunt_layer_context
	just terragrunt-hclfmt

iac-terragrunt-fmt:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{IAC_TERRAGRUNT_LAYER_SETUP}}
	set -euo pipefail
	setup_iac_terragrunt_layer_context
	just terragrunt-fmt

iac-terragrunt-run-all-plan:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{IAC_TERRAGRUNT_LAYER_SETUP}}
	set -euo pipefail
	setup_iac_terragrunt_layer_context
	just terragrunt-run-all-plan

iac-terragrunt-run-all-apply:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{IAC_TERRAGRUNT_LAYER_SETUP}}
	set -euo pipefail
	setup_iac_terragrunt_layer_context
	just terragrunt-run-all-apply

iac-terragrunt-clean:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{IAC_TERRAGRUNT_LAYER_SETUP}}
	set -euo pipefail
	setup_iac_terragrunt_layer_context
	just terragrunt-clean

iac-terragrunt-unlock:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{IAC_TERRAGRUNT_LAYER_SETUP}}
	set -euo pipefail
	setup_iac_terragrunt_layer_context
	LOCK_ID="${LOCK_ID:-}"
	TERRAGRUNT_STATE="${TERRAGRUNT_STATE:-}"
	BACKEND_TABLE="${BACKEND_TABLE:-}"
	if [ -z "$TERRAGRUNT_STATE" ]; then
	  printf 'Enter TERRAGRUNT_STATE (e.g. s3://bucket/path/to/state.tfstate): ' >&2
	  read -r TERRAGRUNT_STATE
	fi
	if [ -z "$TERRAGRUNT_STATE" ]; then
	  log_error "TERRAGRUNT_STATE is required (s3 state bucket/key, e.g. s3://bucket/path/to/state.tfstate)"
	  exit 1
	fi
	if [ -z "$LOCK_ID" ] && [ -n "$BACKEND_TABLE" ]; then
	  log_step "Attempting to read lock from DynamoDB table ${BACKEND_TABLE} for state ${TERRAGRUNT_STATE}"
	  LOCK_ID="$(aws dynamodb get-item \
	    --table-name "$BACKEND_TABLE" \
	    --key "{\"LockID\": {\"S\": \"${TERRAGRUNT_STATE}\"}}" \
	    --query 'Item.Info.S' \
	    --output text 2>/dev/null || true)"
	fi
	if [ -z "$LOCK_ID" ]; then
	  printf 'Enter the Terraform lock ID (LOCK_ID): ' >&2
	  read -r LOCK_ID
	fi
	if [ -z "$LOCK_ID" ]; then
	  log_error "LOCK_ID is required (terraform state lock id)"
	  exit 1
	fi
	log_step "Clearing Terraform lock ${LOCK_ID} for state ${TERRAGRUNT_STATE}"
	TERRAGRUNT_CLI_ARGS="state unlock ${LOCK_ID}" just terragrunt-runner -- --terragrunt-working-dir "$IAC_TERRAGRUNT_WORKDIR" --terragrunt-state "$TERRAGRUNT_STATE"

iac-terragrunt-security:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{IAC_TERRAGRUNT_LAYER_SETUP}}
	set -euo pipefail
	setup_iac_terragrunt_layer_context
	tmp_dir="$(mktemp -d)"
	trap 'rm -rf "$tmp_dir"' EXIT
	(
	  export TERRAGRUNT_PLAN_ARGS="${TERRAGRUNT_PLAN_ARGS:--out=$tmp_dir/plan.tfplan}"
	  just terragrunt-plan
	)
	log_step "Rendering Terraform plan JSON"
	if command -v terragrunt >/dev/null 2>&1; then
	  (cd "$IAC_TERRAGRUNT_WORKDIR" && terragrunt show -json "$tmp_dir/plan.tfplan") > "$tmp_dir/plan.json"
	elif command -v terraform >/dev/null 2>&1; then
	  terraform show -json "$tmp_dir/plan.tfplan" > "$tmp_dir/plan.json"
	else
	  log_error "Neither terragrunt nor terraform found in PATH to render plan JSON"
	  exit 1
	fi
	TRIVY_CONFIG_TARGET="$tmp_dir/plan.json" TRIVY_CONFIG_FORMAT="${TRIVY_CONFIG_FORMAT:-sarif}" just trivy-scan-config

iac-terragrunt-docs:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{AUTO_LAYER_README_HELPERS}}
	{{LAYER_DOCUMENTATION_HELPERS}}
	{{IAC_TERRAGRUNT_LAYER_SETUP}}
	set -euo pipefail
	setup_iac_terragrunt_layer_context
	layer_path="${IAC_LAYER_ROOT:-}"
	if [ -z "$layer_path" ] || [ ! -d "$layer_path" ]; then
	  log_error "Unable to determine iac-terragrunt layer directory (IAC_LAYER_ROOT=${layer_path:-unset})."
	  exit 1
	fi
	layer_workdir="${IAC_TERRAGRUNT_WORKDIR:-$layer_path}"
	layer_rel="${layer_path#$REPO_ROOT/}"
	[ "$layer_rel" = "$layer_path" ] && layer_rel="$(basename "$layer_path")"
	tmp_dir="$(mktemp -d)"
	trap 'rm -rf "$tmp_dir"' EXIT
	layer_doc="${tmp_dir}/layer.md"
	terramaid_doc="${tmp_dir}/terramaid.mmd"
	combined_doc="${tmp_dir}/combined.md"
	log_step "Rendering layer overview for ${layer_rel}"
	if ! generate_layer_doc_content "$layer_path" >"$layer_doc"; then
	  log_error "Failed to render documentation for ${layer_rel}"
	  exit 1
	fi
	plan_file="${tmp_dir}/doc-plan.tfplan"
	log_step "Creating Terraform plan for ${layer_rel} (${ENVIRONMENT})"
	if ! (
	  export TERRAGRUNT_PLAN_ARGS="-out=$plan_file"
	  just terragrunt-plan
	); then
	  log_error "terragrunt plan failed; aborting documentation update."
	  exit 1
	fi
	terra_workdir="${IAC_TERRAGRUNT_WORKDIR:-$layer_workdir}"
	terra_data_dir=""
	cache_root="${layer_workdir}/.terragrunt-cache"
	if [ -d "$cache_root" ]; then
	  terraform_dir="$(CACHE_ROOT="$cache_root" python3 - <<-'PY'
	import os
	root = os.environ["CACHE_ROOT"]
	latest = ""
	latest_mtime = -1.0
	for current_root, dirs, files in os.walk(root):
	    if os.path.basename(current_root) == ".terraform":
	        try:
	            mtime = os.path.getmtime(current_root)
	        except OSError:
	            continue
	        if mtime > latest_mtime:
	            latest_mtime = mtime
	            latest = current_root
	print(latest)
	PY
	)"
	  terraform_dir="$(printf '%s' "$terraform_dir" | tr -d '\n')"
	  if [ -n "$terraform_dir" ]; then
	    terra_workdir="$(dirname "$terraform_dir")"
	    terra_data_dir="$terraform_dir"
	    log_substep "Using Terraform module dir ${terra_workdir} for Terramaid"
	  else
	    log_substep "No .terraform directory found in ${cache_root}; Terramaid may need to re-download providers"
	  fi
	else
	  log_substep "No .terragrunt-cache detected; Terramaid may need to re-download providers"
	fi
	log_step "Generating Terramaid diagram"
	env_cmd=(env TF_IGNORE_DEPENDENCY_LOCK_CHECKS=1 TF_CLI_ARGS_init="-upgrade=false")
	if [ -n "$terra_data_dir" ]; then
	  env_cmd+=(TF_DATA_DIR="$terra_data_dir")
	fi
	wrapper_bin="$REPO_ROOT/.global/scripts/terraform-via-terragrunt.sh"
	if [ -x "$wrapper_bin" ]; then
	  env_cmd+=(TERRAMAID_TF_BINARY="$wrapper_bin")
	  terragrunt_exec="$(command -v "${TERRAGRUNT_BIN:-terragrunt}" 2>/dev/null || true)"
	  terraform_exec="$(command -v "${TERRAFORM_BIN:-terraform}" 2>/dev/null || true)"
	  if [ -n "$terragrunt_exec" ]; then
	    env_cmd+=(TERRAMAID_TERRAGRUNT_BIN="$terragrunt_exec")
	  fi
	  if [ -n "$terraform_exec" ]; then
	    env_cmd+=(TERRAMAID_TERRAFORM_BIN="$terraform_exec")
	  fi
	fi
	env_cmd+=(
	  TERRAMAID_PLAN_FILE="$plan_file"
	  TERRAMAID_WORKING_DIR="$terra_workdir"
	  TERRAMAID_DOC_OUTPUT="$terramaid_doc"
	  just
	  terramaid-docs
	)
	if ! "${env_cmd[@]}"; then
	  log_error "Terramaid rendering failed."
	  exit 1
	fi
	cat "$layer_doc" >"$combined_doc"
	diagram_doc="$terramaid_doc"
	if [ -s "$terramaid_doc" ]; then
	  cleaned_doc="${tmp_dir}/terramaid.mmd.cleaned"
	  python3 - "$terramaid_doc" "$cleaned_doc" <<-'PY'
	import sys
	from pathlib import Path

	src_path = Path(sys.argv[1])
	dst_path = Path(sys.argv[2])

	try:
	    lines = src_path.read_text(encoding="utf-8").splitlines()
	except OSError:
	    lines = []

	if lines and lines[0].strip().startswith("```"):
	    lines = lines[1:]
	if lines and lines[-1].strip().startswith("```"):
	    lines = lines[:-1]

	text = "\n".join(lines).rstrip()
	if text:
	    text += "\n"
	dst_path.write_text(text, encoding="utf-8")
	PY
	  if [ -s "$cleaned_doc" ]; then
	    diagram_doc="$cleaned_doc"
	  fi
	fi
	if [ -s "$diagram_doc" ]; then
	  {
	    printf '\n### Terraform plan diagram (%s)\n\n```mermaid\n' "$ENVIRONMENT"
	    cat "$diagram_doc"
	    printf '\n```\n'
	  } >>"$combined_doc"
	fi
	update_auto_layer_section_from_file "$layer_path/README.md" "" "$combined_doc"
	log_substep "Updated ${layer_rel}/README.md with Terramaid diagram"

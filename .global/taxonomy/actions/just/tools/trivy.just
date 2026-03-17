import "../common.just"

trivy-scan-image:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	ref="${TRIVY_IMAGE_REF:-}"
	input="${TRIVY_IMAGE_INPUT:-}"
	severity="${TRIVY_SEVERITY:-CRITICAL,HIGH}"
	format="${TRIVY_FORMAT:-table}"
	output="${TRIVY_OUTPUT:-}"
	exit_code="${TRIVY_EXIT_CODE:-1}"
	if [ -z "$ref" ] && [ -z "$input" ]; then
		log_error "TRIVY_IMAGE_REF must be provided"
		exit 1
	fi
	if [ -z "$output" ]; then
		identifier="${ref:-$input}"
		ref_slug="$(printf '%s' "$identifier" | tr '/:' '__')"
		output="trivy-report-${ref_slug}.txt"
	fi
	cmd=(trivy image --severity "$severity" --format "$format")
	if [ -n "$exit_code" ]; then
		cmd+=(--exit-code "$exit_code")
	fi
	if [ "${TRIVY_IGNORE_UNFIXED:-}" = "true" ]; then
		cmd+=(--ignore-unfixed)
	fi
	if [ -n "${TRIVY_EXTRA_ARGS:-}" ]; then
		# shellcheck disable=SC2086
		cmd+=($TRIVY_EXTRA_ARGS)
	fi
	log_step "Running Trivy scan for $ref"
	log_substep "Writing scan report to $output"
	if [ -n "$input" ]; then
		cmd+=(--input "$input")
	else
		cmd+=("$ref")
	fi
	set +e
	(
		set -o pipefail
		"${cmd[@]}" | tee "$output"
	)
	status=$?
	set -e
	should_cat=0
	if [ -n "${TRIVY_CAT_REPORT:-}" ]; then
		if [ "${TRIVY_CAT_REPORT}" != "0" ]; then
			should_cat=1
		fi
	elif [ -n "${CI:-}" ]; then
		should_cat=1
	fi
	if [ "$should_cat" -eq 1 ] && [ -f "$output" ]; then
		log_substep "Emitting Trivy report contents from $output"
		cat "$output" || true
	fi
	exit "$status"

trivy-scan-config:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	target="${TRIVY_CONFIG_TARGET:-${TRIVY_TARGET:-}}"
	if [ -z "$target" ]; then
		target="."
	fi
	if [ ! -e "$target" ]; then
		log_error "Config scan target not found: $target"
		exit 1
	fi
	severity="${TRIVY_CONFIG_SEVERITY:-${TRIVY_SEVERITY:-CRITICAL,HIGH}}"
	format="${TRIVY_CONFIG_FORMAT:-${TRIVY_FORMAT:-table}}"
	output="${TRIVY_CONFIG_OUTPUT:-${TRIVY_OUTPUT:-}}"
	exit_code="${TRIVY_CONFIG_EXIT_CODE:-${TRIVY_EXIT_CODE:-1}}"
	cmd=(trivy config --severity "$severity" --format "$format")
	if [ -n "$exit_code" ]; then
		cmd+=(--exit-code "$exit_code")
	fi
	if [ -n "$output" ]; then
		if [ "${output#/}" = "$output" ]; then
			output="$(pwd)/$output"
		fi
		mkdir -p "$(dirname "$output")"
		cmd+=(--output "$output")
	else
		slug="$(printf '%s' "$target" | tr '/:' '__')"
		output="trivy-config-${slug}.txt"
		cmd+=(--output "$output")
	fi
	if [ "${TRIVY_CONFIG_IGNORE_UNFIXED:-${TRIVY_IGNORE_UNFIXED:-}}" = "true" ]; then
		cmd+=(--ignore-unfixed)
	fi
	if [ "${TRIVY_CONFIG_SKIP_POLICY_UPDATE:-}" = "true" ]; then
		cmd+=(--skip-policy-update)
	fi
	if [ -n "${TRIVY_EXTRA_ARGS:-}" ]; then
		# shellcheck disable=SC2086
		cmd+=($TRIVY_EXTRA_ARGS)
	fi
	if [ -n "${TRIVY_CONFIG_EXTRA_ARGS:-}" ]; then
		# shellcheck disable=SC2086
		cmd+=($TRIVY_CONFIG_EXTRA_ARGS)
	fi
	log_step "Running Trivy config scan for $target"
	log_substep "Output file ${output}"
	cmd+=("$target")
	"${cmd[@]}"

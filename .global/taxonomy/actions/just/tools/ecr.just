import "../common.just"
import "./aws.just"

# Amazon Elastic Container Registry helpers.

ecr-login-check:
	#!/usr/bin/env bash
	set -euo pipefail
	registry="${ECR_REGISTRY:-${DOCKER_REGISTRY:-}}"
	if [ -z "$registry" ]; then
		exit 1
	fi
	if [[ "$registry" == */* ]]; then
		registry="${registry%%/*}"
	fi
	config_path="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
	if [ ! -f "$config_path" ]; then
		exit 1
	fi
	python3 - "$config_path" "$registry" <<-'PY'
	import json, sys

	config, host = sys.argv[1], sys.argv[2]
	try:
		with open(config, "r", encoding="utf-8") as fh:
			data = json.load(fh)
	except Exception:
		sys.exit(1)

	auths = data.get("auths") or {}
	hosts = {host, f"https://{host}"}
	for candidate in hosts:
		entry = auths.get(candidate)
		if isinstance(entry, dict):
			if entry.get("auth") or entry.get("identitytoken"):
				sys.exit(0)
	sys.exit(1)
	PY

ecr-login:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	registry="${ECR_REGISTRY:-${DOCKER_REGISTRY:-}}"
	profile="${ECR_AWS_PROFILE:-${DOCKER_AWS_PROFILE:-${AWS_PROFILE:-}}}"
	if [ -z "$registry" ]; then
		log_error "Set ECR_REGISTRY (or DOCKER_REGISTRY) with the target ECR registry URI."
		exit 1
	fi
	if [[ "$registry" == */* ]]; then
		registry="${registry%%/*}"
	fi
	if [[ ! "$registry" =~ \.dkr\.ecr\.[^.]+\.amazonaws\.com ]]; then
		log_warn "Registry $registry does not look like an ECR registry; continuing."
	fi
	if ECR_REGISTRY="$registry" just ecr-login-check >/dev/null 2>&1; then
		log_substep "Already authenticated with $registry"
		exit 0
	fi
	if [ -n "$profile" ]; then
		if ! AWS_PROFILE="$profile" just aws-login-check >/dev/null 2>&1; then
			log_warn "AWS profile $profile does not have an active SSO session; run 'AWS_PROFILE=$profile just aws-sso-login'."
		fi
	fi
	log_step "Logging into $registry via AWS CLI"
	DOCKER_REGISTRY="$registry" DOCKER_AWS_PROFILE="$profile" just docker-login

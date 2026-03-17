import "../common.just"

# AWS CLI helpers.

aws-login-check:
	#!/usr/bin/env bash
	set -euo pipefail
	profile="${AWS_PROFILE:-${AWS_SSO_PROFILE:-}}"
	if [ -z "$profile" ]; then
		exit 1
	fi
	if ! command -v aws >/dev/null 2>&1; then
		exit 1
	fi
	if aws sts get-caller-identity --profile "$profile" >/dev/null 2>&1; then
		exit 0
	fi
	exit 1

aws-sso-login:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	profile="${AWS_PROFILE:-${AWS_SSO_PROFILE:-}}"
	if [ -z "$profile" ]; then
		log_error "Set AWS_PROFILE (or AWS_SSO_PROFILE) to choose an AWS config profile."
		exit 1
	fi
	if AWS_PROFILE="$profile" just aws-login-check >/dev/null 2>&1; then
		log_substep "AWS profile $profile already has valid credentials"
		exit 0
	fi
	log_step "aws sso login --profile $profile"
	aws sso login --profile "$profile"

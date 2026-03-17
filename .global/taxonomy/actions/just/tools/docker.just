import "../common.just"

# Low-level Docker utilities intended to be composed by higher-level recipes.

docker-login:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	registry="${DOCKER_REGISTRY:-}"
	user="${DOCKER_USERNAME:-}"
	pass="${DOCKER_PASSWORD:-}"
	aws_profile="${DOCKER_AWS_PROFILE:-}"
	if [ -z "$registry" ]; then
		log_error "DOCKER_REGISTRY not set"
		exit 1
	fi
	login_host="$registry"
	if [[ "$login_host" == */* ]]; then
		login_host="${login_host%%/*}"
	fi
	if [ -z "$login_host" ]; then
		log_error "Unable to determine registry host for '$registry'"
		exit 1
	fi
	if [[ "$login_host" =~ ^([0-9]+)\.dkr\.ecr\.([^.]+)\.amazonaws\.com$ ]]; then
		region="${BASH_REMATCH[2]}"
		log_step "Logging into ECR registry $login_host (region $region)"
		aws_cmd=(aws)
		if [ -n "$aws_profile" ]; then
			aws_cmd+=(--profile "$aws_profile")
		fi
		aws_cmd+=(ecr get-login-password --region "$region")
		if ! command -v aws >/dev/null 2>/dev/null; then
			log_error "AWS CLI not found in PATH"
			exit 1
		fi
		"${aws_cmd[@]}" | docker login "$login_host" --username AWS --password-stdin
		exit 0
	fi
	if [ -z "$user" ]; then
		log_error "DOCKER_USERNAME not set"
		exit 1
	fi
	if [ -z "$pass" ]; then
		log_error "DOCKER_PASSWORD not set"
		exit 1
	fi
	log_step "Logging into $login_host as $user"
	echo "$pass" | docker login "$login_host" --username "$user" --password-stdin

docker-build-image:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	image_ref="${IMAGE_REF:-}"
	context="${DOCKER_BUILD_CONTEXT:-${DOCKER_CONTEXT:-.}}"
	dockerfile="${DOCKERFILE:-}"
	platform="${DOCKER_PLATFORM:-}"
	build_args="${BUILD_ARGS:-}"
	if [ -z "$image_ref" ]; then
		log_error "IMAGE_REF must be provided"
		exit 1
	fi
	if [ -z "$dockerfile" ]; then
		dockerfile="$context/Dockerfile"
	fi
	if [ ! -f "$dockerfile" ]; then
		log_error "Dockerfile not found: $dockerfile"
		exit 1
	fi
	if [ ! -d "$context" ]; then
		log_error "Docker context not found: $context"
		exit 1
	fi
	cmd=(docker buildx build)
	log_substep "docker binary: $(command -v docker 2>/dev/null || echo 'not found')"
	if [ -n "$platform" ]; then
		cmd+=(--platform "$platform")
	fi
	if [ -n "$build_args" ]; then
		while IFS= read -r arg; do
			[ -z "$arg" ] && continue
			cmd+=(--build-arg "$arg")
		done <<< "$build_args"
	fi
	cmd+=(--load --pull=false)
	cmd+=(-t "$image_ref" -f "$dockerfile" "$context")
	log_step "docker build ${image_ref}"
	log_substep "${cmd[*]}"
	"${cmd[@]}"

docker-tag-image:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	source_ref="${SOURCE_IMAGE:-}"
	target_ref="${TARGET_IMAGE:-}"
	if [ -z "$source_ref" ] || [ -z "$target_ref" ]; then
		log_error "SOURCE_IMAGE and TARGET_IMAGE must be provided"
		exit 1
	fi
	log_step "docker tag $source_ref -> $target_ref"
	docker tag "$source_ref" "$target_ref"

docker-push-image:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	ref="${IMAGE_REF:-}"
	if [ -z "$ref" ]; then
		log_error "IMAGE_REF must be provided"
		exit 1
	fi
	log_step "docker push $ref"
	docker push "$ref"

docker-load-image:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	ref="${IMAGE_REF:-}"
	kind_cluster="${KIND_CLUSTER:-kind}"
	if [ -z "$ref" ]; then
		log_error "IMAGE_REF must be provided"
		exit 1
	fi
	if ! command -v kind >/dev/null 2>&1; then
		log_warn "kind CLI not found; skipping load"
		exit 0
	fi
	log_step "kind load docker-image $ref --name $kind_cluster"
	kind load docker-image "$ref" --name "$kind_cluster"

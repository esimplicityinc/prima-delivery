import "../common.just"

# GitHub Container Registry helpers.

ghcr-login-check:
	#!/usr/bin/env bash
	set -euo pipefail
	host="${GHCR_REGISTRY_HOST:-ghcr.io}"
	config_path="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
	if [ ! -f "$config_path" ]; then
		exit 1
	fi
	python3 - "$config_path" "$host" <<-'PY'
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

ghcr-login:
	#!/usr/bin/env bash
	{{LOG_HELPERS}}
	set -euo pipefail
	host="${GHCR_REGISTRY_HOST:-ghcr.io}"
	if GHCR_REGISTRY_HOST="$host" just ghcr-login-check >/dev/null 2>&1; then
		log_substep "Already authenticated with $host"
		exit 0
	fi
	user="${GHCR_USERNAME:-${GHCR_USER:-${GITHUB_USER:-${GH_USERNAME:-${GH_USER:-}}}}}"
	token="${GHCR_TOKEN:-${GHCR_PAT:-${GITHUB_TOKEN:-${GH_TOKEN:-}}}}"
	if [ -z "$user" ] && [ -n "$token" ]; then
		if command -v gh >/dev/null 2>&1; then
			user="$(GH_TOKEN="$token" gh api user --jq '.login' 2>/dev/null || true)"
		fi
		if [ -z "$user" ] && command -v curl >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
			user="$(curl -fsSL -H "Authorization: Bearer $token" -H "Accept: application/vnd.github+json" https://api.github.com/user 2>/dev/null | python3 - <<'PY' 2>/dev/null
	import json, sys
	try:
	    data = json.load(sys.stdin)
	except Exception:
	    sys.exit(0)
	login = data.get("login") if isinstance(data, dict) else None
	if login:
	    print(login)
	PY
			)"
		fi
	fi
	if [ -z "$user" ]; then
		log_error "Provide GHCR_USERNAME (or GHCR_USER / GITHUB_USER) or export GHCR_TOKEN so the login can be inferred."
		exit 1
	fi
	if [ -z "$token" ]; then
		log_error "Set GHCR_TOKEN (or GHCR_PAT) to a GitHub PAT with read:packages scope."
		exit 1
	fi
	log_step "Logging into $host as $user"
	echo "$token" | docker login "$host" -u "$user" --password-stdin

import "../common.just"
import "../tools/npm.just"
import "../tools/playwright.just"
import "../tools/kubectl.just"

# BDD test layer recipes using Playwright and Cucumber/playwright-bdd.
# Provides commands for running BDD tests, generating step definitions, and reporting.

TESTS_BDD_LAYER_SETUP := '''
setup_tests_bdd_layer_context() {
  ENVIRONMENT="$(resolve_layer_env local)"
  # Prefer TESTS_LAYER_DIR over generic LAYER_DIR to avoid conflicts with other layer types
  local requested_layer="${TESTS_LAYER_DIR:-}"
  local stack_dir="${STACK_DIR:-}"
  if [ -z "$stack_dir" ] && [ -n "$requested_layer" ]; then
    stack_dir="$(cd "$(dirname "$requested_layer")" >/dev/null 2>&1 && pwd)"
  fi
  stack_dir="${stack_dir:-$PWD}"
  STACK_DIR="$stack_dir"
  local default_layer_dir="$STACK_DIR/stack-tests"
  LAYER_DIR="${requested_layer:-$default_layer_dir}"
  if [ ! -d "$LAYER_DIR" ]; then
    printf '\033[1;31mError:\033[0m tests-bdd layer directory not found: %s\n' "$LAYER_DIR" >&2
    exit 1
  fi
  LAYER_DIR="$(cd "$LAYER_DIR" >/dev/null 2>&1 && pwd)"
  STACK_NAME="${STACK_NAME:-$(basename "$STACK_DIR")}"
  LAYER_NAME="${LAYER_NAME:-$(basename "$LAYER_DIR")}"

  if [ ! -f "$LAYER_DIR/package.json" ]; then
    printf '\033[1;31mError:\033[0m package.json not found in %s\n' "$LAYER_DIR" >&2
    exit 1
  fi

  # Load environment-specific .env file
  # Priority: .env.{ENV} > .env.local > .env
  local env_file=""
  if [ -f "$LAYER_DIR/.env.$ENVIRONMENT" ]; then
    env_file="$LAYER_DIR/.env.$ENVIRONMENT"
  elif [ -f "$LAYER_DIR/.env.local" ]; then
    env_file="$LAYER_DIR/.env.local"
  elif [ -f "$LAYER_DIR/.env" ]; then
    env_file="$LAYER_DIR/.env"
  fi
  
  if [ -n "$env_file" ]; then
    log_substep "Loading env from: $(basename "$env_file")"
    set -a
    . "$env_file"
    set +a
  fi

  export NPM_WORKDIR="$LAYER_DIR"
  export PLAYWRIGHT_WORKDIR="$LAYER_DIR"
  export TESTS_WORKDIR="$LAYER_DIR"

  # Test configuration
  TESTS_TIMEOUT="${TESTS_TIMEOUT:-60000}"
  TESTS_WORKERS="${TESTS_WORKERS:-1}"
  TESTS_RETRIES="${TESTS_RETRIES:-0}"

  log_substep "tests-bdd layer: $LAYER_DIR"
  log_substep "tests-bdd environment: $ENVIRONMENT"
}

ensure_features_dir() {
  if [ ! -d "$LAYER_DIR/features" ]; then
    printf '\033[1;31mError:\033[0m features directory not found in %s\n' "$LAYER_DIR" >&2
    exit 1
  fi
}
'''

# Installation commands
tests-bdd-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	log_step "Installing BDD test dependencies"
	just npm-install

tests-bdd-install-ci:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	log_step "Installing BDD test dependencies (CI mode)"
	just npm-install-ci

tests-bdd-install-browsers:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	log_step "Installing Playwright browsers"
	just playwright-install-browsers

# BDD generation commands
tests-bdd-gen:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	ensure_features_dir
	log_step "Generating BDD test files from feature files"
	(cd "$LAYER_DIR" && npm run gen)

tests-bdd-clean-gen:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	log_step "Cleaning generated BDD files"
	(cd "$LAYER_DIR" && rm -rf .features-gen)

# Test execution commands
tests-bdd-run:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	ensure_features_dir
	log_step "Running all BDD tests"
	(cd "$LAYER_DIR" && npm test)

tests-bdd-run-api:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	ensure_features_dir
	log_step "Running API BDD tests"
	(cd "$LAYER_DIR" && npm run test:api)

tests-bdd-run-hybrid:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	ensure_features_dir
	log_step "Running hybrid BDD tests"
	(cd "$LAYER_DIR" && npm run test:hybrid)

tests-bdd-run-smoke:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	ensure_features_dir
	log_step "Running smoke BDD tests"
	(cd "$LAYER_DIR" && npm run test:smoke)

tests-bdd-run-headed:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	ensure_features_dir
	log_step "Running BDD tests in headed mode"
	(cd "$LAYER_DIR" && npm run test:headed 2>/dev/null || npx playwright test --headed)

tests-bdd-run-debug:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	ensure_features_dir
	log_step "Running BDD tests in debug mode"
	just playwright-test-debug

tests-bdd-run-ui:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	ensure_features_dir
	log_step "Running BDD tests with Playwright UI mode"
	just playwright-test-ui

tests-bdd-run-tag tag:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	ensure_features_dir
	log_step "Running BDD tests with tag: {{tag}}"
	(cd "$LAYER_DIR" && npm run gen && npx playwright test --grep "{{tag}}")

tests-bdd-run-project project:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	ensure_features_dir
	log_step "Running BDD tests for project: {{project}}"
	(cd "$LAYER_DIR" && npm run gen && npx playwright test --project={{project}})

# Reporting commands
tests-bdd-report:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	log_step "Opening BDD test report"
	just playwright-show-report

tests-bdd-trace file:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	log_step "Opening trace file: {{file}}"
	just playwright-trace "{{file}}"

# Utility commands
tests-bdd-clean:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	log_step "Cleaning BDD test artifacts"
	(cd "$LAYER_DIR" && rm -rf .features-gen test-results playwright-report storage cucumber-report node_modules)

tests-bdd-codegen url="":
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	log_step "Starting Playwright code generator"
	just playwright-codegen "{{url}}"

# CI/CD pipeline commands
tests-bdd-ci:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	ensure_features_dir
	log_step "Running BDD CI pipeline"
	log_substep "Installing dependencies"
	just npm-install-ci
	log_substep "Installing browsers"
	just playwright-install-browsers
	log_substep "Generating test files"
	(cd "$LAYER_DIR" && npm run gen)
	log_substep "Running tests"
	(cd "$LAYER_DIR" && npx playwright test --workers="${TESTS_WORKERS}" --retries="${TESTS_RETRIES}")
	log_step "BDD CI pipeline complete"

tests-bdd-ci-api:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	ensure_features_dir
	log_step "Running BDD CI pipeline (API tests only)"
	log_substep "Installing dependencies"
	just npm-install-ci
	log_substep "Running API tests"
	(cd "$LAYER_DIR" && npm run test:api)
	log_step "BDD CI pipeline complete"

# Cluster-access test execution with automatic kubectl port-forward
# Requires: TESTS_BDD_SERVICE, TESTS_BDD_NAMESPACE, TESTS_BDD_LOCAL_PORT, TESTS_BDD_REMOTE_PORT
tests-bdd-run-cluster:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{LAYER_ENV_HELPERS}}
	{{TESTS_BDD_LAYER_SETUP}}
	{{KUBECTL_HELPERS}}
	set -euo pipefail
	setup_tests_bdd_layer_context
	setup_kubectl_context
	ensure_features_dir
	ensure_kubectl
	
	# Configuration with sensible defaults
	SERVICE="${TESTS_BDD_SERVICE:-$STACK_NAME}"
	NAMESPACE="${TESTS_BDD_NAMESPACE:-$K8S_NAMESPACE}"
	LOCAL_PORT="${TESTS_BDD_LOCAL_PORT:-8080}"
	REMOTE_PORT="${TESTS_BDD_REMOTE_PORT:-$LOCAL_PORT}"
	
	log_step "Starting cluster-access tests for $SERVICE"
	log_substep "Target: svc/$SERVICE in namespace $NAMESPACE"
	log_substep "Port mapping: localhost:$LOCAL_PORT -> $REMOTE_PORT"
	
	# Start port-forward in background
	KUBECTL_BIN="${KUBECTL:-kubectl}"
	"$KUBECTL_BIN" port-forward "svc/$SERVICE" "$LOCAL_PORT:$REMOTE_PORT" -n "$NAMESPACE" &
	PF_PID=$!
	
	# Cleanup on exit (success or failure)
	cleanup() {
	  if kill -0 $PF_PID 2>/dev/null; then
	    log_substep "Stopping port-forward (PID: $PF_PID)"
	    kill $PF_PID 2>/dev/null || true
	    wait $PF_PID 2>/dev/null || true
	  fi
	}
	trap cleanup EXIT INT TERM
	
	# Wait for port-forward to establish
	log_substep "Waiting for port-forward..."
	sleep 2
	
	# Verify port is listening (portable: Mac + WSL2 + Linux)
	MAX_RETRIES=5
	RETRY=0
	while [ $RETRY -lt $MAX_RETRIES ]; do
	  if timeout 1 bash -c "cat < /dev/null > /dev/tcp/localhost/$LOCAL_PORT" 2>/dev/null; then
	    log_substep "Port $LOCAL_PORT is ready"
	    break
	  fi
	  RETRY=$((RETRY + 1))
	  if [ $RETRY -eq $MAX_RETRIES ]; then
	    log_error "Port-forward failed - localhost:$LOCAL_PORT not responding after $MAX_RETRIES attempts"
	    exit 1
	  fi
	  log_substep "Waiting for port... (attempt $RETRY/$MAX_RETRIES)"
	  sleep 1
	done
	
	# Run tests with cluster access enabled
	log_step "Running BDD tests with CLUSTER_ACCESS=true"
	(cd "$LAYER_DIR" && CLUSTER_ACCESS=true npm test)
	
	log_step "Cluster-access tests complete"

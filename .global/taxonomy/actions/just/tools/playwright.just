import "../common.just"

# Low-level Playwright utilities intended to be composed by higher-level recipes.

PLAYWRIGHT_TOOL_HELPERS := '''
setup_playwright_context() {
  PLAYWRIGHT_DIR="${PLAYWRIGHT_WORKDIR:-$(pwd)}"
  if [ ! -d "$PLAYWRIGHT_DIR" ]; then
    log_error "Playwright project directory not found: $PLAYWRIGHT_DIR"
    exit 1
  fi
  log_substep "playwright working dir requested: $PLAYWRIGHT_DIR"
  PLAYWRIGHT_DIR="$(cd "$PLAYWRIGHT_DIR" && pwd)"
  log_substep "playwright working dir resolved: $PLAYWRIGHT_DIR"
  export PLAYWRIGHT_WORKDIR="$PLAYWRIGHT_DIR"
}

ensure_playwright() {
  if [ ! -f "$PLAYWRIGHT_WORKDIR/node_modules/.bin/playwright" ]; then
    log_error "Playwright not found in node_modules. Run npm install first."
    exit 1
  fi
}

ensure_playwright_config() {
  if [ ! -f "$PLAYWRIGHT_WORKDIR/playwright.config.ts" ] && [ ! -f "$PLAYWRIGHT_WORKDIR/playwright.config.js" ]; then
    log_error "playwright.config.ts/js not found in $PLAYWRIGHT_WORKDIR"
    exit 1
  fi
}
'''

playwright-version:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{PLAYWRIGHT_TOOL_HELPERS}}
	set -euo pipefail
	setup_playwright_context
	ensure_playwright
	log_substep "playwright: $(cd "$PLAYWRIGHT_WORKDIR" && npx playwright --version)"

playwright-install-browsers:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{PLAYWRIGHT_TOOL_HELPERS}}
	set -euo pipefail
	setup_playwright_context
	ensure_playwright
	log_step "Installing Playwright browsers"
	(cd "$PLAYWRIGHT_WORKDIR" && npx playwright install)

playwright-install-deps:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{PLAYWRIGHT_TOOL_HELPERS}}
	set -euo pipefail
	setup_playwright_context
	ensure_playwright
	log_step "Installing Playwright system dependencies"
	(cd "$PLAYWRIGHT_WORKDIR" && npx playwright install-deps)

playwright-test *args:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{PLAYWRIGHT_TOOL_HELPERS}}
	set -euo pipefail
	setup_playwright_context
	ensure_playwright
	ensure_playwright_config
	log_step "Running Playwright tests"
	(cd "$PLAYWRIGHT_WORKDIR" && npx playwright test {{args}})

playwright-test-ui:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{PLAYWRIGHT_TOOL_HELPERS}}
	set -euo pipefail
	setup_playwright_context
	ensure_playwright
	ensure_playwright_config
	log_step "Running Playwright tests with UI mode"
	(cd "$PLAYWRIGHT_WORKDIR" && npx playwright test --ui)

playwright-test-headed *args:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{PLAYWRIGHT_TOOL_HELPERS}}
	set -euo pipefail
	setup_playwright_context
	ensure_playwright
	ensure_playwright_config
	log_step "Running Playwright tests in headed mode"
	(cd "$PLAYWRIGHT_WORKDIR" && npx playwright test --headed {{args}})

playwright-test-debug *args:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{PLAYWRIGHT_TOOL_HELPERS}}
	set -euo pipefail
	setup_playwright_context
	ensure_playwright
	ensure_playwright_config
	log_step "Running Playwright tests in debug mode"
	(cd "$PLAYWRIGHT_WORKDIR" && npx playwright test --debug {{args}})

playwright-test-project project *args:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{PLAYWRIGHT_TOOL_HELPERS}}
	set -euo pipefail
	setup_playwright_context
	ensure_playwright
	ensure_playwright_config
	log_step "Running Playwright tests for project: {{project}}"
	(cd "$PLAYWRIGHT_WORKDIR" && npx playwright test --project={{project}} {{args}})

playwright-test-grep pattern *args:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{PLAYWRIGHT_TOOL_HELPERS}}
	set -euo pipefail
	setup_playwright_context
	ensure_playwright
	ensure_playwright_config
	log_step "Running Playwright tests matching: {{pattern}}"
	(cd "$PLAYWRIGHT_WORKDIR" && npx playwright test --grep "{{pattern}}" {{args}})

playwright-show-report:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{PLAYWRIGHT_TOOL_HELPERS}}
	set -euo pipefail
	setup_playwright_context
	ensure_playwright
	log_step "Opening Playwright test report"
	(cd "$PLAYWRIGHT_WORKDIR" && npx playwright show-report)

playwright-codegen url="":
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{PLAYWRIGHT_TOOL_HELPERS}}
	set -euo pipefail
	setup_playwright_context
	ensure_playwright
	log_step "Starting Playwright code generator"
	if [ -n "{{url}}" ]; then
	  (cd "$PLAYWRIGHT_WORKDIR" && npx playwright codegen "{{url}}")
	else
	  (cd "$PLAYWRIGHT_WORKDIR" && npx playwright codegen)
	fi

playwright-trace file:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{PLAYWRIGHT_TOOL_HELPERS}}
	set -euo pipefail
	setup_playwright_context
	ensure_playwright
	log_step "Opening Playwright trace viewer"
	(cd "$PLAYWRIGHT_WORKDIR" && npx playwright show-trace "{{file}}")

playwright-clean:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{PLAYWRIGHT_TOOL_HELPERS}}
	set -euo pipefail
	setup_playwright_context
	log_step "Cleaning Playwright artifacts"
	(cd "$PLAYWRIGHT_WORKDIR" && rm -rf test-results playwright-report .features-gen storage)

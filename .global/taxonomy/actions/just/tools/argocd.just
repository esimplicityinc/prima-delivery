import "../common.just"

ARGOCD_TOOL_HELPERS := '''
argocd_bin() {
  echo "${ARGOCD_BIN:-argocd}"
}

check_argocd_installed() {
  command -v "$(argocd_bin)" >/dev/null 2>&1
}

has_homebrew() {
  command -v brew >/dev/null 2>&1
}

install_argocd_with_brew() {
  if ! has_homebrew; then
    return 1
  fi
  if brew list argocd >/dev/null 2>&1; then
    log_substep "argocd already installed via Homebrew"
    return 0
  fi
  log_substep "Installing argocd via Homebrew"
  if brew install argocd; then
    return 0
  fi
  return 1
}

download_argocd_release() {
  local version url os arch tmp_dir archive dest_bin
  version="${ARGOCD_VERSION:-v2.11.0}"
  case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *)
      log_error "Unsupported OS for argocd: $(uname -s)"
      exit 1
      ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)
      log_error "Unsupported architecture for argocd: $(uname -m)"
      exit 1
      ;;
  esac
  url="https://github.com/argoproj/argo-cd/releases/download/${version}/argocd-${os}-${arch}"
  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/argocd"
  log_substep "Downloading argocd CLI (${url})"
  if ! curl -fsSL "$url" -o "$archive"; then
    log_error "Failed to download argocd CLI from ${url}"
    exit 1
  fi
  chmod +x "$archive"
  dest_bin="${TOOL_INSTALL_DIR:-/usr/local/bin}/argocd"
  install_argocd_binary "$archive" "$dest_bin"
  rm -rf "$tmp_dir"
  log_substep "Installed argocd to ${dest_bin}"
}

install_argocd_binary() {
  local src="$1"
  local dest="$2"
  local dir
  dir="$(dirname "$dest")"
  if [ ! -d "$dir" ]; then
    if ! mkdir -p "$dir" 2>/dev/null; then
      if command -v sudo >/dev/null 2>&1; then
        sudo mkdir -p "$dir"
      else
        mkdir -p "$dir"
      fi
    fi
  fi
  if [ -w "$dir" ]; then
    install -m 0755 "$src" "$dest"
  else
    if command -v sudo >/dev/null 2>&1; then
      sudo install -m 0755 "$src" "$dest"
    else
      install -m 0755 "$src" "$dest"
    fi
  fi
}
'''

argocd-verify-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{ARGOCD_TOOL_HELPERS}}
	set -euo pipefail
	if ! check_argocd_installed; then
	  log_error "argocd CLI not found in PATH"
	  exit 1
	fi
	ARGOCD_BIN_PATH="$(argocd_bin)"
	if ! version_out="$("$ARGOCD_BIN_PATH" version --client 2>/dev/null)"; then
	  log_error "argocd detected but failed to run 'argocd version --client'"
	  exit 1
	fi
	log_step "argocd installation verified: ${version_out}"

argocd-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{ARGOCD_TOOL_HELPERS}}
	set -euo pipefail
	if check_argocd_installed; then
	  ARGOCD_BIN_PATH="$(argocd_bin)"
	  if version_out="$("$ARGOCD_BIN_PATH" version --client 2>/dev/null)"; then
	    log_step "argocd already installed: ${version_out}"
	  else
	    log_step "argocd already installed"
	  fi
	  exit 0
	fi
	log_step "Installing argocd CLI"
	if install_argocd_with_brew; then
	  exit 0
	fi
	log_substep "Homebrew not available or failed; falling back to GitHub release"
	download_argocd_release

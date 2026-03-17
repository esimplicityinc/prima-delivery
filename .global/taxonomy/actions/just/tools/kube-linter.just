import "../common.just"

KUBE_LINTER_TOOL_HELPERS := '''
has_homebrew() {
  command -v brew >/dev/null 2>&1
}

install_kubelinter_with_brew() {
  if ! has_homebrew; then
    return 1
  fi
  local formula="${KUBE_LINTER_BREW_FORMULA:-kube-linter}"
  if brew list "$formula" >/dev/null 2>&1; then
    log_substep "${formula} already installed via Homebrew"
    return 0
  fi
  log_substep "Installing ${formula} via Homebrew"
  if brew install "$formula"; then
    return 0
  fi
  return 1
}

kubelinter_bin() {
  echo "${KUBE_LINTER_BIN:-kube-linter}"
}

check_kubelinter_installed() {
  command -v "$(kubelinter_bin)" >/dev/null 2>&1
}

kubelinter_detect_platform() {
  local os arch
  case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *)
      log_error "Unsupported OS for kube-linter: $(uname -s)"
      exit 1
      ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)
      log_error "Unsupported architecture for kube-linter: $(uname -m)"
      exit 1
      ;;
  esac
  printf '%s %s\n' "$os" "$arch"
}

ensure_install_parent() {
  local dir="$1"
  if [ -d "$dir" ]; then
    return 0
  fi
  if mkdir -p "$dir" 2>/dev/null; then
    return 0
  fi
  if command -v sudo >/dev/null 2>&1; then
    sudo mkdir -p "$dir"
  else
    mkdir -p "$dir"
  fi
}

install_binary_with_permissions() {
  local src="$1"
  local dest="$2"
  local dir
  dir="$(dirname "$dest")"
  ensure_install_parent "$dir"
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

kubelinter_install_release() {
  local os arch suffix version asset url tmp_dir archive install_dir dest
  read -r os arch <<<"$(kubelinter_detect_platform)"
  if [ "$arch" = "arm64" ]; then
    suffix="${os}_arm64"
  else
    suffix="${os}"
  fi
  version="${KUBE_LINTER_VERSION:-v0.7.6}"
  asset="kube-linter-${suffix}.tar.gz"
  url="https://github.com/stackrox/kube-linter/releases/download/${version}/${asset}"
  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/${asset}"
  log_substep "Downloading ${asset} (${url})"
  if ! curl -fsSL "$url" -o "$archive"; then
    log_error "Failed to download kube-linter release from ${url}"
    exit 1
  fi
  log_substep "Extracting kube-linter archive"
  if ! tar -xzf "$archive" -C "$tmp_dir"; then
    log_error "Failed to extract ${archive}"
    exit 1
  fi
  install_dir="${TOOL_INSTALL_DIR:-/usr/local/bin}"
  dest="${install_dir}/kube-linter"
  install_binary_with_permissions "$tmp_dir/kube-linter" "$dest"
  rm -rf "$tmp_dir"
  log_substep "Installed kube-linter to ${dest}"
}
'''

kube-linter-verify-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{KUBE_LINTER_TOOL_HELPERS}}
	set -euo pipefail
	if ! check_kubelinter_installed; then
	  log_error "kube-linter binary not found in PATH"
	  exit 1
	fi
	KUBE_LINTER_BIN_PATH="$(kubelinter_bin)"
	if ! version_out="$("$KUBE_LINTER_BIN_PATH" version 2>/dev/null)"; then
	  log_error "kube-linter detected but failed to run 'version'"
	  exit 1
	fi
	log_step "kube-linter installation verified: ${version_out}"

kube-linter-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{KUBE_LINTER_TOOL_HELPERS}}
	set -euo pipefail
	if check_kubelinter_installed; then
	  KUBE_LINTER_BIN_PATH="$(kubelinter_bin)"
	  if version_out="$("$KUBE_LINTER_BIN_PATH" version 2>/dev/null)"; then
	    log_step "kube-linter already installed: ${version_out}"
	  else
	    log_step "kube-linter already installed"
	  fi
	  exit 0
	fi
	log_step "Installing kube-linter"
	if install_kubelinter_with_brew; then
	  exit 0
	fi
	log_substep "Homebrew not available or failed; falling back to release archive"
	kubelinter_install_release

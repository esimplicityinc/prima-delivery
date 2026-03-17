import "../common.just"

KUBECONFORM_TOOL_HELPERS := '''
has_homebrew() {
  command -v brew >/dev/null 2>&1
}

install_kubeconform_with_brew() {
  if ! has_homebrew; then
    return 1
  fi
  local formula="${KUBECONFORM_BREW_FORMULA:-kubeconform}"
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

kubeconform_bin() {
  echo "${KUBECONFORM_BIN:-kubeconform}"
}

check_kubeconform_installed() {
  command -v "$(kubeconform_bin)" >/dev/null 2>&1
}

kubeconform_detect_platform() {
  local os arch
  case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *)
      log_error "Unsupported OS for kubeconform: $(uname -s)"
      exit 1
      ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)
      log_error "Unsupported architecture for kubeconform: $(uname -m)"
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

kubeconform_install_release() {
  local os arch version asset url tmp_dir install_dir dest archive
  read -r os arch <<<"$(kubeconform_detect_platform)"
  version="${KUBECONFORM_VERSION:-v0.7.0}"
  asset="kubeconform-${os}-${arch}.tar.gz"
  url="https://github.com/yannh/kubeconform/releases/download/${version}/${asset}"
  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/${asset}"
  log_substep "Downloading ${asset} (${url})"
  if ! curl -fsSL "$url" -o "$archive"; then
    log_error "Failed to download kubeconform release from ${url}"
    exit 1
  fi
  log_substep "Extracting kubeconform archive"
  if ! tar -xzf "$archive" -C "$tmp_dir"; then
    log_error "Failed to extract ${archive}"
    exit 1
  fi
  install_dir="${TOOL_INSTALL_DIR:-/usr/local/bin}"
  dest="${install_dir}/kubeconform"
  install_binary_with_permissions "$tmp_dir/kubeconform" "$dest"
  rm -rf "$tmp_dir"
  log_substep "Installed kubeconform to ${dest}"
}
'''

kubeconform-verify-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{KUBECONFORM_TOOL_HELPERS}}
	set -euo pipefail
	if ! check_kubeconform_installed; then
	  log_error "kubeconform binary not found in PATH"
	  exit 1
	fi
	KUBECONFORM_BIN_PATH="$(kubeconform_bin)"
	if ! version_out="$("$KUBECONFORM_BIN_PATH" -v 2>/dev/null)"; then
	  log_error "kubeconform detected but failed to run '-v'"
	  exit 1
	fi
	log_step "kubeconform installation verified: ${version_out}"

kubeconform-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{KUBECONFORM_TOOL_HELPERS}}
	set -euo pipefail
	if check_kubeconform_installed; then
	  KUBECONFORM_BIN_PATH="$(kubeconform_bin)"
	  if version_out="$("$KUBECONFORM_BIN_PATH" -v 2>/dev/null)"; then
	    log_step "kubeconform already installed: ${version_out}"
	  else
	    log_step "kubeconform already installed"
	  fi
	  exit 0
	fi
	log_step "Installing kubeconform"
	if install_kubeconform_with_brew; then
	  exit 0
	fi
	log_substep "Homebrew not available or failed; falling back to release archive"
	kubeconform_install_release

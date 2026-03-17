import "../common.just"

KUBESEC_TOOL_HELPERS := '''
has_homebrew() {
  command -v brew >/dev/null 2>&1
}

install_kubesec_with_brew() {
  if ! has_homebrew; then
    return 1
  fi
  local formula="${KUBESEC_BREW_FORMULA:-kubesec}"
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

kubesec_bin() {
  echo "${KUBESEC_BIN:-kubesec}"
}

check_kubesec_installed() {
  command -v "$(kubesec_bin)" >/dev/null 2>&1
}

kubesec_detect_platform() {
  local os arch
  case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *)
      log_error "Unsupported OS for kubesec: $(uname -s)"
      exit 1
      ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)
      log_error "Unsupported architecture for kubesec: $(uname -m)"
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

kubesec_install_release() {
  local os arch version asset url tmp_dir archive install_dir dest
  read -r os arch <<<"$(kubesec_detect_platform)"
  version="${KUBESEC_VERSION:-v2.14.2}"
  asset="kubesec_${os}_${arch}.tar.gz"
  url="https://github.com/controlplaneio/kubesec/releases/download/${version}/${asset}"
  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/${asset}"
  log_substep "Downloading ${asset} (${url})"
  if ! curl -fsSL "$url" -o "$archive"; then
    log_error "Failed to download kubesec release from ${url}"
    exit 1
  fi
  log_substep "Extracting kubesec archive"
  if ! tar -xzf "$archive" -C "$tmp_dir"; then
    log_error "Failed to extract ${archive}"
    exit 1
  fi
  install_dir="${TOOL_INSTALL_DIR:-/usr/local/bin}"
  dest="${install_dir}/kubesec"
  install_binary_with_permissions "$tmp_dir/kubesec" "$dest"
  rm -rf "$tmp_dir"
  log_substep "Installed kubesec to ${dest}"
}
'''

kubesec-verify-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{KUBESEC_TOOL_HELPERS}}
	set -euo pipefail
	if ! check_kubesec_installed; then
	  log_error "kubesec binary not found in PATH"
	  exit 1
	fi
	KUBESEC_BIN_PATH="$(kubesec_bin)"
	if ! version_out="$("$KUBESEC_BIN_PATH" version 2>/dev/null)"; then
	  log_error "kubesec detected but failed to run 'version'"
	  exit 1
	fi
	log_step "kubesec installation verified: ${version_out}"

kubesec-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{KUBESEC_TOOL_HELPERS}}
	set -euo pipefail
	if check_kubesec_installed; then
	  KUBESEC_BIN_PATH="$(kubesec_bin)"
	  if version_out="$("$KUBESEC_BIN_PATH" version 2>/dev/null)"; then
	    log_step "kubesec already installed: ${version_out}"
	  else
	    log_step "kubesec already installed"
	  fi
	  exit 0
	fi
	log_step "Installing kubesec"
	if install_kubesec_with_brew; then
	  exit 0
	fi
	log_substep "Homebrew not available or failed; falling back to release archive"
	kubesec_install_release

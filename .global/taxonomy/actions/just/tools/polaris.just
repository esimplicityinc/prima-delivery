import "../common.just"

POLARIS_TOOL_HELPERS := '''
has_homebrew() {
  command -v brew >/dev/null 2>&1
}

install_polaris_with_brew() {
  if ! has_homebrew; then
    return 1
  fi
  local formula="${POLARIS_BREW_FORMULA:-fairwinds/tap/polaris}"
  if brew list "${formula##*/}" >/dev/null 2>&1; then
    log_substep "${formula##*/} already installed via Homebrew"
    return 0
  fi
  log_substep "Installing ${formula} via Homebrew"
  if brew install "$formula"; then
    return 0
  fi
  return 1
}

polaris_bin() {
  echo "${POLARIS_BIN:-polaris}"
}

check_polaris_installed() {
  command -v "$(polaris_bin)" >/dev/null 2>&1
}

polaris_detect_platform() {
  local os arch
  case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *)
      log_error "Unsupported OS for polaris: $(uname -s)"
      exit 1
      ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)
      log_error "Unsupported architecture for polaris: $(uname -m)"
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

polaris_install_release() {
  local os arch version asset url tmp_dir archive install_dir dest
  read -r os arch <<<"$(polaris_detect_platform)"
  version="${POLARIS_VERSION:-10.1.2}"
  asset="polaris_${os}_${arch}.tar.gz"
  url="https://github.com/FairwindsOps/polaris/releases/download/${version}/${asset}"
  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/${asset}"
  log_substep "Downloading ${asset} (${url})"
  if ! curl -fsSL "$url" -o "$archive"; then
    log_error "Failed to download polaris release from ${url}"
    exit 1
  fi
  log_substep "Extracting polaris archive"
  if ! tar -xzf "$archive" -C "$tmp_dir"; then
    log_error "Failed to extract ${archive}"
    exit 1
  fi
  install_dir="${TOOL_INSTALL_DIR:-/usr/local/bin}"
  dest="${install_dir}/polaris"
  install_binary_with_permissions "$tmp_dir/polaris" "$dest"
  rm -rf "$tmp_dir"
  log_substep "Installed polaris to ${dest}"
}
'''

polaris-verify-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{POLARIS_TOOL_HELPERS}}
	set -euo pipefail
	if ! check_polaris_installed; then
	  log_error "polaris binary not found in PATH"
	  exit 1
	fi
	POLARIS_BIN_PATH="$(polaris_bin)"
	if ! version_out="$("$POLARIS_BIN_PATH" version 2>/dev/null)"; then
	  log_error "polaris detected but failed to run 'version'"
	  exit 1
	fi
	log_step "polaris installation verified: ${version_out}"

polaris-install:
	#!/usr/bin/env bash
	{{ENV_HELPERS}}
	{{LOG_HELPERS}}
	{{POLARIS_TOOL_HELPERS}}
	set -euo pipefail
	if check_polaris_installed; then
	  POLARIS_BIN_PATH="$(polaris_bin)"
	  if version_out="$("$POLARIS_BIN_PATH" version 2>/dev/null)"; then
	    log_step "polaris already installed: ${version_out}"
	  else
	    log_step "polaris already installed"
	  fi
	  exit 0
	fi
	log_step "Installing polaris"
	if install_polaris_with_brew; then
	  exit 0
	fi
	log_substep "Homebrew not available or failed; falling back to release archive"
	polaris_install_release

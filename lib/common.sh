#!/usr/bin/env bash
# Shared helpers for dotfiles installation modules.

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log_info() {
  echo "[INFO] $*"
}

log_warn() {
  echo "[WARN] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    log_error "This script must be run as root."
    exit 1
  fi
}

require_debian() {
  if [[ ! -f /etc/os-release ]]; then
    log_error "Cannot detect OS: /etc/os-release not found."
    exit 1
  fi

  # shellcheck source=/dev/null
  source /etc/os-release

  if [[ "${ID:-}" != "debian" ]]; then
    log_error "This installer targets Debian only (detected: ${ID:-unknown})."
    exit 1
  fi
}

debian_codename() {
  # shellcheck source=/dev/null
  source /etc/os-release
  echo "${VERSION_CODENAME:?Debian codename not found in /etc/os-release}"
}

backup_file() {
  local file="$1"

  if [[ -f "$file" ]]; then
    cp -a "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"
    log_info "Backup created for ${file}"
  fi
}

dotfiles_target_user() {
  echo "${DOTFILES_USER:-${SUDO_USER:-$USER}}"
}

dotfiles_target_home() {
  local user home

  user="$(dotfiles_target_user)"
  home="$(getent passwd "$user" | cut -d: -f6)"

  if [[ -z "$home" ]]; then
    log_error "Cannot resolve home directory for user: ${user}"
    exit 1
  fi

  echo "$home"
}

deploy_user_file() {
  local src="$1"
  local rel="$2"
  local user group home dest mode="${3:-644}"

  user="$(dotfiles_target_user)"
  group="$(id -gn "$user" 2>/dev/null || echo "$user")"
  home="$(dotfiles_target_home)"
  dest="${home}/${rel}"

  if [[ "$user" == root ]]; then
    log_error "Refusing to deploy config for root. Run with sudo as a regular user or set DOTFILES_USER."
    exit 1
  fi

  if [[ ! -f "$src" ]]; then
    log_error "Source file not found: ${src}"
    exit 1
  fi

  backup_file "$dest"
  install -D -o "$user" -g "$group" -m "$mode" "$src" "$dest"
  log_info "Deployed ${rel} for user ${user}"
}

deploy_system_file() {
  local src="$1"
  local dest="$2"
  local mode="${3:-644}"

  if [[ ! -f "$src" ]]; then
    log_error "Source file not found: ${src}"
    exit 1
  fi

  backup_file "$dest"
  install -D -m "$mode" "$src" "$dest"
  log_info "Installed ${dest}"
}

install_user_fonts() {
  local user group home src dest

  user="$(dotfiles_target_user)"
  group="$(id -gn "$user" 2>/dev/null || echo "$user")"
  home="$(dotfiles_target_home)"
  src="${DOTFILES_ROOT}/fonts"
  dest="${home}/.local/share/fonts"

  if [[ "$user" == root ]]; then
    log_error "Refusing to install fonts for root. Run with sudo as a regular user or set DOTFILES_USER."
    exit 1
  fi

  if [[ ! -d "$src" ]]; then
    log_error "Fonts directory not found: ${src}"
    exit 1
  fi

  install -d -o "$user" -g "$group" -m 755 "$dest"
  cp -a "${src}/." "$dest/"
  chown -R "${user}:${group}" "$dest"

  log_info "Installed fonts from ${src}"
  sudo -u "$user" fc-cache -f
  log_info "Refreshed font cache for user ${user}"
}

run_as_target_user() {
  local user home

  user="$(dotfiles_target_user)"
  home="$(dotfiles_target_home)"

  if [[ "$user" == root ]]; then
    log_error "Refusing to run user commands as root. Run with sudo as a regular user or set DOTFILES_USER."
    exit 1
  fi

  sudo -u "$user" env HOME="$home" "$@"
}

deploy_user_tree() {
  local src="$1"
  local rel="$2"
  local user group home dest

  user="$(dotfiles_target_user)"
  group="$(id -gn "$user" 2>/dev/null || echo "$user")"
  home="$(dotfiles_target_home)"
  dest="${home}/${rel}"

  if [[ "$user" == root ]]; then
    log_error "Refusing to deploy config for root. Run with sudo as a regular user or set DOTFILES_USER."
    exit 1
  fi

  if [[ ! -d "$src" ]]; then
    log_error "Source directory not found: ${src}"
    exit 1
  fi

  if [[ -d "$dest" ]]; then
    mv "$dest" "${dest}.bak.$(date +%Y%m%d%H%M%S)"
    log_info "Backup created for ${dest}"
  fi

  install -d -o "$user" -g "$group" -m 755 "$(dirname "$dest")"
  cp -a "$src" "$dest"
  chown -R "${user}:${group}" "$dest"
  log_info "Deployed ${rel}/ for user ${user}"
}

resolve_module_script() {
  local module="$1"
  local candidate

  for candidate in \
    "${DOTFILES_ROOT}/modules/common/${module}/install.sh" \
    "${DOTFILES_ROOT}/modules/x11/${module}/install.sh" \
    "${DOTFILES_ROOT}/modules/wayland/${module}/install.sh" \
    "${DOTFILES_ROOT}/modules/${module}/install.sh"; do
    if [[ -f "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

run_module() {
  local module="$1"
  local module_script

  if ! module_script="$(resolve_module_script "$module")"; then
    log_error "Module not found: ${module}"
    exit 1
  fi

  log_info "Running module: ${module}"
  # shellcheck source=/dev/null
  source "$module_script"
}

# shellcheck source=lib/verify.sh
source "${DOTFILES_ROOT}/lib/verify.sh"

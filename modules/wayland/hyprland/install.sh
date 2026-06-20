#!/usr/bin/env bash
# Install Hyprland and deploy Wayland compositor configuration.
# https://wiki.hypr.land/Getting-Started/Installation/

hyprland_package_available() {
  local codename="$1"
  local pocket="$2"

  if [[ -n "$pocket" ]]; then
    apt-cache show -t "${codename}-${pocket}" hyprland >/dev/null 2>&1
  else
    apt-cache show hyprland >/dev/null 2>&1
  fi
}

hyprland_enable_backports() {
  local codename="$1"
  local src dest

  dest="/etc/apt/sources.list.d/dotfiles-${codename}-backports.list"
  src="${DOTFILES_ROOT}/config/common/apt/trixie-backports.list"

  if [[ -f "$dest" ]]; then
    log_info "Backports source already present: ${dest}"
    return
  fi

  if [[ "$codename" != "trixie" || ! -f "$src" ]]; then
    return 1
  fi

  log_info "Enabling ${codename}-backports for Hyprland..."
  deploy_system_file "$src" "$dest"
  apt-get update
}

hyprland_install_from_apt() {
  local codename="$1"

  log_info "Updating package lists..."
  apt-get update

  apt-get install -y jq socat

  case "$codename" in
    bookworm|bullseye)
      log_error "Hyprland is not available on Debian ${codename}."
      log_error "Use Debian 13 (Trixie) with backports, or Debian 14 (Forky) or newer."
      log_error "See: https://wiki.hypr.land/Getting-Started/Installation/"
      exit 1
      ;;
    trixie)
      if hyprland_package_available "$codename" backports; then
        log_info "Installing Hyprland from trixie-backports..."
        apt-get install -y -t trixie-backports hyprland
        return
      fi

      if hyprland_package_available "$codename" ""; then
        log_info "Installing Hyprland..."
        apt-get install -y hyprland
        return
      fi

      if hyprland_enable_backports "$codename" && hyprland_package_available "$codename" backports; then
        log_info "Installing Hyprland from trixie-backports..."
        apt-get install -y -t trixie-backports hyprland
        return
      fi

      log_error "Hyprland is not available. On Trixie it requires backports."
      log_error "Add manually:"
      log_error "  deb http://deb.debian.org/debian trixie-backports main"
      log_error "Then run: sudo apt update && sudo apt install -t trixie-backports hyprland"
      log_error "See: https://wiki.hypr.land/Getting-Started/Installation/"
      exit 1
      ;;
    forky|sid|*)
      if hyprland_package_available "$codename" ""; then
        log_info "Installing Hyprland..."
        apt-get install -y hyprland
      elif hyprland_package_available "$codename" backports; then
        log_info "Installing Hyprland from ${codename}-backports..."
        apt-get install -y -t "${codename}-backports" hyprland
      else
        log_error "Hyprland package not found for Debian ${codename}."
        log_error "See: https://wiki.hypr.land/Getting-Started/Installation/"
        exit 1
      fi
      ;;
  esac
}

hyprland_install() {
  local codename

  codename="$(debian_codename)"
  log_info "Detected Debian codename: ${codename}"

  hyprland_install_from_apt "$codename"

  deploy_user_file "${DOTFILES_ROOT}/config/wayland/hyprland/hyprland.conf" ".config/hypr/hyprland.conf"
}

hyprland_install

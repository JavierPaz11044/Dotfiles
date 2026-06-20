#!/usr/bin/env bash
# Install Hyprland and deploy Wayland compositor configuration.
# https://wiki.hypr.land/Getting-Started/Installation/

hyprland_backports_enabled() {
  local codename="$1"

  grep -rq "${codename}-backports" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null
}

hyprland_install_package() {
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
      if ! hyprland_backports_enabled "$codename"; then
        log_error "Hyprland on Trixie requires the backports repository."
        log_error "Add this line to your APT sources (main is enough):"
        log_error "  deb http://deb.debian.org/debian trixie-backports main"
        log_error "Then run: sudo apt update"
        log_error "See: https://wiki.hypr.land/Getting-Started/Installation/"
        exit 1
      fi

      log_info "Installing Hyprland from trixie-backports..."
      apt-get install -y -t trixie-backports hyprland
      ;;
    forky|sid|*)
      if apt-cache show hyprland >/dev/null 2>&1; then
        log_info "Installing Hyprland..."
        apt-get install -y hyprland
      elif hyprland_backports_enabled "$codename" && apt-cache show -t "${codename}-backports" hyprland >/dev/null 2>&1; then
        log_info "Installing Hyprland from ${codename}-backports..."
        apt-get install -y -t "${codename}-backports" hyprland
      else
        log_error "Hyprland package not found for Debian ${codename}."
        log_error "Enable ${codename}-backports or see: https://wiki.hypr.land/Getting-Started/Installation/"
        exit 1
      fi
      ;;
  esac
}

hyprland_install() {
  local codename

  codename="$(debian_codename)"
  log_info "Detected Debian codename: ${codename}"

  hyprland_install_package "$codename"

  deploy_user_file "${DOTFILES_ROOT}/config/wayland/hyprland/hyprland.conf" ".config/hypr/hyprland.conf"
}

hyprland_install

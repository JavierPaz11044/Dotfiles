#!/usr/bin/env bash
# Install Hyprland, session launcher, polkit agent, and user config.
# https://wiki.hypr.land/Getting-Started/Installation/

hyprland_install_session() {
  local hypr_bin session_dir session_file

  hypr_bin="$(command -v Hyprland || command -v hyprland || true)"
  if [[ -z "$hypr_bin" ]]; then
    log_error "Hyprland binary not found after package install."
    exit 1
  fi

  session_dir="/usr/share/wayland-sessions"
  session_file="${session_dir}/hyprland.desktop"

  log_info "Installing Hyprland session launcher at ${session_file}..."
  {
    printf '%s\n' "[Desktop Entry]"
    printf '%s\n' "Name=Hyprland"
    printf '%s\n' "Comment=Hyprland Wayland compositor"
    printf '%s\n' "Exec=dbus-run-session ${hypr_bin}"
    printf '%s\n' "Type=Application"
    printf '%s\n' "DesktopNames=Hyprland"
  } > "$session_file"
  chmod 644 "$session_file"
}

hyprland_install_polkit_agent() {
  local codename

  codename="$(debian_codename)"
  log_info "Installing Polkit authentication agent..."

  case "$codename" in
    trixie)
      if apt-cache show -t trixie-backports hyprpolkitagent >/dev/null 2>&1; then
        apt-get install -y -t trixie-backports hyprpolkitagent
        return
      fi
      ;;
    forky|sid)
      if apt-cache show hyprpolkitagent >/dev/null 2>&1; then
        apt-get install -y hyprpolkitagent
        return
      fi
      ;;
  esac

  if apt-cache show lxpolkit >/dev/null 2>&1; then
    log_warn "hyprpolkitagent not found, installing lxpolkit"
    apt-get install -y lxpolkit
    return
  fi

  log_warn "No polkit agent package found; you may need to install hyprpolkitagent manually"
}

hyprland_install_package() {
  local codename pocket

  codename="$(debian_codename)"
  pocket="${codename}-backports"

  log_info "Updating package lists..."
  apt-get update

  apt-get install -y jq socat polkitd dbus-user-session

  case "$codename" in
    bookworm|bullseye)
      log_error "Hyprland is not available on Debian ${codename}."
      exit 1
      ;;
    trixie)
      log_info "Installing Hyprland from ${pocket}..."
      apt-get install -y -t "$pocket" hyprland
      ;;
    forky|sid)
      apt-get install -y hyprland
      ;;
    *)
      log_error "Unsupported Debian codename: ${codename}"
      exit 1
      ;;
  esac
}

hyprland_install() {
  require_backports

  log_info "Detected Debian codename: $(debian_codename)"

  hyprland_install_package
  hyprland_install_session
  hyprland_install_polkit_agent

  deploy_user_file "${DOTFILES_ROOT}/config/wayland/hyprland/hyprland.conf" ".config/hypr/hyprland.conf"
}

hyprland_install

# shellcheck source=lib/verify.sh
source "${DOTFILES_ROOT}/lib/verify.sh"
if ! verify_hyprland; then
  log_error "Hyprland verification failed."
  exit 1
fi

log_info "Hyprland step complete."

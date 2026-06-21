#!/usr/bin/env bash
# Install Hyprland, session launcher, polkit agent, and user config.
# https://wiki.hypr.land/Getting-Started/Installation/

hyprland_install_session() {
  local session_dir session_file template hypr_bin

  session_dir="/usr/share/wayland-sessions"
  session_file="${session_dir}/hyprland.desktop"
  template="${DOTFILES_ROOT}/config/wayland/hyprland/hyprland.desktop"

  # Debian Hyprland 0.53+ must be started via start-hyprland (not Hyprland directly).
  if [[ -x /usr/bin/start-hyprland ]]; then
    if [[ -f "$session_file" ]] && grep -q 'start-hyprland' "$session_file"; then
      log_info "Hyprland session file OK (${session_file})"
      return
    fi

    log_info "Installing Hyprland session launcher at ${session_file}..."
    deploy_system_file "$template" "$session_file"
    return
  fi

  hypr_bin="$(command -v Hyprland || command -v hyprland || true)"
  if [[ -z "$hypr_bin" ]]; then
    log_error "Hyprland binary not found after package install."
    exit 1
  fi

  if [[ -f "$session_file" ]]; then
    log_warn "start-hyprland not found; keeping existing ${session_file}"
    return
  fi

  log_warn "start-hyprland not found; installing legacy session launcher"
  {
    printf '%s\n' "[Desktop Entry]"
    printf '%s\n' "Name=Hyprland"
    printf '%s\n' "Comment=Hyprland Wayland compositor"
    printf '%s\n' "Exec=dbus-run-session ${hypr_bin}"
    printf '%s\n' "TryExec=${hypr_bin}"
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

  deploy_user_file "${DOTFILES_ROOT}/config/wayland/hyprland/hyprland.lua" ".config/hypr/hyprland.lua"
}

hyprland_install

# shellcheck source=lib/verify.sh
source "${DOTFILES_ROOT}/lib/verify.sh"
if ! verify_hyprland; then
  log_error "Hyprland verification failed."
  exit 1
fi

log_info "Hyprland step complete."

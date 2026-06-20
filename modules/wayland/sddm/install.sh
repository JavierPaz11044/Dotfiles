#!/usr/bin/env bash
# Install SDDM and register Hyprland as the default Wayland session.
# https://wiki.hypr.land/ — SDDM is the recommended display manager for Wayland.

sddm_install_hyprland_session() {
  local hypr_bin session_dir

  hypr_bin="$(command -v Hyprland || command -v hyprland || true)"
  if [[ -z "$hypr_bin" ]]; then
    log_error "Hyprland binary not found. Run the hyprland module first."
    exit 1
  fi

  session_dir="/usr/share/wayland-sessions"
  if [[ ! -f "${session_dir}/hyprland.desktop" ]]; then
    log_info "Installing Hyprland session file to ${session_dir}..."
    {
      printf '%s\n' "[Desktop Entry]"
      printf '%s\n' "Name=Hyprland"
      printf '%s\n' "Comment=Hyprland Wayland compositor"
      printf '%s\n' "Exec=dbus-run-session ${hypr_bin}"
      printf '%s\n' "Type=Application"
      printf '%s\n' "DesktopNames=Hyprland"
    } > "${session_dir}/hyprland.desktop"
    chmod 644 "${session_dir}/hyprland.desktop"
  else
    log_info "Hyprland session file already provided by package"
  fi
}

sddm_install() {
  log_info "Installing SDDM..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends sddm polkit

  deploy_system_file \
    "${DOTFILES_ROOT}/config/wayland/sddm/10-hyprland.conf" \
    "/etc/sddm.conf.d/10-dotfiles-hyprland.conf"

  sddm_install_hyprland_session

  if command -v update-alternatives >/dev/null 2>&1; then
    update-alternatives --set x-display-manager /usr/sbin/sddm 2>/dev/null || true
  fi

  systemctl enable sddm
  log_info "SDDM enabled with Hyprland as default session"
  log_info "Reboot to start the graphical login (or: systemctl start sddm)"
}

sddm_install

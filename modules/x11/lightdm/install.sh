#!/usr/bin/env bash
# Install LightDM and register bspwm as the default X11 session.

lightdm_install_bspwm_session() {
  local session_dir="/usr/share/xsessions"

  if [[ ! -f "${session_dir}/bspwm.desktop" ]]; then
    log_info "Installing bspwm session file to ${session_dir}..."
    install -m 644 \
      "${DOTFILES_ROOT}/config/x11/lightdm/bspwm.desktop" \
      "${session_dir}/bspwm.desktop"
  else
    log_info "bspwm session file already provided by package"
  fi
}

lightdm_install() {
  if ! command -v bspwm >/dev/null 2>&1; then
    log_error "bspwm not found. Run the bspwm module first."
    exit 1
  fi

  log_info "Installing LightDM..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y lightdm lightdm-gtk-greeter polkit

  deploy_system_file \
    "${DOTFILES_ROOT}/config/x11/lightdm/50-bspwm.conf" \
    "/etc/lightdm/lightdm.conf.d/50-dotfiles-bspwm.conf"

  lightdm_install_bspwm_session

  if command -v update-alternatives >/dev/null 2>&1; then
    update-alternatives --set x-display-manager /usr/sbin/lightdm 2>/dev/null || true
  fi

  systemctl enable lightdm
  log_info "LightDM enabled with bspwm as default session"
  log_info "Reboot to start the graphical login (or: systemctl start lightdm)"
}

lightdm_install

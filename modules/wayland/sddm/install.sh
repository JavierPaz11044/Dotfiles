#!/usr/bin/env bash
# Install SDDM configured for Hyprland (session must exist from hyprland module).

sddm_install() {
  require_hyprland

  log_info "Installing SDDM and PolicyKit..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    sddm \
    polkitd \
    dbus-user-session \
    libpam-systemd

  if ! systemctl is-active --quiet polkit; then
    systemctl start polkit || true
  fi

  deploy_system_file \
    "${DOTFILES_ROOT}/config/wayland/sddm/10-hyprland.conf" \
    "/etc/sddm.conf.d/10-dotfiles-hyprland.conf"

  if command -v update-alternatives >/dev/null 2>&1; then
    update-alternatives --set x-display-manager /usr/sbin/sddm 2>/dev/null || true
  fi

  systemctl enable sddm
}

sddm_install

# shellcheck source=lib/verify.sh
source "${DOTFILES_ROOT}/lib/verify.sh"
if ! verify_sddm; then
  log_error "SDDM verification failed."
  exit 1
fi

log_info "SDDM step complete. Reboot or run: sudo systemctl start sddm"

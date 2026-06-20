#!/usr/bin/env bash
# Install Hyprland and deploy Wayland compositor configuration.

hyprland_install() {
  log_info "Installing Hyprland and runtime dependencies..."
  apt-get install -y hyprland jq socat

  deploy_user_file "${DOTFILES_ROOT}/config/wayland/hyprland/hyprland.conf" ".config/hypr/hyprland.conf"
}

hyprland_install

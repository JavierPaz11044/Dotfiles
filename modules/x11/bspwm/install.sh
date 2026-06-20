#!/usr/bin/env bash
# Install bspwm/sxhkd and deploy native X11 window-manager configuration.

bspwm_install() {
  log_info "Installing bspwm (includes sxhkd)..."
  apt-get install -y bspwm

  deploy_user_file "${DOTFILES_ROOT}/config/x11/sxhkd/sxhkdrc" ".config/sxhkd/sxhkdrc"
  deploy_user_file "${DOTFILES_ROOT}/config/x11/bspwm/bspwmrc" ".config/bspwm/bspwmrc" 755
}

bspwm_install

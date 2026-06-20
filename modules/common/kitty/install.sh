#!/usr/bin/env bash
# Install kitty from official precompiled binaries, deploy fonts and configuration.
# https://sw.kovidgoyal.net/kitty/binary/

kitty_install_binary() {
  if [[ -x "$(dotfiles_target_home)/.local/kitty.app/bin/kitty" ]]; then
    log_info "kitty already installed at ~/.local/kitty.app"
    return
  fi

  log_info "Installing kitty from official binary installer..."
  run_as_target_user bash -c 'curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n'
}

kitty_link_binaries() {
  local home

  home="$(dotfiles_target_home)"

  if [[ ! -x "${home}/.local/kitty.app/bin/kitty" ]]; then
    log_warn "kitty binary not found, skipping PATH symlinks"
    return
  fi

  log_info "Linking kitty and kitten into ~/.local/bin..."
  run_as_target_user bash <<'EOF'
set -euo pipefail
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/"
EOF
}

kitty_install() {
  if ! command -v curl >/dev/null 2>&1; then
    log_info "Installing curl..."
    apt-get install -y curl
  fi

  if ! command -v fc-cache >/dev/null 2>&1; then
    log_info "Installing fontconfig..."
    apt-get install -y fontconfig
  fi

  kitty_install_binary
  kitty_link_binaries
  install_user_fonts
  deploy_user_file "${DOTFILES_ROOT}/config/common/kitty/kitty.conf" ".config/kitty/kitty.conf"
}

kitty_install

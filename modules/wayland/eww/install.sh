#!/usr/bin/env bash
# Build eww from source (Wayland) and deploy workspace bar configuration.
# https://elkowar.github.io/eww/

EWW_VERSION="${EWW_VERSION:-v0.6.0}"

eww_install_build_deps() {
  log_info "Installing eww build dependencies..."
  apt-get install -y \
    build-essential \
    curl \
    git \
    pkg-config \
    libgtk-3-dev \
    libgtk-layer-shell-dev \
    libpango1.0-dev \
    libgdk-pixbuf-2.0-dev \
    libdbusmenu-gtk3-dev \
    libcairo2-dev \
    libglib2.0-dev
}

eww_install_rust() {
  if run_as_target_user bash -lc 'command -v cargo >/dev/null'; then
    log_info "Rust toolchain already available for target user"
    return
  fi

  log_info "Installing rustup for target user..."
  run_as_target_user bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal'
}

eww_build() {
  local home src

  home="$(dotfiles_target_home)"
  src="${home}/.local/src/eww"

  if [[ -x "${home}/.local/bin/eww" ]]; then
    log_info "eww already installed at ~/.local/bin/eww"
    return
  fi

  log_info "Building eww ${EWW_VERSION} (Wayland)..."
  run_as_target_user bash <<EOF
set -euo pipefail
mkdir -p "\$HOME/.local/src" "\$HOME/.local/bin"
if [[ ! -d "${src}/.git" ]]; then
  git clone --depth 1 --branch "${EWW_VERSION}" https://github.com/elkowar/eww "${src}"
fi
cd "${src}"
source "\$HOME/.cargo/env"
cargo build --release --no-default-features --features wayland
install -m 755 target/release/eww "\$HOME/.local/bin/eww"
EOF
}

eww_install() {
  require_hyprland

  eww_install_build_deps
  eww_install_rust
  eww_build
  deploy_user_tree "${DOTFILES_ROOT}/config/wayland/eww" ".config/eww"
  run_as_target_user chmod +x "$(dotfiles_target_home)/.config/eww/scripts/workspaces.sh"
}

eww_install

if ! verify_eww; then
  log_error "eww verification failed."
  exit 1
fi

log_info "eww step complete."

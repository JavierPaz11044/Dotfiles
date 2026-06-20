#!/usr/bin/env bash
# Dotfiles installer for minimal Debian systems.
#
# Usage:
#   sudo ./install.sh common          # shared modules (apt, kitty)
#   sudo ./install.sh x11             # X11 stack (common + bspwm + lightdm)
#   sudo ./install.sh wayland         # Wayland stack (common + hyprland + eww + sddm)
#   sudo ./install.sh apt hyprland    # individual modules

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

PROFILE_COMMON=(apt kitty)
PROFILE_X11=(apt kitty bspwm lightdm)
PROFILE_WAYLAND=(apt kitty hyprland eww sddm)

usage() {
  cat <<EOF
Usage: sudo ${0##*/} <profile|module ...>

Profiles:
  common     Shared setup: apt, kitty
  x11        X11 stack: common + bspwm/sxhkd + lightdm
  wayland    Wayland stack: common + hyprland + eww + sddm

Modules:
  apt        Refresh APT package lists
  kitty      Kitty binary, fonts, terminal config
  bspwm      bspwm/sxhkd (X11 only)
  lightdm    LightDM login manager with bspwm session (X11)
  hyprland   Hyprland compositor (Trixie: needs backports)
  eww        eww workspace bar (Wayland, builds from source)
  sddm       SDDM login manager with Hyprland session (Wayland)
EOF
}

expand_profile() {
  local profile="$1"

  case "$profile" in
    common) printf '%s\n' "${PROFILE_COMMON[@]}" ;;
    x11) printf '%s\n' "${PROFILE_X11[@]}" ;;
    wayland) printf '%s\n' "${PROFILE_WAYLAND[@]}" ;;
    *) return 1 ;;
  esac
}

main() {
  if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
  fi

  require_root
  require_debian

  local modules=()
  local arg expanded

  for arg in "$@"; do
    if expanded="$(expand_profile "$arg" 2>/dev/null)"; then
      while IFS= read -r module; do
        modules+=("$module")
      done <<< "$expanded"
    else
      modules+=("$arg")
    fi
  done

  log_info "Starting Dotfiles installation"

  for module in "${modules[@]}"; do
    run_module "$module"
  done

  log_info "Installation complete"
}

main "$@"

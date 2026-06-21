#!/usr/bin/env bash
# Dotfiles installer for minimal Debian systems.
#
# Usage:
#   sudo ./install.sh common              # shared modules (apt, kitty)
#   sudo ./install.sh x11                 # X11 stack
#   sudo ./install.sh wayland             # full Wayland stack (step by step inside)
#   sudo ./install.sh backports           # step 1: enable backports + test
#   sudo ./install.sh hyprland            # step 2: hyprland + session + test
#   sudo ./install.sh sddm                # step 3: sddm + test
#   sudo ./install.sh test backports      # verify only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

PROFILE_COMMON=(apt kitty)
PROFILE_X11=(apt kitty bspwm lightdm)
PROFILE_WAYLAND=(apt backports hyprland sddm)

WAYLAND_TESTS=(backports hyprland sddm)

usage() {
  cat <<EOF
Usage: sudo ${0##*/} <profile|module ...>
       sudo ${0##*/} test [module ...]

Profiles:
  common     Shared setup: apt, kitty
  x11        X11 stack: common + bspwm/sxhkd + lightdm
  wayland    Wayland stack (step by step): apt, backports, hyprland, sddm

Wayland steps (run in order):
  backports  Enable backports + verify hyprland is available
  hyprland   Install Hyprland, session launcher, config + verify
  sddm       Install SDDM for Hyprland + verify

Other modules:
  apt        Refresh APT package lists
  kitty      Kitty binary, fonts, terminal config
  bspwm      bspwm/sxhkd (X11 only)
  lightdm    LightDM with bspwm session (X11)
  eww        eww workspace bar (optional, after hyprland)

Tests:
  test       Verify installed modules (default wayland tests if none given)
  Examples:
    sudo ./install.sh test backports
    sudo ./install.sh test hyprland sddm
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

run_tests() {
  local modules=("$@")
  local module failed=0

  if [[ ${#modules[@]} -eq 0 ]]; then
    modules=("${WAYLAND_TESTS[@]}")
  fi

  log_info "Running verification tests"

  for module in "${modules[@]}"; do
    if ! run_verify "$module"; then
      failed=1
    fi
  done

  if [[ "$failed" -eq 1 ]]; then
    log_error "Some tests failed."
    exit 1
  fi

  log_info "All tests passed."
}

main() {
  if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
  fi

  require_root
  require_debian

  if [[ "$1" == "test" ]]; then
    shift
    run_tests "$@"
    exit 0
  fi

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

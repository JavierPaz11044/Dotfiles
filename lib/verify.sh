#!/usr/bin/env bash
# Verification helpers for install modules.

verify_backports() {
  local codename pocket

  codename="$(debian_codename)"
  pocket="${codename}-backports"

  case "$codename" in
    bookworm|bullseye)
      log_warn "Backports step skipped on ${codename} (not required for Hyprland here)"
      return 0
      ;;
    trixie|forky|sid)
      if ! apt-cache show -t "$pocket" hyprland >/dev/null 2>&1; then
        log_error "[FAIL] backports: hyprland not available from ${pocket}"
        log_error "       Run: sudo ./install.sh backports"
        return 1
      fi
      log_info "[OK] backports: hyprland available from ${pocket}"
      return 0
      ;;
    *)
      log_error "[FAIL] backports: unsupported codename ${codename}"
      return 1
      ;;
  esac
}

verify_hyprland() {
  local home hypr_bin session

  home="$(dotfiles_target_home)"
  hypr_bin="$(command -v Hyprland || command -v hyprland || true)"
  session="/usr/share/wayland-sessions/hyprland.desktop"

  if [[ -z "$hypr_bin" ]]; then
    log_error "[FAIL] hyprland: binary not found in PATH"
    return 1
  fi
  log_info "[OK] hyprland: binary at ${hypr_bin}"

  if ! dpkg -s hyprland >/dev/null 2>&1; then
    log_error "[FAIL] hyprland: package hyprland is not installed"
    return 1
  fi
  log_info "[OK] hyprland: package installed"

  if [[ ! -f "$session" ]]; then
    log_error "[FAIL] hyprland: session file missing (${session})"
    return 1
  fi
  log_info "[OK] hyprland: session file ${session}"

  if [[ -x /usr/bin/start-hyprland ]]; then
    if ! grep -q 'start-hyprland' "$session"; then
      log_error "[FAIL] hyprland: session must use /usr/bin/start-hyprland (Hyprland 0.53+)"
      log_error "       Run: sudo ./install.sh hyprland"
      return 1
    fi
    log_info "[OK] hyprland: session uses start-hyprland"
  elif ! grep -qE '^Exec=.*(Hyprland|hyprland)' "$session"; then
    log_error "[FAIL] hyprland: session file has no valid Exec line"
    return 1
  else
    log_info "[OK] hyprland: session Exec line present"
  fi

  if [[ ! -f "${home}/.config/hypr/hyprland.conf" ]]; then
    log_error "[FAIL] hyprland: config missing at ~/.config/hypr/hyprland.conf"
    return 1
  fi
  log_info "[OK] hyprland: user config deployed"

  return 0
}

verify_sddm() {
  if ! command -v sddm >/dev/null 2>&1; then
    log_error "[FAIL] sddm: binary not found"
    return 1
  fi
  log_info "[OK] sddm: binary installed"

  if ! dpkg -s sddm >/dev/null 2>&1; then
    log_error "[FAIL] sddm: package not installed"
    return 1
  fi
  log_info "[OK] sddm: package installed"

  if ! systemctl is-enabled sddm >/dev/null 2>&1; then
    log_error "[FAIL] sddm: service is not enabled"
    return 1
  fi
  log_info "[OK] sddm: service enabled"

  if [[ ! -f /etc/sddm.conf.d/10-dotfiles-hyprland.conf ]]; then
    log_error "[FAIL] sddm: config missing at /etc/sddm.conf.d/10-dotfiles-hyprland.conf"
    return 1
  fi
  log_info "[OK] sddm: config installed"

  local default_session session_path
  default_session="$(grep -E '^DefaultSession=' /etc/sddm.conf.d/10-dotfiles-hyprland.conf | cut -d= -f2- | tr -d '[:space:]')"
  if [[ -z "$default_session" ]]; then
    log_error "[FAIL] sddm: DefaultSession not set in config"
    return 1
  fi
  session_path="/usr/share/wayland-sessions/${default_session}"
  if [[ ! -f "$session_path" ]]; then
    log_error "[FAIL] sddm: DefaultSession points to missing file (${session_path})"
    log_error "       Run: sudo ./install.sh hyprland"
    return 1
  fi
  log_info "[OK] sddm: DefaultSession ${default_session} exists"

  if ! systemctl is-active --quiet polkit; then
    log_error "[FAIL] sddm: polkit service is not running"
    return 1
  fi
  log_info "[OK] sddm: polkit service running"

  return 0
}

verify_eww() {
  local home

  home="$(dotfiles_target_home)"

  if [[ ! -x "${home}/.local/bin/eww" ]]; then
    log_error "[FAIL] eww: binary missing at ~/.local/bin/eww"
    return 1
  fi
  log_info "[OK] eww: binary installed"

  if [[ ! -f "${home}/.config/eww/eww.yuck" ]]; then
    log_error "[FAIL] eww: config missing at ~/.config/eww/eww.yuck"
    return 1
  fi
  log_info "[OK] eww: config deployed"

  return 0
}

run_verify() {
  local module="$1"
  local fn="verify_${module}"

  if ! declare -f "$fn" >/dev/null 2>&1; then
    log_error "No verification defined for module: ${module}"
    return 1
  fi

  log_info "Testing module: ${module}"
  "$fn"
}

require_backports() {
  if ! verify_backports; then
    log_error "Backports are not ready. Run first: sudo ./install.sh backports"
    exit 1
  fi
}

require_hyprland() {
  if ! verify_hyprland; then
    log_error "Hyprland is not ready. Run first: sudo ./install.sh hyprland"
    exit 1
  fi
}

#!/usr/bin/env bash
# Enable Debian backports (required for Hyprland on Trixie).

backports_install() {
  local codename dest

  codename="$(debian_codename)"
  dest="/etc/apt/sources.list.d/dotfiles-${codename}-backports.list"

  log_info "Detected Debian codename: ${codename}"

  case "$codename" in
    bookworm|bullseye)
      log_warn "Backports are not required on ${codename} for this stack."
      return 0
      ;;
    trixie|forky|sid)
      if [[ -f "$dest" ]]; then
        log_info "Backports source already present: ${dest}"
      else
        log_info "Adding ${codename}-backports source..."
        {
          printf '%s\n' "# Managed by Dotfiles backports module"
          printf '%s\n' "deb http://deb.debian.org/debian ${codename}-backports main"
        } > "$dest"
        chmod 644 "$dest"
        log_info "Installed ${dest}"
      fi
      ;;
    *)
      log_error "Unsupported Debian codename: ${codename}"
      exit 1
      ;;
  esac

  log_info "Updating package lists..."
  apt-get update
}

backports_install

# shellcheck source=lib/verify.sh
source "${DOTFILES_ROOT}/lib/verify.sh"
if ! verify_backports; then
  log_error "Backports verification failed."
  exit 1
fi

log_info "Backports step complete."

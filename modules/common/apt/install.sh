#!/usr/bin/env bash
# Refresh APT package lists before other modules install packages.

apt_install() {
  log_info "Updating package lists..."
  apt-get update
}

apt_install

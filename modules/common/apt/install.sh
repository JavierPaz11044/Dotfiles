#!/usr/bin/env bash
# Enable contrib and non-free using add-apt-repository (no manual sources.list edits).

apt_install() {
  log_info "Updating package lists..."
  apt-get update

  log_info "Installing software-properties-common..."
  apt-get install -y software-properties-common

  log_info "Enabling contrib component..."
  add-apt-repository -y -c contrib

  log_info "Enabling non-free component..."
  add-apt-repository -y -c non-free

  log_info "Updating package lists..."
  apt-get update
}

apt_install

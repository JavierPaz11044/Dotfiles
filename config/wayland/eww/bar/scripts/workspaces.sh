#!/usr/bin/env bash
# Stream Hyprland workspaces as JSON for eww.

emit() {
  local active

  active="$(hyprctl activeworkspace -j | jq '.id')"
  hyprctl workspaces -j | jq --argjson active "$active" '
    [.[] | {
      id: .id,
      active: (.id == $active),
      occupied: (.windows > 0)
    }] | sort_by(.id)
  '
}

emit

instance="$(ls "${XDG_RUNTIME_DIR}/hypr" 2>/dev/null | head -n1)"
if [[ -n "$instance" ]]; then
  socat -u "UNIX-CONNECT:${XDG_RUNTIME_DIR}/hypr/${instance}/.socket2.sock" - | while read -r _; do
    emit
  done
fi

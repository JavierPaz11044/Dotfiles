#!/usr/bin/env bash
# Stream Hyprland workspace state as JSON for eww deflisten.

emit() {
  local active

  active="$(hyprctl activeworkspace -j | jq '.id')"
  hyprctl workspaces -j | jq --argjson active "$active" '[.[] | {id: .id, active: (.id == $active)}] | sort_by(.id)'
}

emit

instance="$(ls "${XDG_RUNTIME_DIR}/hypr" 2>/dev/null | head -n1)"
if [[ -z "$instance" ]]; then
  exit 0
fi

socat -u "UNIX-CONNECT:${XDG_RUNTIME_DIR}/hypr/${instance}/.socket2.sock" - | while read -r _; do
  emit
done

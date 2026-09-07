#!/usr/bin/env bash
# Fullscreen toggle (alt-f) that cooperates with lone-window centering.
#
# On a space with many tiled windows: normal yabai zoom-fullscreen.
# On a space with one tiled window: toggle the centering instead.
# Zoom cannot grow a window past the space padding, so the script
# marks the space with a "nocenter_*" label and lifts the padding.

set -euo pipefail

[ -d /opt/homebrew/bin ] && PATH="/opt/homebrew/bin:$PATH"

space=$(yabai -m query --spaces --space)
idx=$(jq '.index' <<<"$space")
label=$(jq -r '.label' <<<"$space")

count=$(yabai -m query --windows --space "$idx" | jq \
  '[.[] | select(.["is-floating"] == false
                 and .["is-minimized"] == false
                 and .["is-hidden"] == false)] | length')

if [ "$count" -ne 1 ]; then
  exec yabai -m window --toggle zoom-fullscreen
fi

if [[ "$label" == nocenter* ]]; then
  yabai -m space "$idx" --label ""
else
  yabai -m space "$idx" --label "nocenter_${idx}"
fi

exec "$HOME/.config/yabai/center_single_window.sh"

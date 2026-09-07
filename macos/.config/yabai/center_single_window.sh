#!/usr/bin/env bash
# Center a lone tiled window, like Omarchy on Hyprland.
#
# A space with one tiled window gets wide side padding. The window then
# matches one pane of a two-pane split, centered on the screen.
# Spaces with more tiled windows return to the default padding.
#
# Signals in yabairc run this script on window and space changes.
# skhd also runs it after float toggles, because those fire no signal.

set -euo pipefail

# Signal actions can run with a minimal PATH.
[ -d /opt/homebrew/bin ] && PATH="/opt/homebrew/bin:$PATH"

top=$(yabai -m config top_padding)
bottom=$(yabai -m config bottom_padding)
left=$(yabai -m config left_padding)
right=$(yabai -m config right_padding)
gap=$(yabai -m config window_gap)

displays=$(yabai -m query --displays)
windows=$(yabai -m query --windows)

yabai -m query --spaces | jq -c '.[]' | while read -r space; do
  [ "$(jq '.["is-native-fullscreen"]' <<<"$space")" = "true" ] && continue
  idx=$(jq '.index' <<<"$space")
  didx=$(jq '.display' <<<"$space")

  # Count the tiled windows on this space.
  count=$(jq --argjson s "$idx" \
    '[.[] | select(.space == $s
                   and .["is-floating"] == false
                   and .["is-minimized"] == false
                   and .["is-hidden"] == false)] | length' <<<"$windows")

  if [ "$count" -eq 1 ]; then
    screen_w=$(jq --argjson d "$didx" '.[] | select(.index == $d) | .frame.w' <<<"$displays")
    # Pane width in a two-pane split: (screen - left - right - gap) / 2.
    # Side padding that centers a window of that width:
    side=$(awk -v w="$screen_w" -v l="$left" -v r="$right" -v g="$gap" \
      'BEGIN { pane = (w - l - r - g) / 2; printf "%d", (w - pane) / 2 }')
    new_left=$side new_right=$side
  else
    new_left=$left new_right=$right
  fi

  # Skip spaces that already have the correct padding. This stops signal
  # loops, because each padding change fires window_moved again.
  [ "$(yabai -m config --space "$idx" left_padding)" = "$new_left" ] && continue
  yabai -m space "$idx" --padding "abs:${top}:${bottom}:${new_left}:${new_right}"
done

#!/usr/bin/env bash
#
# yabai picture-in-picture helper, driven by skhd.
#
#   pip.sh enter
#       Toggle the focused window into / out of "PiP": floating + sticky
#       (visible on every space). On enter it parks in the top-right corner.
#
#   pip.sh <left|right|top|bottom> <swap-dir>
#       If the focused window is floating, snap it to that corner of the
#       current display, preserving the other axis (so h/l/k/j walk the four
#       corners). Pressing left / right while already pinned to that edge hops
#       the window to the adjacent monitor and continues on its near side.
#       If the focused window is tiled, fall back to `yabai window --swap`.
#
#   pip.sh focus <west|east|north|south>
#       yabai can't focus directionally *out of* a floating window, so when the
#       focused window floats we pick the nearest managed window on this space
#       ourselves (falling back to the most recent). Tiled windows get normal
#       directional focus, falling back to the adjacent display at a screen edge.
#
# Corners use 2x the normal window padding: grid yields the usual *_padding
# (8px) inset and clears the menu bar, then we nudge an extra PAD inward.

set -uo pipefail

PAD=8 # extra inset on top of yabai's grid padding -> 16px total

win="$(yabai -m query --windows --window)"
wid="$(echo "$win" | jq -r '.id')"
floating="$(echo "$win" | jq -r '.["is-floating"]')"
disp="$(yabai -m query --displays --display)"

# place <left|right> <top|bottom> on the window's current display
place() {
  local h="$1" v="$2" col row dx dy
  if [ "$h" = left ]; then col=0; dx=$PAD; else col=4; dx=$((-PAD)); fi
  if [ "$v" = top ]; then row=0; dy=$PAD; else row=4; dy=$((-PAD)); fi
  yabai -m window "$wid" --grid "6:6:${col}:${row}:2:2"
  yabai -m window "$wid" --move "rel:${dx}:${dy}"
}

# which half of its display the window currently occupies
side_h() { echo "$win" | jq -r --argjson d "$disp" \
  '((.frame.x + .frame.w / 2) < ($d.frame.x + $d.frame.w / 2)) | if . then "left" else "right" end'; }
side_v() { echo "$win" | jq -r --argjson d "$disp" \
  '((.frame.y + .frame.h / 2) < ($d.frame.y + $d.frame.h / 2)) | if . then "top" else "bottom" end'; }

case "${1:-}" in
enter)
  if [ "$floating" = true ]; then # exit PiP -> back to tiling
    yabai -m window "$wid" --toggle sticky
    yabai -m window "$wid" --toggle float
  else # enter PiP
    yabai -m window "$wid" --toggle float
    yabai -m window "$wid" --toggle sticky
    place right top
  fi
  ;;
left)
  [ "$floating" = true ] || { yabai -m window --swap "$2"; exit; }
  # directional --display west is reliable; prev/next is focus-dependent and flaky
  if [ "$(side_h)" = left ] && yabai -m window "$wid" --display west 2>/dev/null; then
    place right "$(side_v)"
    yabai -m window --focus "$wid" 2>/dev/null || true # focus does not follow on its own
  else
    place left "$(side_v)"
  fi
  ;;
right)
  [ "$floating" = true ] || { yabai -m window --swap "$2"; exit; }
  if [ "$(side_h)" = right ] && yabai -m window "$wid" --display east 2>/dev/null; then
    place left "$(side_v)"
    yabai -m window --focus "$wid" 2>/dev/null || true
  else
    place right "$(side_v)"
  fi
  ;;
top)
  [ "$floating" = true ] || { yabai -m window --swap "$2"; exit; }
  place "$(side_h)" top
  ;;
bottom)
  [ "$floating" = true ] || { yabai -m window --swap "$2"; exit; }
  place "$(side_h)" bottom
  ;;
focus)
  d="$2"
  if [ "$floating" != true ]; then # tiled: normal focus, else adjacent display
    yabai -m window --focus "$d" 2>/dev/null || yabai -m display --focus "$d"
    exit
  fi
  # floating: pick the nearest managed window on this space in direction d
  target="$(yabai -m query --windows --space | jq -r --arg d "$d" \
    --argjson cx "$(echo "$win" | jq '.frame.x + .frame.w/2')" \
    --argjson cy "$(echo "$win" | jq '.frame.y + .frame.h/2')" '
      [ .[] | select(.["is-floating"] == false and .["is-minimized"] == false)
            | {id, x: (.frame.x + .frame.w/2), y: (.frame.y + .frame.h/2)} ]
      | map(select(
          ($d == "west" and .x < $cx) or ($d == "east" and .x > $cx) or
          ($d == "north" and .y < $cy) or ($d == "south" and .y > $cy)))
      | sort_by(if $d == "west" then -.x elif $d == "east" then .x
                elif $d == "north" then -.y else .y end)
      | (.[0].id // empty)')"
  if [ -n "$target" ]; then
    yabai -m window --focus "$target"
  else
    yabai -m window --focus recent 2>/dev/null || yabai -m display --focus "$d"
  fi
  ;;
esac

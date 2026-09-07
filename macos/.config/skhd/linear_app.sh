#!/usr/bin/env bash
# ctrl+alt-l: open linear-tui like a standalone app.
#
# The TUI lives in a persistent tmux session named "linear". The bind
# focuses the existing window when one exists. Otherwise it opens a new
# Ghostty window that attaches to the session. Closing the window only
# detaches the client, so the TUI keeps its state for the next open.
#
# The window command, title, and lifecycle live in linear-tui.conf.
# The config pins the title, which gives yabai an exact match key.

set -euo pipefail

# skhd starts with a minimal PATH.
[ -d /opt/homebrew/bin ] && PATH="/opt/homebrew/bin:$PATH"

title="linear-tui"

# Focus the existing window when one exists.
win=$(yabai -m query --windows | jq -r --arg t "$title" \
  '[.[] | select(.app == "Ghostty" and .title == $t)][0].id // empty')
if [ -n "$win" ]; then
  exec yabai -m window --focus "$win"
fi

open -na Ghostty --args --config-file="$HOME/.config/ghostty/linear-tui.conf"

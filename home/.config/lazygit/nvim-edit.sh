#!/usr/bin/env bash
#
# lazygit `e` (edit) handler. Opens the selected file(s) in the *parent*
# Neovim as normal buffers (not tabs), replaces the quickfix list with the
# selection, and opens Trouble — see ~/.config/nvim/lua/util/lazygit_qf.lua.
#
# Wired up via os.edit / os.editAtLine in ~/.config/lazygit/config.yml.
# lazygit substitutes {{filename}} unquoted, so a multi-file selection arrives
# as multiple positional args ("$@"). When run outside Neovim ($NVIM unset),
# falls back to a normal nvim so standalone lazygit still works.
set -euo pipefail

line=0
if [ "${1:-}" = "--line" ]; then
  line="$2"
  shift 2
fi

if [ -z "${NVIM:-}" ]; then
  if [ "$line" != 0 ]; then
    exec nvim "+$line" -- "$@"
  else
    exec nvim -- "$@"
  fi
fi

# Build a Vimscript list literal of absolute paths (lazygit runs us from the
# repo root), escaping single quotes as '' for Vimscript string literals.
list=""
for f in "$@"; do
  case "$f" in
  /*) abs="$f" ;;
  *) abs="$PWD/$f" ;;
  esac
  esc=${abs//\'/\'\'}
  list="${list:+$list,}'$esc'"
done

# Load the helper by absolute path rather than require(), so it works no matter
# which Neovim config (runtimepath) the parent instance happens to be using.
helper="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lua/util/lazygit_qf.lua"
helper_esc=${helper//\'/\'\'}

nvim --server "$NVIM" --remote-expr \
  "luaeval('dofile(_A.path).open(_A.files, _A.line)', {'path': '$helper_esc', 'files': [$list], 'line': $line})" \
  >/dev/null

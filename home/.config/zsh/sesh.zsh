# ⌘+j (sent as Alt+j by ghostty) → sesh picker. Only fires outside tmux;
# inside tmux the binding in tmux.conf catches M-j first.
function _sesh_picker() {
  emulate -L zsh
  local session
  session=$(sesh list --icons --hide-duplicates | fzf \
    --height 60% --reverse \
    --no-sort --prompt '⚡  ' \
    --bind 'tab:down,btab:up' \
    --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
    --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
    --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
    --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
    --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
    --preview-window 'right:60%' \
    --preview 'sesh preview {}')
  zle reset-prompt
  [[ -z "$session" ]] && return
  BUFFER="sesh connect \"$session\""
  zle accept-line
}
if command -v sesh >/dev/null && command -v fzf >/dev/null; then
  zle -N _sesh_picker
  bindkey '\ej' _sesh_picker
fi

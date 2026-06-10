# --- Completions ---------------------------------------------------------
# (previously handled by oh-my-zsh)
[ -d /opt/homebrew/share/zsh/site-functions ] && fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # case-insensitive

# --- History --------------------------------------------------------------
# (previously handled by oh-my-zsh)
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_dups hist_ignore_space hist_verify

# --- Aliases --------------------------------------------------------------
alias vim="nvim"
command -v bat >/dev/null && alias cat='bat'
if command -v zoxide >/dev/null; then
  alias cd='z'
  eval "$(zoxide init zsh)"
fi

# --- Tool integrations -----------------------------------------------------
# fzf first (ctrl-t files, alt-c dirs), then atuin so it wins ctrl-r history
command -v fzf >/dev/null && source <(fzf --zsh)
command -v atuin >/dev/null && eval "$(atuin init zsh)"

# --- PATH / tooling -------------------------------------------------------
export PATH="$HOME/.asdf/shims:$PATH"
command -v direnv >/dev/null && eval "$(direnv hook zsh)"
export GOPRIVATE=github.com/angellist/*
export GOBIN=$HOME/bin
export PATH="$GOBIN:$PATH"
command -v al >/dev/null && source <(al completion zsh)

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
zle -N _sesh_picker
bindkey '\ej' _sesh_picker

# --- Prompt ---------------------------------------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"

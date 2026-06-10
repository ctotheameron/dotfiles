# Tool replacements & integrations. Everything is guarded so the shell
# works on a fresh machine before packages are installed.

# nvim > vim
command -v nvim >/dev/null && alias vim='nvim'

# bat > cat
command -v bat >/dev/null && alias cat='bat'

# eza > ls
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -l --group-directories-first --icons=auto --git'
  alias la='eza -la --group-directories-first --icons=auto --git'
  alias tree='eza --tree --icons=auto'
fi

# zoxide > cd
if command -v zoxide >/dev/null; then
  alias cd='z'
  eval "$(zoxide init zsh)"
fi

# direnv
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# fzf first (ctrl-t files, alt-c dirs), then atuin so it wins ctrl-r history
command -v fzf >/dev/null && source <(fzf --zsh)
command -v atuin >/dev/null && eval "$(atuin init zsh)"

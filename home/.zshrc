# --- Completions ---------------------------------------------------------
[ -d /opt/homebrew/share/zsh/site-functions ] && fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # case-insensitive

# --- History --------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_dups hist_ignore_space hist_verify

# --- Aliases --------------------------------------------------------------
alias vim="nvim"

# --- PATH ------------------------------------------------------------------
export PATH="$HOME/.asdf/shims:$PATH"
export GOBIN=$HOME/bin
export PATH="$GOBIN:$PATH"

# --- Modular config: ~/.config/zsh/*.zsh -----------------------------------
# tools.zsh (eza/bat/zoxide/fzf/atuin/direnv), sesh.zsh (picker),
# work.zsh (gitignored, machine-local)
for rc in "$HOME/.config/zsh"/*.zsh(N); do
  source "$rc"
done
unset rc

# --- Prompt ---------------------------------------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"

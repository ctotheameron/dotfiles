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
  alias l='eza -l --icons --git -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias ltree='eza --tree --level=2 --icons --git'
fi

# zoxide > cd
if command -v zoxide >/dev/null; then
  alias cd='z'
  eval "$(zoxide init zsh)"
fi

# direnv
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# fzf first (ctrl-t files, alt-c dirs), then atuin so it wins ctrl-r history
if command -v fzf >/dev/null; then
  source <(fzf --zsh)

  # Catppuccin color scheme
  export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

  # Use fd for all fzf listings: faster, respects .gitignore, includes hidden
  if command -v fd >/dev/null; then
    export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

    # fd also powers fuzzy path/dir completion (e.g. `cd **<Tab>`)
    _fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
    _fzf_compgen_dir() { fd --type=d --hidden --exclude .git . "$1"; }
  fi

  # Previews: bat for files, eza tree for directories
  _fzf_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"
  export FZF_CTRL_T_OPTS="--preview '$_fzf_preview'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

  # Context-aware previews for ** completion (cd shows tree, ssh shows dig)
  _fzf_comprun() {
    local command=$1
    shift
    case "$command" in
      cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
      export|unset) fzf --preview "eval 'echo \${}'" "$@" ;;
      ssh)          fzf --preview 'dig {}' "$@" ;;
      *)            fzf --preview "$_fzf_preview" "$@" ;;
    esac
  }

  # fzf-git.sh: keybinds for git objects (ctrl-g ctrl-{b,t,h,...})
  [ -f ~/.config/fzf-git.sh/fzf-git.sh ] && source ~/.config/fzf-git.sh/fzf-git.sh
fi
command -v atuin >/dev/null && eval "$(atuin init zsh)"

# 1Password CLI: completions + shell plugins (created by `op plugin init`).
# Auth itself is per-machine: enable desktop-app integration in the 1Password
# app (Settings → Developer → Integrate with 1Password CLI).
if command -v op >/dev/null; then
  eval "$(op completion zsh)"
  compdef _op op
  [ -f "$HOME/.config/op/plugins.sh" ] && source "$HOME/.config/op/plugins.sh"
fi

# Graphite CLI completions. Auth is per-machine: `gt auth` (token would
# otherwise live in ~/.config/graphite/user_config — never commit that).
# Capture output first so a broken `gt` binary (e.g. a pkg-bundled AUR build
# printing "Pkg: Error reading from file.") can't spam stderr on every startup.
if command -v gt >/dev/null; then
  _gt_completion="$(gt completion 2>/dev/null)" && eval "$_gt_completion"
  unset _gt_completion
fi

# Ghost-text suggestions from history (accept with →) and live command
# syntax highlighting. Paths: Homebrew (macOS) and pacman (Arch).
for _plugin_dir in /opt/homebrew/share /usr/share/zsh/plugins; do
  [ -f "$_plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ] &&
    source "$_plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [ -f "$_plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] &&
    source "$_plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
done
unset _plugin_dir

# pi (coding agent): pin to the Node version where it is installed so
# asdf resolves the binary in any project, even when .tool-versions
# sets a different Node version.
if command -v pi >/dev/null; then
  pi() { ASDF_NODEJS_VERSION=26.2.0 command pi "$@"; }
fi

# Keybinds. autosuggest-* widgets only exist after zsh-autosuggestions loads,
# so these must come after the plugin loop above. Alt-j is left free for the
# sesh picker (see sesh.zsh).
bindkey '^w' autosuggest-execute
bindkey '^e' autosuggest-accept
bindkey '^u' autosuggest-toggle
bindkey 'jj' vi-cmd-mode
bindkey '^k' up-line-or-search
bindkey '^j' down-line-or-search

#!/usr/bin/env bash
#
# Bootstrap a new machine:
#   git clone git@github.com:ctotheameron/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh
#
# Detects macOS vs Arch and uses the appropriate package manager,
# then symlinks configs into $HOME with GNU Stow.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_PACKAGES=(home)

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------------------
# OS detection
# ---------------------------------------------------------------------------
detect_os() {
  case "$(uname -s)" in
  Darwin) echo macos ;;
  Linux)
    if [ -r /etc/os-release ]; then
      # shellcheck disable=SC1091
      . /etc/os-release
      case "${ID:-}${ID_LIKE:-}" in
      *arch*)
        echo arch
        return
        ;;
      esac
    fi
    echo unsupported
    ;;
  *) echo unsupported ;;
  esac
}

# ---------------------------------------------------------------------------
# Package installation
# ---------------------------------------------------------------------------
install_packages_macos() {
  if ! command -v brew >/dev/null; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"

  log "Installing packages from Brewfile"
  brew bundle --file "$DOTFILES_DIR/packages/Brewfile"

  # Machine-local packages (work tooling etc.) — untracked, optional
  if [ -f "$DOTFILES_DIR/packages/Brewfile.local" ]; then
    log "Installing packages from Brewfile.local"
    brew bundle --file "$DOTFILES_DIR/packages/Brewfile.local"
  fi
}

read_pkg_list() {
  # Strip comments and blank lines
  grep -vE '^\s*(#|$)' "$1"
}

install_packages_arch() {
  log "Installing packages with pacman"
  read_pkg_list "$DOTFILES_DIR/packages/arch.txt" |
    sudo pacman -S --needed --noconfirm -

  local aur_helper=""
  if command -v yay >/dev/null; then
    aur_helper=yay
  elif command -v paru >/dev/null; then
    aur_helper=paru
  fi

  if [ -n "$aur_helper" ]; then
    log "Installing AUR packages with $aur_helper"
    read_pkg_list "$DOTFILES_DIR/packages/aur.txt" |
      xargs "$aur_helper" -S --needed --noconfirm
  else
    log "No AUR helper (yay/paru) found; skipping packages/aur.txt"
  fi

  install_fonts_arch
}

# "Liga SFMono Nerd Font" (ghostty's font-family) installs via a Homebrew cask
# on macOS (see Brewfile); Arch has no package, so pull the same files from the
# upstream repo into the user fonts dir. Idempotent.
install_fonts_arch() {
  fc-list 2>/dev/null | grep -qi 'Liga SFMono Nerd Font' && return 0
  log "Installing Liga SFMono Nerd Font"
  local tmp dest
  tmp="$(mktemp -d)"
  git clone --depth 1 \
    https://github.com/shaunsingh/SFMono-Nerd-Font-Ligaturized "$tmp"
  dest="$HOME/.local/share/fonts/LigaSFMonoNerdFont"
  mkdir -p "$dest"
  cp "$tmp"/*.otf "$dest"/
  rm -rf "$tmp"
  fc-cache -f "$dest" >/dev/null
}

# ---------------------------------------------------------------------------
# Stow
# ---------------------------------------------------------------------------
backup_conflicts() {
  # Move any real files that stow would conflict with into a backup dir.
  local backup_dir
  backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

  for pkg in "${STOW_PACKAGES[@]}"; do
    (cd "$DOTFILES_DIR/$pkg" && find . -type f -o -type l) | while read -r rel; do
      rel="${rel#./}"
      local target="$HOME/$rel"
      if [ -e "$target" ] && [ ! -L "$target" ]; then
        mkdir -p "$backup_dir/$(dirname "$rel")"
        mv "$target" "$backup_dir/$rel"
        log "Backed up existing $rel to $backup_dir/$rel"
      fi
    done
  done
}

stow_packages() {
  log "Stowing: ${STOW_PACKAGES[*]}"
  backup_conflicts
  stow -d "$DOTFILES_DIR" -t "$HOME" --restow "${STOW_PACKAGES[@]}"
}

# ---------------------------------------------------------------------------
# Mail (aerc + mbsync + notmuch)
# ---------------------------------------------------------------------------
setup_mail() {
  # mbsync writes here, notmuch indexes it, aerc reads it. mbsync does not
  # create the root store, so make it first. Mail itself stays out of the repo.
  command -v mbsync >/dev/null || return 0

  # One directory per account in ~/.config/isyncrc.
  mkdir -p "$HOME/Mail/icloud" "$HOME/Mail/gmail" "$HOME/Mail/angellist"

  # aerc refuses an accounts.conf that group or other can read. git records
  # only the exec bit, so a fresh clone lands at 644 and aerc stops. The file
  # holds no password of its own, because rbw fetches it at send time.
  local accounts="$HOME/.config/aerc/accounts.conf"
  [ -f "$accounts" ] && chmod 600 "$accounts"

  command -v notmuch >/dev/null && notmuch new >/dev/null 2>&1

  log "Mail ready. Run 'rbw login', then store these Bitwarden items:"
  log "  iCloud app password, Gmail app password, AngelList app password"
}

# ---------------------------------------------------------------------------
# asdf runtimes (.tool-versions)
# ---------------------------------------------------------------------------
bootstrap_asdf_tools() {
  # ~/.tool-versions is stowed, but asdf still needs each plugin added and each
  # version installed before the shims work. Skip this and a shim such as
  # python3 shadows the real binary, then exits 126 with "No version is set for
  # command python3". Idempotent: plugin add and install both no-op when the
  # plugin or the version is already there.
  command -v asdf >/dev/null || return 0

  local tool_versions="$HOME/.tool-versions"
  [ -f "$tool_versions" ] || return 0

  local plugin version installed
  while read -r plugin version _ || [ -n "$plugin" ]
  do
    # skip blank lines and comments
    [ -n "$plugin" ] || continue
    [ "${plugin#\#}" = "$plugin" ] || continue

    asdf plugin add "$plugin" >/dev/null 2>&1 || true

    # asdf list indents each version and marks the active one with '*'
    installed="$(asdf list "$plugin" 2>/dev/null | tr -d ' *' || true)"
    if printf '%s\n' "$installed" | grep -qxF "$version"
    then
      continue
    fi

    log "Installing $plugin $version (asdf)"
    asdf install "$plugin" "$version" ||
      log "Failed: asdf install $plugin $version"
  done <"$tool_versions"

  # Later steps (install_pi needs npm) run in this shell, which never sourced
  # .zshrc — so put the shims on PATH here.
  if [ "${PATH#*"$HOME/.asdf/shims"}" = "$PATH" ]
  then
    export PATH="$HOME/.asdf/shims:$PATH"
  fi
}

# ---------------------------------------------------------------------------
# tmux plugins (tpm)
# ---------------------------------------------------------------------------
bootstrap_tmux_plugins() {
  # tpm and the plugins it manages are gitignored (see .gitignore), so clone
  # tpm and install the plugins declared in tmux.conf. Idempotent.
  command -v tmux >/dev/null || return 0

  local plugins_dir="$HOME/.config/tmux/plugins"
  local tpm_dir="$plugins_dir/tpm"

  if [ ! -d "$tpm_dir" ]; then
    log "Cloning tpm"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  log "Installing tmux plugins (tpm)"
  # install_plugins reads @plugin entries from a running server and needs the
  # plugin path exported (normally done by the tpm run line in tmux.conf).
  export TMUX_PLUGIN_MANAGER_PATH="$plugins_dir/"
  tmux new-session -d -s __tpm_bootstrap 2>/dev/null || true
  "$tpm_dir/bin/install_plugins" || log "Some tmux plugins failed; run <prefix>+I in tmux to retry"
  tmux kill-session -t __tpm_bootstrap 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Claude Code (native installer)
# ---------------------------------------------------------------------------
install_claude_code() {
  # Not in Brewfile/aur.txt on purpose: the native installer self-updates in
  # the background, while brew/AUR installs nag for manual upgrades. The
  # binary lives outside the repo (~/.local/share/claude + ~/.local/bin
  # launcher); this just bootstraps it. Idempotent.
  [ -x "$HOME/.local/bin/claude" ] && return 0
  command -v claude >/dev/null && return 0

  log "Installing Claude Code"
  # Pre-create as the current user — the installer refuses to write the
  # launcher into a directory it can't own (e.g. left root-owned by a
  # previous sudo'd tool install).
  mkdir -p "$HOME/.local/bin"
  curl -fsSL https://claude.ai/install.sh | bash
}

# ---------------------------------------------------------------------------
# pi coding agent (npm global)
# ---------------------------------------------------------------------------
install_pi() {
  # An npm global, so not in Brewfile/arch.txt. Its config is the stowed
  # ~/.pi/agent/settings.json; on first run pi reads the packages list from
  # it and reinstalls any missing extensions itself. Idempotent.
  command -v pi >/dev/null && return 0
  if ! command -v npm >/dev/null; then
    log "Skipping pi: npm not found (asdf install nodejs first, then re-run)"
    return 0
  fi

  log "Installing pi coding agent"
  npm install -g --ignore-scripts @earendil-works/pi-coding-agent
}

# ---------------------------------------------------------------------------
# herdr (agent multiplexer)
# ---------------------------------------------------------------------------
bootstrap_herdr() {
  # herdr itself comes from Brewfile/aur.txt. Its plugin clone and its agent
  # integrations live outside the repo, so restore them here. Idempotent:
  # `plugin install` re-pins the same repo, and each `integration install`
  # rewrites its own hook.
  command -v herdr >/dev/null || return 0

  log "Setting up herdr"

  # ctrl+hjkl navigation across nvim splits and herdr panes. The keys are
  # bound in the stowed config.toml, and nvim/lua/plugins/tmux-navigator.lua
  # holds the editor half.
  herdr plugin install paulbkim-dev/vim-herdr-navigation -y >/dev/null 2>&1 ||
    log "herdr: vim-herdr-navigation install failed (check network)"

  # Report real agent lifecycle state to the sidebar, per agent CLI present.
  for agent in pi claude opencode codex; do
    command -v "$agent" >/dev/null || continue
    herdr integration install "$agent" >/dev/null 2>&1 ||
      log "herdr: $agent integration failed"
  done
}

# ---------------------------------------------------------------------------
# Services (macOS window-manager stack)
# ---------------------------------------------------------------------------
start_wm_services() {
  # Bring up the window-manager stack under launchd so it runs at login.
  # yabai/skhd manage their own LaunchAgents via --start-service; sketchybar
  # and borders use Homebrew services. Idempotent: safe to re-run.
  #
  # brew's bootstrap occasionally loads a job without running it (RunAtLoad
  # doesn't fire, leaving `runs = 0`), so kickstart afterwards to force it —
  # this is what otherwise leaves these "installed but not running".
  log "Starting window-manager services"
  yabai --start-service 2>/dev/null || true
  skhd --start-service 2>/dev/null || true
  for svc in sketchybar borders; do
    brew services start "$svc" >/dev/null 2>&1 || true
    launchctl kickstart -p "gui/$(id -u)/homebrew.mxcl.${svc}" >/dev/null 2>&1 || true
  done
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  local os
  os="$(detect_os)"

  case "$os" in
  macos)
    install_packages_macos
    # macOS-only configs (sketchybar, yabai, skhd, borders) — tracked for
    # all machines, but only stowed on macOS
    STOW_PACKAGES+=(macos)
    ;;
  arch)
    install_packages_arch
    # Linux/Hyprland-only configs (hypr, ghostty Linux overrides) — tracked
    # for all machines, but only stowed on Arch
    STOW_PACKAGES+=(arch)
    ;;
  *)
    echo "Unsupported OS. This script supports macOS and Arch." >&2
    exit 1
    ;;
  esac

  stow_packages

  # asdf plugins/versions for the stowed ~/.tool-versions (the runtimes
  # themselves are not tracked, so a fresh machine has shims but no versions)
  bootstrap_asdf_tools

  # tmux plugins (tpm clones + the plugins it manages are gitignored)
  bootstrap_tmux_plugins

  install_claude_code
  install_pi

  # herdr plugin + agent integrations (both live outside the repo)
  bootstrap_herdr

  setup_mail

  # Build bat's theme cache so custom themes (Catppuccin) are available
  command -v bat >/dev/null && bat cache --build >/dev/null

  # macOS: expose the 1Password SSH agent at the same path Linux uses,
  # so ~/.ssh/config works on both (requires SSH agent enabled in the app)
  if [ "$(detect_os)" = "macos" ]; then
    start_wm_services

    mkdir -p "$HOME/.1password"
    ln -sf "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" \
      "$HOME/.1password/agent.sock"

    mkdir -p "$HOME/Projects"

    # process-compose reads Application Support on macOS (no ~/.config
    # fallback); point it at the stowed XDG-style config instead. Replace
    # any real dir process-compose may have auto-created (ln won't).
    pc_dir="$HOME/Library/Application Support/process-compose"
    [ -L "$pc_dir" ] || rm -rf "$pc_dir"
    ln -sfn "$HOME/.config/process-compose" "$pc_dir"

    # aerc reads ~/Library/Preferences on macOS and never looks at ~/.config,
    # so point it at the stowed config. It copies its own defaults in on first
    # run, so replace any real dir it made (ln alone will not).
    aerc_dir="$HOME/Library/Preferences/aerc"
    [ -L "$aerc_dir" ] || rm -rf "$aerc_dir"
    ln -sfn "$HOME/.config/aerc" "$aerc_dir"
  fi

  log "Done. Restart your shell."
}

main "$@"

#!/usr/bin/env bash
#
# Bootstrap a new machine:
#   git clone git@github.com:<you>/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh
#
# Detects macOS vs Arch/Omarchy and uses the appropriate package manager,
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
          *arch*) echo arch; return ;;
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
# Main
# ---------------------------------------------------------------------------
main() {
  local os
  os="$(detect_os)"

  case "$os" in
    macos) install_packages_macos ;;
    arch) install_packages_arch ;;
    *)
      echo "Unsupported OS. This script supports macOS and Arch/Omarchy." >&2
      exit 1
      ;;
  esac

  stow_packages

  # Build bat's theme cache so custom themes (Catppuccin) are available
  command -v bat >/dev/null && bat cache --build >/dev/null

  # macOS: expose the 1Password SSH agent at the same path Linux uses,
  # so ~/.ssh/config works on both (requires SSH agent enabled in the app)
  if [ "$(detect_os)" = "macos" ]; then
    mkdir -p "$HOME/.1password"
    ln -sf "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" \
      "$HOME/.1password/agent.sock"

    # process-compose reads Application Support on macOS (no ~/.config
    # fallback); point it at the stowed XDG-style config instead. Replace
    # any real dir process-compose may have auto-created (ln won't).
    pc_dir="$HOME/Library/Application Support/process-compose"
    [ -L "$pc_dir" ] || rm -rf "$pc_dir"
    ln -sfn "$HOME/.config/process-compose" "$pc_dir"
  fi

  log "Done. Restart your shell."
}

main "$@"

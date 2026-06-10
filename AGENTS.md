# AGENTS.md — how this dotfiles repo works

Instructions for AI agents (and future humans) making changes here.

## What this repo is

A GNU Stow–managed dotfiles repo. `home/` is a single stow package that
mirrors `$HOME`; running `stow home` from the repo root (target comes from
`.stowrc`) symlinks everything into place. Because configs are symlinked,
**edits to live configs (e.g. `~/.zshrc`, `~/.config/nvim/...`) land directly
in this repo** — expect `git status` to pick up ride-along changes the user
made between requests. Don't be surprised by them, and don't silently revert
them.

```txt
home/               stow package mirroring $HOME (the actual dotfiles)
macos/              stow package for macOS-only configs (stowed on Darwin only)
packages/Brewfile   macOS packages (brew bundle)
packages/arch.txt   Arch official repo packages (pacman)
packages/aur.txt    Arch AUR packages (yay/paru)
scripts/            maintenance helpers (e.g. export-btt.sh)
btt/                BetterTouchTool preset exports (JSON)
install.sh          bootstrap: detects OS, installs packages, stows, post-setup
.stowrc             makes plain `stow home` target $HOME
```

The owner runs macOS and Arch (Omarchy). Both must keep working.

## Rules for every change

### 1. Support macOS + Arch wherever possible

- Shell config must degrade gracefully: guard tool integrations with
  `command -v <tool> >/dev/null` and path checks (see
  `home/.config/zsh/tools.zsh` for the established pattern). A fresh machine
  with zero packages installed must still get a working shell.
- No hardcoded `/Users/<name>` or `/opt/homebrew` without a guard. Use
  `$HOME`, and check directories exist before adding them to `fpath`/`PATH`.
- Prefer cross-platform paths (e.g. `~/.1password/agent.sock`, which
  install.sh symlinks on macOS to match Linux).
- macOS-only configs (yabai, skhd, sketchybar, borders) live in the `macos/`
  stow package, which install.sh only stows on Darwin. Track macOS-only
  things there — never in `home/`, which must stay cross-platform. BTT is
  the exception (preset exports in `btt/`, see below).
- Paths that differ per OS and can't be unified get a comment noting the
  other OS's value (e.g. `op-ssh-sign` in `home/.gitconfig`) and can be
  overridden via the machine-local escape hatches (below).

### 2. Package installs must be replayable via install.sh

Installing something with `brew install` for the user is fine, but it is
**not done** until it's recorded:

- macOS: add to `packages/Brewfile` (include the `tap` line if needed).
- Arch: add the equivalent to `packages/arch.txt` (official repos) or
  `packages/aur.txt` (AUR). Verify real package names (AUR RPC:
  `https://aur.archlinux.org/rpc/?v=5&type=search&arg=<name>`); note a
  fallback in a comment if no Arch equivalent exists.
- Anything needing post-install setup (cache builds, symlinks, completions)
  goes in `install.sh` — it must stay idempotent (`--needed`, `--restow`,
  `ln -sf`, etc.), safe to re-run on an existing machine.
- One-time, non-automatable steps (auth, GUI toggles) go in the README's
  "One-time auth on a new machine" section instead.

### 3. Commit (and push) every logical change

- After each completed change: `git add` the relevant files, commit with a
  concise imperative message, and push to `origin main`.
- Inspect `git status` first — unrelated live-config edits may be pending.
  Including them is usually fine (that's the workflow), but don't bury big
  unrelated changes in a misleading commit message.
- Never amend or force-push.

### 4. Secrets and machine-local state stay out of git

- **Never commit credentials**: `gh` hosts.yml, Graphite `user_config`
  (auth token), `op` config, SSH private keys. Check `.gitignore` before
  tracking a new tool's config dir, and audit configs for embedded tokens
  before `git add`.
- Work-specific config lives in gitignored files: `home/.config/zsh/work.zsh`,
  and identity overrides via `~/.gitconfig.local` (untracked, included last).
- Machine-local state is not config: plugin clones (tmux `plugins/`),
  caches, `lazygit state.yml`, atuin's database, `~/.local/state/...` —
  gitignore or leave outside the repo. The rule of thumb: if a fresh machine
  should *regenerate* it, don't track it.

### 5. Verify before declaring done

Match the verification to what changed:

- zsh: `zsh -ic 'echo ok'` (plus check the specific alias/widget/completion).
- tmux: `tmux source-file ~/.config/tmux/tmux.conf`, then inspect with
  `tmux show -g <option>` / `tmux list-keys`. Note: `source-file` only adds —
  removed options/binds must be explicitly `set -gu` / `unbind` on the live
  server.
- Layout/TUI behavior: test in a disposable detached session
  (`tmux new-session -d -s test ...`, `capture-pane`, then `kill-session`).
- ghostty: `ghostty +validate-config`.
- nvim: headless checks (`nvim --headless -c ... -c q`).
- stow: after adding files at new paths, `stow --restow home` and `ls -la`
  the target to confirm the symlink.

### 6. Established conventions to follow

- zsh is modular: `~/.zshrc` stays minimal and sources `~/.config/zsh/*.zsh`.
  Tool integrations belong in `tools.zsh`, not `.zshrc`.
- Theme is Catppuccin (Mocha for terminal-rendered tools; tmux currently
  macchiato by owner's choice). Match it when theming something new.
- Comments in configs should explain *what a binding does* in plain language
  (see `home/.config/ghostty/config` for the documentation style).
- sesh per-project layouts: `.sesh` scripts generated from
  `home/.config/sesh/sesh.example` — keep the `# --- layout` marker intact;
  `sesh-startup` depends on it.
- BTT changes: edit via scripting/UI, then `scripts/export-btt.sh` and commit
  the exported preset.

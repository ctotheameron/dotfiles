# dotfiles

Configs managed with [GNU Stow](https://www.gnu.org/software/stow/). Works on
macOS (Homebrew) and Arch/Omarchy (pacman + AUR).

## New machine

```sh
git clone git@github.com:ctotheameron/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

The script detects the OS, installs packages with the appropriate package
manager (`brew bundle` on macOS, `pacman`/`yay` on Arch), backs up any
conflicting files to `~/.dotfiles-backup/`, and symlinks everything in
`home/` into `$HOME`.

## Layout

```
home/              stow package mirroring $HOME (shared across OSes)
macos/             stow package for macOS-only configs (sketchybar, yabai,
                   skhd, borders) — only stowed on macOS
packages/Brewfile  macOS packages (brew bundle dump)
packages/arch.txt  Arch official repo packages
packages/aur.txt   AUR packages
install.sh         bootstrap script
```

## One-time auth on a new machine

Secrets are never tracked, so after `install.sh` run:

- `gh auth login` — GitHub CLI (token lives in `~/.config/gh/hosts.yml`)
- `gt auth` — Graphite (token lives in `~/.config/graphite/user_config`)
- 1Password app → Settings → Developer → "Integrate with 1Password CLI",
  then `op plugin init <tool>` for any shell plugins you want
- `atuin import auto` — seed shell history (optionally `atuin login` for sync)
- `pi` — authenticate on first run (creds land in `~/.pi/agent/auth.json`,
  never tracked); it auto-installs its extension packages from the stowed
  `~/.pi/agent/settings.json`
- Recreate `~/.config/zsh/work.zsh` if it's a work machine

## BetterTouchTool (macOS)

BTT stores config in versioned SQLite databases, so it can't be stowed.
Instead, presets are exported as JSON into `macos/btt/` (excluded from
stowing via `macos/.stow-local-ignore`):

- After changing BTT config: `scripts/export-btt.sh`, then commit.
- On a new machine (after `brew bundle` installs BTT):
  `open macos/btt/*.bttpreset` and confirm the import prompt.

## Day-to-day

- Add a new config: move it under `home/` (mirroring its path in `$HOME`),
  then run `stow -d ~/dotfiles -t ~ --restow home`.
- Update the Brewfile after installing something:
  `brew bundle dump --file ~/dotfiles/packages/Brewfile --force`
- Never commit `~/.config/gh/hosts.yml` (gitignored — it contains your
  GitHub token).

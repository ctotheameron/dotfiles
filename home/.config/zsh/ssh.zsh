# SSH agent wiring — Bitwarden desktop serves personal keys (git commit
# signing). Socket path is the same on macOS and Linux (non-flatpak).
# Falls through silently if Bitwarden isn't running.
if [[ -S "$HOME/.bitwarden-ssh-agent.sock" ]]; then
  export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
fi

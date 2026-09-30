# SSH agent wiring — Bitwarden desktop serves SSH keys (auth + git commit
# signing). The socket path is the same on macOS and Linux (non-flatpak).
#
# ~/.ssh/config already sets IdentityAgent for ssh itself; this export covers
# everything else that reads SSH_AUTH_SOCK — notably agent forwarding into
# Docker/OrbStack containers (bundler cloning private git gems).
#
# Does nothing if the agent is off. Trap: the socket file can outlive the
# agent. If ssh says "Connection refused", turn the SSH agent off and on in
# Bitwarden → Settings.
if [[ -S "$HOME/.bitwarden-ssh-agent.sock" ]]; then
  export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
fi

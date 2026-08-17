# SSH agent wiring — 1Password serves SSH keys (auth + git commit signing).
# ~/.1password/agent.sock is a symlink on macOS (created by install.sh) and
# the native socket path on Linux, so this works on both.
#
# ~/.ssh/config already sets IdentityAgent for ssh itself; this export covers
# everything else that reads SSH_AUTH_SOCK — notably agent forwarding into
# Docker/OrbStack containers (bundler cloning private git gems).
# Falls through silently if 1Password isn't running.
if [[ -S "$HOME/.1password/agent.sock" ]]; then
  export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
fi

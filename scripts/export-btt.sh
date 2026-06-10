#!/usr/bin/env bash
#
# Export all BetterTouchTool presets to btt/ so they can be committed.
# Run this after changing BTT config, then commit the result.
# Restore on a new machine: open btt/<name>.bttpreset (BTT prompts to import).

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$DOTFILES_DIR/btt"
mkdir -p "$OUT_DIR"

if ! osascript -e 'tell application "System Events" to exists process "BetterTouchTool"' | grep -q true; then
  echo "BetterTouchTool is not running; start it and re-run." >&2
  exit 1
fi

# Preset names live in BTT's sqlite store; find the newest data store file.
DB="$(ls -t "$HOME/Library/Application Support/BetterTouchTool"/btt_data_store.version_* 2>/dev/null |
  grep -vE '(-shm|-wal|backup)' | head -1)"

presets="$(sqlite3 "$DB" \
  "select distinct ZPRESETNAME from ZBTTBASEENTITY where ZPRESETNAME is not null" 2>/dev/null || true)"
[ -n "$presets" ] || presets="Default"

while IFS= read -r preset; do
  out="$OUT_DIR/$preset.bttpreset"
  osascript -e "tell application \"BetterTouchTool\" to export_preset \"$preset\" outputPath \"$out\"" >/dev/null
  echo "Exported: $out"
done <<<"$presets"

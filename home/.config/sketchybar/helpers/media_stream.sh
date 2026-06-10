#!/usr/bin/env bash
#
# Streams now-playing info into sketchybar.
#
# Workaround for macOS 15.4+ locking down the private MediaRemote framework,
# which broke sketchybar's built-in media_change event and nowplaying-cli.
# Uses media-control (https://github.com/ungive/media-control), which reads
# MediaRemote through /usr/bin/perl (an Apple-entitled platform binary).
#
# Spawned from items/media.lua on sketchybar (re)load. Each update fires:
#   sketchybar --trigger media_update APP=... STATE=... TITLE=... ARTIST=... ARTWORK=...

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

command -v media-control >/dev/null || exit 1
command -v jq >/dev/null || exit 1

ARTWORK_DIR="${TMPDIR:-/tmp}sketchybar_media"
mkdir -p "$ARTWORK_DIR"

media-control stream --no-diff | while IFS= read -r line; do
  payload=$(jq -c '.payload' <<<"$line" 2>/dev/null) || continue
  [ -z "$payload" ] || [ "$payload" = "null" ] && payload="{}"

  # Cache artwork to a content-addressed file so sketchybar reloads it on
  # track change (it won't re-read an unchanged path).
  artwork_file=""
  artwork=$(jq -r '.artworkData // empty' <<<"$payload")
  if [ -n "$artwork" ]; then
    hash=$(jq -r '(.bundleIdentifier // "") + "|" + (.artist // "") + "|" + (.album // "") + "|" + (.title // "")' <<<"$payload" | md5 -q)
    artwork_file="$ARTWORK_DIR/cover_$hash"
    if [ ! -f "$artwork_file" ]; then
      base64 -d <<<"$artwork" >"$artwork_file" 2>/dev/null
      # Full-res covers (600px+) render huge; shrink to a bar-sized thumbnail.
      sips -Z 128 "$artwork_file" >/dev/null 2>&1
    fi
  fi

  app=$(jq -r '{"com.apple.Music": "Music", "com.spotify.client": "Spotify"}[.bundleIdentifier] // .bundleIdentifier // ""' <<<"$payload")
  title=$(jq -r '.title // ""' <<<"$payload")
  artist=$(jq -r '.artist // ""' <<<"$payload")
  state=$(jq -r 'if .playing == true then "playing" else "paused" end' <<<"$payload")

  sketchybar --trigger media_update \
    APP="$app" \
    STATE="$state" \
    TITLE="$title" \
    ARTIST="$artist" \
    ARTWORK="$artwork_file"
done

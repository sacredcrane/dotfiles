#!/bin/sh

state="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"

volume="$(
  printf '%s\n' "$state" |
    awk '{ printf "%d", $2 * 100 }'
)"

case "$volume" in
'' | *[!0-9]*) volume=0 ;;
esac

case "$state" in
*MUTED*) muted=true ;;
*) muted=false ;;
esac

jq -cn \
  --argjson volume "$volume" \
  --argjson muted "$muted" \
  '{volume: $volume, muted: $muted}'

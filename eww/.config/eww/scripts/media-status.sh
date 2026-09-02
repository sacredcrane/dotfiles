#!/bin/sh

empty_state() {
  jq -cn '{active: false, playing: false, title: "NO ACTIVE PLAYER", artist: "Start playback to wake the dashboard", album: "", elapsed: "0:00", duration: "0:00", progress: 0}'
}

command -v playerctl >/dev/null 2>&1 || {
  empty_state
  exit
}

status="$(playerctl status 2>/dev/null)" || {
  empty_state
  exit
}

title="$(playerctl metadata xesam:title 2>/dev/null)"
artist="$(playerctl metadata xesam:artist 2>/dev/null)"
album="$(playerctl metadata xesam:album 2>/dev/null)"
position="$(playerctl position 2>/dev/null)"
length="$(playerctl metadata mpris:length 2>/dev/null)"

position="${position%%.*}"
case "$position" in '' | *[!0-9]*) position=0 ;; esac
case "$length" in '' | *[!0-9]*) length=0 ;; esac
length=$((length / 1000000))

progress=0
if [ "$length" -gt 0 ]; then
  progress=$((position * 100 / length))
  [ "$progress" -gt 100 ] && progress=100
fi

format_time() {
  printf '%d:%02d' "$(( $1 / 60 ))" "$(( $1 % 60 ))"
}

[ -n "$title" ] || title="UNKNOWN TRACK"
[ -n "$artist" ] || artist="Unknown artist"

playing=false
[ "$status" = "Playing" ] && playing=true

jq -cn \
  --arg title "$title" \
  --arg artist "$artist" \
  --arg album "$album" \
  --arg elapsed "$(format_time "$position")" \
  --arg duration "$(format_time "$length")" \
  --argjson playing "$playing" \
  --argjson progress "$progress" \
  '{active: true, playing: $playing, title: $title, artist: $artist, album: $album, elapsed: $elapsed, duration: $duration, progress: $progress}'

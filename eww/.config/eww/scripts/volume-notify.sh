#!/bin/sh

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
id_file="$runtime_dir/volume-osd-$(id -u).id"
lock_file="$runtime_dir/volume-osd-$(id -u).lock"
state="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"
value="$(printf '%s\n' "$state" | awk '{ printf "%d", $2 * 100 }')"

case "$value" in
'' | *[!0-9]*) exit 1 ;;
esac

case "$state" in
*MUTED*)
  display_value=0
  body="Muted"
  icon=audio-volume-muted-symbolic
  ;;
*)
  display_value=$value
  body="${value}%"
  if [ "$value" -lt 34 ]; then
    icon=audio-volume-low-symbolic
  elif [ "$value" -lt 67 ]; then
    icon=audio-volume-medium-symbolic
  else
    icon=audio-volume-high-symbolic
  fi
  ;;
esac

exec 9>"$lock_file"
flock 9

notification_id=""

if [ -r "$id_file" ]; then
  IFS= read -r notification_id <"$id_file"
fi

case "$notification_id" in
'' | *[!0-9]*) notification_id=0 ;;
esac

notification_id="$(
  notify-send \
    --print-id \
    --replace-id="$notification_id" \
    --app-name=volume-osd \
    --urgency=low \
    --expire-time=1200 \
    --hint="int:value:$display_value" \
    --icon="$icon" \
    "Volume" \
    "$body"
)"

case "$notification_id" in
'' | *[!0-9]*) exit 1 ;;
esac

printf '%s\n' "$notification_id" >"$id_file"

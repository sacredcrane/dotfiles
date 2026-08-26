#!/bin/sh

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
id_file="$runtime_dir/brightness-osd-$(id -u).id"
lock_file="$runtime_dir/brightness-osd-$(id -u).lock"

case "$1" in
up)
  # Void's acpid handler applies 5%; this adds the remaining percentage point.
  sleep 0.05
  brightnessctl --class=backlight set +1% >/dev/null
  ;;
down)
  sleep 0.05
  brightnessctl --class=backlight set 1%- >/dev/null
  ;;
*) exit 2 ;;
esac

value="$(
  brightnessctl --class=backlight -m 2>/dev/null |
    awk -F, 'NR == 1 { gsub(/%/, "", $4); print $4 }'
)"

case "$value" in
'' | *[!0-9]*) exit 1 ;;
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
    --app-name=brightness-osd \
    --urgency=low \
    --expire-time=1200 \
    --hint="int:value:$value" \
    --icon=display-brightness-symbolic \
    "Brightness" \
    "${value}%"
)"

case "$notification_id" in
'' | *[!0-9]*) exit 1 ;;
esac

printf '%s\n' "$notification_id" >"$id_file"

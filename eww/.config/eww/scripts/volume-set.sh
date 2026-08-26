#!/bin/sh

value="$1"

if ! awk -v value="$value" 'BEGIN {
  exit !(value ~ /^[0-9]+([.][0-9]+)?$/ && value >= 0 && value <= 100)
}'; then
  exit 2
fi

wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ "${value}%" >/dev/null

exec "$HOME/.config/eww/scripts/volume-notify.sh"

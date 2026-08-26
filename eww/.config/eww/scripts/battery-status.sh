#!/bin/sh

battery=""

for supply in /sys/class/power_supply/*; do
  [ -d "$supply" ] || continue
  [ "$(cat "$supply/type" 2>/dev/null)" = "Battery" ] || continue
  battery="$supply"
  break
done

if [ -z "$battery" ]; then
  jq -cn '{capacity: 0, status: "Unavailable", icon: "󰂑", class: "unavailable"}'
  exit 0
fi

capacity="$(cat "$battery/capacity" 2>/dev/null)"
status="$(cat "$battery/status" 2>/dev/null)"

case "$capacity" in
'' | *[!0-9]*) capacity=0 ;;
esac

[ -n "$status" ] || status="Unknown"

if [ "$capacity" -ge 90 ]; then
  icon=""
elif [ "$capacity" -ge 65 ]; then
  icon=""
elif [ "$capacity" -ge 40 ]; then
  icon=""
elif [ "$capacity" -ge 15 ]; then
  icon=""
else
  icon=""
fi

if [ "$status" = "Charging" ]; then
  class="charging"
elif [ "$capacity" -le 15 ]; then
  class="low"
elif [ "$capacity" -le 35 ]; then
  class="medium"
else
  class="good"
fi

jq -cn \
  --argjson capacity "$capacity" \
  --arg status "$status" \
  --arg icon "$icon" \
  --arg class "$class" \
  '{capacity: $capacity, status: $status, icon: $icon, class: $class}'

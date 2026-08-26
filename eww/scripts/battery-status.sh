#!/bin/sh

BAT="/sys/class/power_supply/BAT0"

capacity="$(cat "$BAT/capacity" 2>/dev/null || echo 0)"
status="$(cat "$BAT/status" 2>/dev/null || echo Unknown)"

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

printf '{"capacity":%s,"status":"%s","icon":"%s","class":"%s"}\n' \
  "$capacity" "$status" "$icon" "$class"

#!/bin/sh

case "$1" in
up)
  brightnessctl --class=backlight set +5% >/dev/null
  ;;
down)
  brightnessctl --class=backlight set 5%- >/dev/null
  ;;
esac

#!/bin/sh

case "$1" in
up)
  wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ >/dev/null
  ;;
down)
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- >/dev/null
  ;;
esac

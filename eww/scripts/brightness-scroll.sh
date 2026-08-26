#!/bin/sh

case "$1" in
up)
  brightnessctl set +5%
  ;;
down)
  brightnessctl set 5%-
  ;;
esac

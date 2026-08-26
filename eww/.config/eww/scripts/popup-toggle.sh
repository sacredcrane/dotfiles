#!/bin/sh

target="$1"
popups="calendar-popup power-popup session-popup tray-popup volume-popup network-popup bluetooth-popup vpn-popup"

case " $popups " in
*" $target "*) ;;
*) exit 2 ;;
esac

if eww active-windows 2>/dev/null |
  awk -F ': ' -v target="$target" '$2 == target { found=1 } END { exit !found }'; then
  eww close "$target"
  exit 0
fi

for popup in $popups; do
  eww close "$popup" >/dev/null 2>&1 || true
done

case "$target" in
network-popup) "$HOME/.config/eww/scripts/wifi-scan.sh" >/dev/null 2>&1 & ;;
bluetooth-popup) "$HOME/.config/eww/scripts/bluetooth-action.sh" scan >/dev/null 2>&1 & ;;
esac

eww open "$target"

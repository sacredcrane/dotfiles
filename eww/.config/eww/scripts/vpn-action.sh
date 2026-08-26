#!/bin/sh

action="$1"
interface="my_pc"
config="$HOME/Documents/my_pc.conf"
awg_quick="/usr/local/bin/awg-quick"

is_active() {
  ip link show dev "$interface" >/dev/null 2>&1
}

case "$action" in
connect)
  is_active && exit 0

  if doas -n "$awg_quick" up "$config" >/dev/null 2>&1; then
    notify-send "VPN" "my_pc connected"
  else
    notify-send "VPN" "Connection failed; check the doas rule"
    exit 1
  fi
  ;;
disconnect)
  is_active || exit 0

  if doas -n "$awg_quick" down "$config" >/dev/null 2>&1; then
    notify-send "VPN" "my_pc disconnected"
  else
    notify-send "VPN" "Disconnect failed; check the doas rule"
    exit 1
  fi
  ;;
*) exit 2 ;;
esac

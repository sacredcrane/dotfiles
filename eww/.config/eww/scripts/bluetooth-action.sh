#!/bin/sh

action="$1"
address="${2:-}"

valid_address() {
  printf '%s\n' "$1" |
    awk 'BEGIN { IGNORECASE=1 } /^[0-9a-f]{2}(:[0-9a-f]{2}){5}$/ { valid=1 } END { exit !valid }'
}

case "$action" in
power-toggle)
  if bluetoothctl show 2>/dev/null | awk '/Powered: yes/ { on=1 } END { exit !on }'; then
    bluetoothctl power off >/dev/null
  else
    bluetoothctl power on >/dev/null
  fi
  ;;
scan)
  bluetoothctl power on >/dev/null 2>&1 || exit 1
  bluetoothctl --timeout 15 scan on >/dev/null 2>&1 || true
  ;;
pair | connect | disconnect | remove)
  valid_address "$address" || exit 2

  case "$action" in
  pair)
    bluetoothctl power on >/dev/null 2>&1 || exit 1
    bluetoothctl pairable on >/dev/null 2>&1 || exit 1
    trap 'bluetoothctl pairable off >/dev/null 2>&1 || true' EXIT

    if bluetoothctl --agent NoInputNoOutput --timeout 60 pair "$address" >/dev/null 2>&1 &&
      bluetoothctl trust "$address" >/dev/null 2>&1 &&
      bluetoothctl connect "$address" >/dev/null 2>&1; then
      notify-send "Bluetooth" "Device paired and connected"
    else
      notify-send "Bluetooth" "Pairing failed; the device may require a passkey"
      exit 1
    fi
    ;;
  connect)
    bluetoothctl connect "$address" >/dev/null 2>&1 || {
      notify-send "Bluetooth" "Connection failed"
      exit 1
    }
    ;;
  disconnect)
    bluetoothctl disconnect "$address" >/dev/null 2>&1 || exit 1
    ;;
  remove)
    bluetoothctl remove "$address" >/dev/null 2>&1 || exit 1
    ;;
  esac
  ;;
*) exit 2 ;;
esac

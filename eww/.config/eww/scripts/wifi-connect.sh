#!/bin/sh

id="$1"

iface="$(
  iw dev 2>/dev/null |
    awk '$1 == "Interface" { print $2; exit }'
)"

[ -n "$iface" ] || exit 1

case "$id" in
'' | *[!0-9]*) exit 2 ;;
esac

wpa_cli -i "$iface" list_networks 2>/dev/null |
  awk -F '\t' -v id="$id" 'NR > 1 && $1 == id { found=1 } END { exit !found }' ||
  exit 2

wpa_cli -i "$iface" enable_network "$id" >/dev/null &&
  wpa_cli -i "$iface" select_network "$id" >/dev/null &&
  wpa_cli -i "$iface" save_config >/dev/null

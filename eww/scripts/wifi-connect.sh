#!/bin/sh

ssid="$1"

iface="$(
  iw dev 2>/dev/null |
    awk '$1 == "Interface" { print $2; exit }'
)"

[ -n "$iface" ] || exit 1
[ -n "$ssid" ] || exit 1

id="$(
  wpa_cli -i "$iface" list_networks 2>/dev/null |
    tail -n +2 |
    awk -F '\t' -v ssid="$ssid" '
            $2 == ssid {
                print $1
                exit
            }
        '
)"

[ -n "$id" ] || exit 2

wpa_cli -i "$iface" enable_network "$id" >/dev/null &&
  wpa_cli -i "$iface" select_network "$id" >/dev/null

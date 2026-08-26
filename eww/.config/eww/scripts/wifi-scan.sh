#!/bin/sh

iface="$(
  iw dev 2>/dev/null |
    awk '$1 == "Interface" { print $2; exit }'
)"

[ -n "$iface" ] || exit 1

wpa_cli -i "$iface" scan >/dev/null 2>&1

#!/bin/sh

bssid="$1"

if ! printf '%s\n' "$bssid" |
  awk 'BEGIN { IGNORECASE=1 } /^[0-9a-f]{2}(:[0-9a-f]{2}){5}$/ { valid=1 } END { exit !valid }'; then
  exit 2
fi

iface="$(
  iw dev 2>/dev/null |
    awk '$1 == "Interface" { print $2; exit }'
)"

[ -n "$iface" ] || exit 1

network="$(
  wpa_cli -i "$iface" scan_results 2>/dev/null |
    awk -F '\t' -v bssid="$bssid" '
      BEGIN { IGNORECASE=1 }
      NR > 1 && $1 == bssid && NF >= 5 {
        print $4 "\t" $5
        exit
      }
    '
)"

[ -n "$network" ] || exit 3

flags="${network%%	*}"
ssid="${network#*	}"

case "$flags" in
*SAE*) security="sae" ;;
*WPA* | *RSN*) security="wpa" ;;
*) security="open" ;;
esac

password=""

if [ "$security" != "open" ]; then
  if ! password="$(
    fuzzel \
      --dmenu \
      --prompt-only="Wi-Fi password: " \
      --password \
      --namespace=wifi-password \
      --layer=overlay \
      --log-level=none \
      --log-no-syslog
  )"; then
    exit 0
  fi

  length=${#password}

  if [ "$security" = "wpa" ]; then
    [ "$length" -ge 8 ] && [ "$length" -le 63 ] || {
      notify-send "Wi-Fi" "WPA password must contain 8-63 characters"
      exit 4
    }
  elif [ "$length" -lt 1 ] || [ "$length" -gt 63 ]; then
    notify-send "Wi-Fi" "SAE password must contain 1-63 characters"
    exit 4
  fi
fi

id="$(wpa_cli -i "$iface" add_network 2>/dev/null)"

case "$id" in
'' | *[!0-9]*) exit 5 ;;
esac

configured=false

cleanup() {
  if [ "$configured" != true ]; then
    wpa_cli -i "$iface" remove_network "$id" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT
trap 'exit 1' HUP INT TERM

ssid_hex="$(printf '%s' "$ssid" | od -An -tx1 | tr -d ' \n')"
wpa_cli -i "$iface" set_network "$id" ssid "$ssid_hex" >/dev/null || exit 6
wpa_cli -i "$iface" set_network "$id" bssid "$bssid" >/dev/null || exit 6

case "$security" in
open)
  wpa_cli -i "$iface" set_network "$id" key_mgmt NONE >/dev/null || exit 6
  ;;
wpa)
  psk="$(
    printf '%s\n' "$password" |
      wpa_passphrase "$ssid" 2>/dev/null |
      awk -F= '/^[[:space:]]*psk=[[:xdigit:]]{64}$/ { gsub(/[[:space:]]/, "", $2); print $2; exit }'
  )"
  [ -n "$psk" ] || exit 6
  {
    printf 'set_network %s key_mgmt WPA-PSK\n' "$id"
    printf 'set_network %s psk %s\n' "$id" "$psk"
  } | wpa_cli -i "$iface" >/dev/null 2>&1
  ;;
sae)
  escaped_password="$(
    printf '%s' "$password" |
      sed 's/\\/\\\\/g; s/"/\\"/g'
  )"
  {
    printf 'set_network %s key_mgmt SAE\n' "$id"
    printf 'set_network %s ieee80211w 2\n' "$id"
    printf 'set_network %s sae_password "%s"\n' "$id" "$escaped_password"
  } | wpa_cli -i "$iface" >/dev/null 2>&1
  ;;
esac

password=""
escaped_password=""
psk=""

wpa_cli -i "$iface" enable_network "$id" >/dev/null || exit 7
wpa_cli -i "$iface" select_network "$id" >/dev/null || exit 7
wpa_cli -i "$iface" save_config >/dev/null || exit 8

configured=true
notify-send "Wi-Fi" "Connection profile saved"

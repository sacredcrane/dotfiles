#!/bin/sh

wifi_iface="$(
  iw dev 2>/dev/null |
    awk '$1 == "Interface" { print $2; exit }'
)"

wifi_connected=false
wifi_ssid=""
wifi_signal=0
wifi_ip=""

if [ -n "$wifi_iface" ]; then
  status="$(wpa_cli -i "$wifi_iface" status 2>/dev/null)"

  state="$(
    printf '%s\n' "$status" |
      awk -F= '$1 == "wpa_state" { print $2 }'
  )"

  if [ "$state" = "COMPLETED" ]; then
    wifi_connected=true

    wifi_ssid="$(
      printf '%s\n' "$status" |
        awk -F= '$1 == "ssid" {
                    sub(/^ssid=/, "")
                    print
                }'
    )"

    wifi_ip="$(
      ip -4 -o addr show dev "$wifi_iface" 2>/dev/null |
        awk '{ split($4, a, "/"); print a[1]; exit }'
    )"

    wifi_signal="$(
      iw dev "$wifi_iface" link 2>/dev/null |
        awk '/signal:/ { printf "%.0f", $2 }'
    )"

    [ -n "$wifi_signal" ] || wifi_signal=-100
  fi
fi

ethernet_iface=""

for path in /sys/class/net/*; do
  iface="$(basename "$path")"

  [ "$iface" = "lo" ] && continue
  [ "$iface" = "$wifi_iface" ] && continue

  # Только реальные hardware interfaces.
  [ -e "$path/device" ] || continue

  # Wi-Fi сюда не попадает.
  [ -d "$path/wireless" ] && continue

  # Ethernet-like interface.
  [ "$(cat "$path/type" 2>/dev/null)" = "1" ] || continue

  ethernet_iface="$iface"
  break
done

ethernet_connected=false
ethernet_ip=""

if [ -n "$ethernet_iface" ]; then
  carrier="$(
    cat "/sys/class/net/$ethernet_iface/carrier" 2>/dev/null ||
      echo 0
  )"

  if [ "$carrier" = "1" ]; then
    ethernet_connected=true

    ethernet_ip="$(
      ip -4 -o addr show dev "$ethernet_iface" 2>/dev/null |
        awk '{ split($4, a, "/"); print a[1]; exit }'
    )"
  fi
fi

jq -cn \
  --argjson wifi_connected "$wifi_connected" \
  --arg wifi_iface "$wifi_iface" \
  --arg wifi_ssid "$wifi_ssid" \
  --argjson wifi_signal "$wifi_signal" \
  --arg wifi_ip "$wifi_ip" \
  --argjson ethernet_connected "$ethernet_connected" \
  --arg ethernet_iface "$ethernet_iface" \
  --arg ethernet_ip "$ethernet_ip" \
  '{
        wifi: {
            connected: $wifi_connected,
            interface: $wifi_iface,
            ssid: $wifi_ssid,
            signal: $wifi_signal,
            ip: $wifi_ip
        },
        ethernet: {
            connected: $ethernet_connected,
            interface: $ethernet_iface,
            ip: $ethernet_ip
        }
    }'

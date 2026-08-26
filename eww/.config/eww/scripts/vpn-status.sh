#!/bin/sh

interface="my_pc"

if ip link show dev "$interface" >/dev/null 2>&1; then
  active=true
  address="$(
    ip -4 -o address show dev "$interface" 2>/dev/null |
      awk '{ split($4, value, "/"); print value[1]; exit }'
  )"
else
  active=false
  address=""
fi

jq -cn \
  --arg profile "$interface" \
  --argjson active "$active" \
  --arg address "$address" \
  '{profile: $profile, active: $active, address: $address}'

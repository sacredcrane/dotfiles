#!/bin/sh

controller="$(bluetoothctl show 2>/dev/null)"

case "$controller" in
*'Powered: yes'*) powered=true ;;
*) powered=false ;;
esac

case "$controller" in
*'Discovering: yes'*) discovering=true ;;
*) discovering=false ;;
esac

devices="$(
  bluetoothctl devices 2>/dev/null |
    while IFS= read -r line; do
      address="$(printf '%s\n' "$line" | awk '{ print $2 }')"

      if ! printf '%s\n' "$address" |
        awk 'BEGIN { IGNORECASE=1 } /^[0-9a-f]{2}(:[0-9a-f]{2}){5}$/ { valid=1 } END { exit !valid }'; then
        continue
      fi

      name="${line#Device $address }"
      info="$(bluetoothctl info "$address" 2>/dev/null)"

      alias="$(
        printf '%s\n' "$info" |
          awk -F ': ' '$1 ~ /^[[:space:]]*Alias$/ { print $2; exit }'
      )"

      [ -n "$alias" ] && name="$alias"

      address_name="$(printf '%s' "$address" | tr ':' '-')"

      if [ "$name" = "$address" ] || [ "$name" = "$address_name" ]; then
        named=false
      else
        named=true
      fi

      case "$info" in
      *'Paired: yes'*) paired=true ;;
      *) paired=false ;;
      esac

      case "$info" in
      *'Trusted: yes'*) trusted=true ;;
      *) trusted=false ;;
      esac

      case "$info" in
      *'Connected: yes'*) connected=true ;;
      *) connected=false ;;
      esac

      jq -cn \
        --arg address "$address" \
        --arg name "$name" \
        --argjson named "$named" \
        --argjson paired "$paired" \
        --argjson trusted "$trusted" \
        --argjson connected "$connected" \
        '{
          address: $address,
          name: $name,
          named: $named,
          paired: $paired,
          trusted: $trusted,
          connected: $connected
        }'
    done |
    jq -sc 'sort_by([(.connected | not), (.paired | not), (.named | not), .name])'
)"

[ -n "$devices" ] || devices='[]'

jq -cn \
  --argjson powered "$powered" \
  --argjson discovering "$discovering" \
  --argjson devices "$devices" \
  '{
    powered: $powered,
    discovering: $discovering,
    connected: ([$devices[] | select(.connected)] | length),
    devices: $devices
  }'

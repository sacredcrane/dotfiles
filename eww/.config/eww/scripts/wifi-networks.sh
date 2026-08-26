#!/bin/sh

iface="$(
  iw dev 2>/dev/null |
    awk '$1 == "Interface" { print $2; exit }'
)"

if [ -z "$iface" ]; then
  printf '[]\n'
  exit 0
fi

known="$(
  wpa_cli -i "$iface" list_networks 2>/dev/null |
    tail -n +2
)"

wpa_cli -i "$iface" scan_results 2>/dev/null |
  tail -n +2 |
  awk -F '\t' '
        NF >= 5 && $5 != "" {
            bssid=$1
            ssid=$5
            signal=$3

            if (!(ssid in best) || signal > best[ssid]) {
                best[ssid]=signal
                flags[ssid]=$4
                bssids[ssid]=bssid
            }
        }

        END {
            for (ssid in best)
                printf "%s\t%s\t%s\t%s\n", best[ssid], bssids[ssid], ssid, flags[ssid]
        }
    ' |
  sort -nr |
  while IFS="$(printf '\t')" read -r signal bssid ssid flags; do

    id="$(
      printf '%s\n' "$known" |
        awk -F '\t' -v ssid="$ssid" '
                    $2 == ssid {
                        print $1
                        exit
                    }
                '
    )"

    if [ -n "$id" ]; then
      known_json=true
    else
      known_json=false
      id=-1
    fi

    case "$flags" in
    *SAE*) security=sae ;;
    *WPA* | *RSN*) security=wpa ;;
    *) security=open ;;
    esac

    jq -cn \
      --arg ssid "$ssid" \
      --arg bssid "$bssid" \
      --argjson signal "$signal" \
      --arg flags "$flags" \
      --arg security "$security" \
      --argjson known "$known_json" \
      --argjson id "$id" \
      '{
                ssid: $ssid,
                bssid: $bssid,
                signal: $signal,
                flags: $flags,
                security: $security,
                known: $known,
                id: $id
            }'
  done |
  jq -s '.'

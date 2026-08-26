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
            ssid=$5
            signal=$3

            if (!(ssid in best) || signal > best[ssid]) {
                best[ssid]=signal
                flags[ssid]=$4
            }
        }

        END {
            for (ssid in best)
                printf "%s\t%s\t%s\n", best[ssid], ssid, flags[ssid]
        }
    ' |
  sort -nr |
  while IFS="$(printf '\t')" read -r signal ssid flags; do

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

    jq -cn \
      --arg ssid "$ssid" \
      --argjson signal "$signal" \
      --arg flags "$flags" \
      --argjson known "$known_json" \
      --argjson id "$id" \
      '{
                ssid: $ssid,
                signal: $signal,
                flags: $flags,
                known: $known,
                id: $id
            }'
  done |
  jq -s '.'

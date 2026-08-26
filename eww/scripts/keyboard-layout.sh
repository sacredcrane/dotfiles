#!/bin/sh

print_layout() {
  name="$(
    niri msg -j keyboard-layouts 2>/dev/null |
      jq -r '.names[.current_idx] // "??"'
  )"

  case "$name" in
  *Russian* | *Рус*) echo "RU" ;;
  *English* | *US*) echo "EN" ;;
  *) printf '%.2s\n' "$name" | tr '[:lower:]' '[:upper:]' ;;
  esac
}

print_layout

niri msg -j event-stream 2>/dev/null |
  while IFS= read -r event; do
    if printf '%s\n' "$event" |
      jq -e \
        'has("KeyboardLayoutSwitched") or has("KeyboardLayoutsChanged")' \
        >/dev/null 2>&1; then
      print_layout
    fi
  done

#!/bin/sh

print_workspaces() {
  niri msg --json workspaces 2>/dev/null |
    jq -c '[sort_by(.idx)[] | {idx: .idx, active: .is_active}]' \
      2>/dev/null || printf '[]\n'
}

print_workspaces

niri msg --json event-stream 2>/dev/null |
  while IFS= read -r event; do
    if printf '%s\n' "$event" |
      jq -e 'has("WorkspacesChanged") or has("WorkspaceActivated")' \
        >/dev/null 2>&1; then
      print_workspaces
    fi
  done

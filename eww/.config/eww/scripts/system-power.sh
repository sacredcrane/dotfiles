#!/bin/sh

action="$1"

case "$action" in
suspend)
  label="Suspend"
  ;;
reboot)
  label="Reboot"
  ;;
poweroff)
  label="Shut down"
  ;;
*) exit 2 ;;
esac

selection="$(
  printf 'Cancel\n%s\n' "$label" |
    fuzzel \
      --dmenu \
      --only-match \
      --lines=2 \
      --prompt="Confirm: " \
      --namespace=system-power-confirm \
      --layer=overlay \
      --log-level=none \
      --log-no-syslog
)" || exit 0

[ "$selection" = "$label" ] || exit 0

case "$action" in
suspend)
  "$HOME/.local/bin/lock-screen" --daemonize
  exec doas -n /usr/bin/zzz
  ;;
reboot)
  exec doas -n /usr/bin/reboot
  ;;
poweroff)
  exec doas -n /usr/bin/poweroff
  ;;
esac

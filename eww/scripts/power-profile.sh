#!/bin/sh

BUS="org.freedesktop.UPower.PowerProfiles"
PATH_="/org/freedesktop/UPower/PowerProfiles"

# Начальное состояние + заодно регистрируем этот D-Bus interface в tlp-pd.
tlpctl get

# Дальше только события.
stdbuf -oL gdbus monitor \
  --system \
  --dest "$BUS" \
  --object-path "$PATH_" |
  sed -u -n \
    "s/.*'ActiveProfile': <'\([^']*\)'>.*/\1/p"

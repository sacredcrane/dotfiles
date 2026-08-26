#!/bin/sh

BUS="org.freedesktop.UPower.PowerProfiles"
PATH_="/org/freedesktop/UPower/PowerProfiles"

tlpctl get


stdbuf -oL gdbus monitor \
  --system \
  --dest "$BUS" \
  --object-path "$PATH_" |
  sed -u -n \
    "s/.*'ActiveProfile': <'\([^']*\)'>.*/\1/p"

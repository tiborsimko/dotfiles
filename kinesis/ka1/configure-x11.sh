#!/bin/bash
#
# Tibor's keyboard and mouse configuration script.

# Quit on errors
set -o errexit

# Quit on unbound symbols
set -o nounset

# Read arguments
arg=""
if [ $# -gt 0 ]; then
  arg="$1"
fi

# Modify old keyboard
if [ "$arg" == "--old" ]; then
  deviceid=$(xinput list | grep "HID 05f3:0007    " | sed -n 's/.*id=\([0-9]\+\).*/\1/p')
  setxkbmap -device "${deviceid}" -option caps:escape -option altwin:prtsc_rwin
fi

# Set faster keyboard repeat rate
xset r rate 200 60

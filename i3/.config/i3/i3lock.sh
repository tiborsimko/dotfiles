#!/bin/sh

# Quit on errors
set -o errexit

# Quit on unbound symbols
set -o nounset

# Kill the compositor so that notifications won't appear while the screen is
# locked
if [ -n "$(pgrep -x picom)" ]; then
    killall picom
fi

# Lock the screen
i3lock -n -c 000000

# Restart compositor after unlocking
if [ -z "$(pgrep -x picom)" ]; then
    picom &
fi

#!/bin/bash -e
#
# Toggle bar.

if pgrep -x polybar; then
    pkill -x polybar
    herbstclient pad 0 0 0 0 0
else
    polybar mybar &
    herbstclient pad 0 24 0 0 0
fi

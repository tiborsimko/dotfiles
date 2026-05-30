#!/bin/bash
#
# Minimize the frontmost window via AppleScript, then focus its left
# neighbour so the workspace doesn't end up empty.
#
# Usage: minimize-and-focus.sh

# Minimize the frontmost window
osascript -e 'tell application "System Events" to set value of attribute "AXMinimized" of window 1 of (first process whose frontmost is true) to true'

# Small delay to let the minimize complete
sleep 0.1

# Focus another window on the workspace
aerospace focus --boundaries-action wrap-around-the-workspace left

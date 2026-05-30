#!/bin/bash
#
# Swap all workspaces between two monitors. Moves run in parallel so there's
# less visual blinking than sequential moves. Requires exactly two monitors;
# bails out otherwise.
#
# Usage: swap-monitor-workspaces.sh

# Get monitor IDs
MONITORS=$(aerospace list-monitors --json)
MONITOR_COUNT=$(echo "$MONITORS" | jq length)

if [ "$MONITOR_COUNT" -ne 2 ]; then
    echo "This script only works with exactly 2 monitors (found $MONITOR_COUNT)"
    exit 1
fi

MONITOR1=$(echo "$MONITORS" | jq -r '.[0]["monitor-id"]')
MONITOR2=$(echo "$MONITORS" | jq -r '.[1]["monitor-id"]')

# Get the currently focused workspace
FOCUSED_WS=$(aerospace list-workspaces --focused)

# Get workspaces on each monitor
WS_ON_M1=$(aerospace list-workspaces --monitor "$MONITOR1")
WS_ON_M2=$(aerospace list-workspaces --monitor "$MONITOR2")

# Move all workspaces from monitor 1 to monitor 2 (in parallel, non-focused first)
while IFS= read -r ws; do
    if [ -n "$ws" ] && [ "$ws" != "$FOCUSED_WS" ]; then
        aerospace move-workspace-to-monitor --workspace "$ws" "$MONITOR2" &
    fi
done <<< "$WS_ON_M1"

# Move all workspaces from monitor 2 to monitor 1 (in parallel, non-focused first)
while IFS= read -r ws; do
    if [ -n "$ws" ] && [ "$ws" != "$FOCUSED_WS" ]; then
        aerospace move-workspace-to-monitor --workspace "$ws" "$MONITOR1" &
    fi
done <<< "$WS_ON_M2"

wait

# Move the focused workspace last
if [ -n "$FOCUSED_WS" ]; then
    # Determine which monitor the focused workspace was on
    if echo "$WS_ON_M1" | grep -qx "$FOCUSED_WS"; then
        aerospace move-workspace-to-monitor --workspace "$FOCUSED_WS" "$MONITOR2"
    else
        aerospace move-workspace-to-monitor --workspace "$FOCUSED_WS" "$MONITOR1"
    fi
fi

#!/bin/bash
#
# Cycle to the next window of the focused app across all workspaces. Useful
# when one app has multiple windows scattered across spaces.
#
# Usage: focus-next-window.sh

# Get current window info
CURRENT=$(aerospace list-windows --focused --json | jq -r '.[0]')
CURRENT_ID=$(echo "$CURRENT" | jq -r '.["window-id"]')
CURRENT_APP=$(echo "$CURRENT" | jq -r '.["app-name"]')

# Get all windows for this app (IDs and workspaces)
WINDOWS=$(aerospace list-windows --all --json | jq -c ".[] | select(.[\"app-name\"] == \"$CURRENT_APP\") | {id: .[\"window-id\"], workspace: .workspace}")

# Convert to arrays
IDS=()
WORKSPACES=()
while read -r win; do
    [[ -z "$win" ]] && continue
    IDS+=("$(echo "$win" | jq -r '.id')")
    WORKSPACES+=("$(echo "$win" | jq -r '.workspace')")
done <<< "$WINDOWS"

# Skip if only one window
[[ ${#IDS[@]} -le 1 ]] && exit 0

# Find current index and get next
for i in "${!IDS[@]}"; do
    if [[ "${IDS[$i]}" == "$CURRENT_ID" ]]; then
        NEXT_INDEX=$(( (i + 1) % ${#IDS[@]} ))
        aerospace workspace "${WORKSPACES[$NEXT_INDEX]}"
        aerospace focus --window-id "${IDS[$NEXT_INDEX]}"
        exit 0
    fi
done

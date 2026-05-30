#!/bin/bash
#
# Focus an app by name, optionally skipping windows whose title contains a
# substring. Prefers a match on the current workspace; falls back to any.
#
# Usage: focus-app.sh <app-name> [exclude-title-substring]
#
# Example: focus-app.sh Alacritty

APP_NAME="$1"
EXCLUDE="$2"

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name> [exclude-title-substring]"
    exit 1
fi

# shellcheck disable=SC2016  # $app and $exclude are jq vars (bound via --arg), not shell vars
FILTER='.[] | select(.["app-name"] == $app) | select($exclude == "" or (.["window-title"] | contains($exclude) | not)) | .["window-id"]'

# Prefer a window of the app in the current workspace
CURRENT_WS=$(aerospace list-workspaces --focused)
WINDOW_ID=$(aerospace list-windows --workspace "$CURRENT_WS" --json | jq -r --arg app "$APP_NAME" --arg exclude "$EXCLUDE" "$FILTER" | head -1)

# Fall back to any workspace (will trigger workspace switch on focus)
if [ -z "$WINDOW_ID" ]; then
    WINDOW_ID=$(aerospace list-windows --all --json | jq -r --arg app "$APP_NAME" --arg exclude "$EXCLUDE" "$FILTER" | head -1)
fi

if [ -n "$WINDOW_ID" ]; then
    aerospace focus --window-id "$WINDOW_ID"
elif aerospace list-apps | grep -q " | $APP_NAME\$"; then
    # App is running but minimized - bring it to focus
    open -a "$APP_NAME"
fi

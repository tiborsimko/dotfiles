#!/bin/bash
#
# Focus a window whose title contains the given substring, optionally
# restricted to a specific app. Prefers a match on the current workspace;
# falls back to any.
#
# Usage: focus-window-by-title.sh <substring> [app-name]
#
# Example: focus-window-by-title.sh Slack "Google Chrome"

TITLE="$1"
APP_NAME="$2"

if [ -z "$TITLE" ]; then
    echo "Usage: $0 <substring> [app-name]"
    exit 1
fi

# shellcheck disable=SC2016  # $t and $app are jq vars (bound via --arg), not shell vars
FILTER='.[] | select(.["window-title"] | contains($t)) | select($app == "" or .["app-name"] == $app) | .["window-id"]'

# Prefer a matching window in the current workspace
CURRENT_WS=$(aerospace list-workspaces --focused)
WINDOW_ID=$(aerospace list-windows --workspace "$CURRENT_WS" --json | jq -r --arg t "$TITLE" --arg app "$APP_NAME" "$FILTER" | head -1)

# Fall back to any workspace (will trigger workspace switch on focus)
if [ -z "$WINDOW_ID" ]; then
    WINDOW_ID=$(aerospace list-windows --all --json | jq -r --arg t "$TITLE" --arg app "$APP_NAME" "$FILTER" | head -1)
fi

if [ -n "$WINDOW_ID" ]; then
    aerospace focus --window-id "$WINDOW_ID"
fi

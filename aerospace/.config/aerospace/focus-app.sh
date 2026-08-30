#!/bin/bash
#
# Focus an existing app window by name. Prefers a match on the current
# workspace, then falls back to any workspace. Within each search,
# --prefer-title puts matching windows first without excluding the others.
#
# With --activate, a running app without a managed window is asked to open one.
# This is reserved for callers such as bounce-cmd-p.sh; direct app shortcuts
# intentionally do nothing when no window exists.
#
# Usage: focus-app.sh [--activate] [--prefer-title <substring>] <app-name>
#
# Example: focus-app.sh Alacritty

ACTIVATE=false
PREFER_TITLE=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --activate)
            ACTIVATE=true
            shift
            ;;
        --prefer-title)
            if [ "$#" -lt 2 ]; then
                echo "Usage: $0 [--activate] [--prefer-title <substring>] <app-name>"
                exit 1
            fi
            PREFER_TITLE="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

APP_NAME="$1"

if [ "$#" -ne 1 ] || [ -z "$APP_NAME" ]; then
    echo "Usage: $0 [--activate] [--prefer-title <substring>] <app-name>"
    exit 1
fi

# shellcheck disable=SC2016  # $app and $prefer are jq vars (bound via --arg), not shell vars
FILTER='[.[] | select(.["app-name"] == $app)]
    | if $prefer == "" then . else
        sort_by(if ((.["window-title"] // "") | contains($prefer)) then 0 else 1 end)
      end
    | .[0]["window-id"] // empty'

# Prefer a window of the app in the current workspace
CURRENT_WS=$(aerospace list-workspaces --focused)
WINDOW_ID=$(aerospace list-windows --workspace "$CURRENT_WS" --json | jq -r --arg app "$APP_NAME" --arg prefer "$PREFER_TITLE" "$FILTER")

# Fall back to any workspace (will trigger workspace switch on focus)
if [ -z "$WINDOW_ID" ]; then
    WINDOW_ID=$(aerospace list-windows --all --json | jq -r --arg app "$APP_NAME" --arg prefer "$PREFER_TITLE" "$FILTER")
fi

if [ -n "$WINDOW_ID" ]; then
    aerospace focus --window-id "$WINDOW_ID"
elif [ "$ACTIVATE" = true ] && aerospace list-apps | grep -q " | $APP_NAME\$"; then
    # App is running but minimized - bring it to focus
    open -a "$APP_NAME"
fi

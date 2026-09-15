#!/bin/bash
#
# Focus the default terminal, wait until it is frontmost, then synthesize Cmd-P
# so its session picker fires. Karabiner invokes this fallback only outside
# supported terminals; Cmd-P stays local inside each terminal.
#
# Usage: bounce-cmd-p.sh

# Karabiner's shell_command runs with a minimal PATH; reach Homebrew tools.
export PATH="/opt/homebrew/bin:$PATH"

TERMINAL_BINDING=$(aerospace config --get mode.apps.binding.t)
TERMINAL_APP=${TERMINAL_BINDING##*focus-app.sh }

if [ "$TERMINAL_APP" = "$TERMINAL_BINDING" ]; then
    echo "Cannot determine the default terminal from AeroSpace" >&2
    exit 1
fi

TERMINAL_APP=${TERMINAL_APP%%;*}
TERMINAL_APP=${TERMINAL_APP##* }

case "$TERMINAL_APP" in
    '' | *[!A-Za-z0-9._-]*)
        echo "Invalid default terminal in AeroSpace: $TERMINAL_APP" >&2
        exit 1
        ;;
esac

~/.config/aerospace/focus-app.sh --activate "$TERMINAL_APP"

/usr/bin/osascript - "$TERMINAL_APP" <<'OSA'
on run argv
  set terminalName to item 1 of argv
  set terminalProcessName to terminalName & ".app"

  tell application "System Events"
    repeat 25 times
      if name of (path to frontmost application) is terminalProcessName then
        keystroke "p" using command down
        return
      end if
      delay 0.02
    end repeat
  end tell
end run
OSA

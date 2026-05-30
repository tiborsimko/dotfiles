#!/bin/bash
#
# Focus Alacritty, wait until it's actually frontmost, then synthesize Cmd-P
# so tmux's session picker fires. Bound from Karabiner so Cmd-P outside
# Alacritty hops over and triggers it.
#
# Usage: bounce-cmd-p.sh

# Karabiner's shell_command runs with a minimal PATH; reach Homebrew tools.
export PATH="/opt/homebrew/bin:$PATH"

~/.config/aerospace/focus-app.sh Alacritty

/usr/bin/osascript <<'OSA'
tell application "System Events"
  repeat 25 times
    if name of (path to frontmost application) is "Alacritty.app" then exit repeat
    delay 0.02
  end repeat
  keystroke "p" using command down
end tell
OSA

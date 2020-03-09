#!/bin/bash
panel_runs=$(pgrep -c "panel.sh")
echo $panel_runs
if [ "$panel_runs" = "1" ]; then
    ~/.config/herbstluftwm/panel.sh &
else
    pkill -x panel.sh && herbstclient pad 0 0
fi

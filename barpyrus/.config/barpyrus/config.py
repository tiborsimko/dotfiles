import sys

from barpyrus import conky, hlwm, lemonbar
from barpyrus import widgets as W
from barpyrus.core import Theme

# Copy this config to ~/.config/barpyrus/config.py

# set up a connection to herbstluftwm in order to get events
# and in order to call herbstclient commands
hc = hlwm.connect()

# get the geometry of the monitor
monitor = sys.argv[1] if len(sys.argv) >= 2 else 0
(x, y, monitor_w, monitor_h) = hc.monitor_rect(monitor)
height = 16 # height of the panel
width = monitor_w - 60 # width of the panel (making room for stalonetray)
hc(['pad', str(monitor), str(height)]) # get space for the panel

# An example conky-section:
# icons
bat_icons = [
    0xe242, 0xe243, 0xe244, 0xe245, 0xe246,
    0xe247, 0xe248, 0xe249, 0xe24a, 0xe24b,
]
# first icon: 0 percent
# last icon: 100 percent
bat_delta = 100 / len(bat_icons)
conky_text = ''
conky_text += '%{F\\#98971a}CPU%{F\\#928374} ${cpu}% ${loadavg} '
conky_text += '%{F\\#98971a}MEM%{F\\#928374} ${memperc}% ${memmax} '
conky_text += '%{F\\#98971a}SWP%{F\\#928374} ${swapperc}% ${swapmax} '
conky_text += '%{F\\#98971a}HDD%{F\\#928374} ${fs_free} '
conky_text += '%{F\\#98971a}NET%{F\\#928374} ${wireless_essid wlp4s0} ${upspeedf wlp4s0}u ${downspeedf wlp4s0}d '
conky_text += '%{F\\#98971a}BAT%{F\\#928374} '
conky_text += "${if_existing /sys/class/power_supply/BAT0}"
conky_text += "${if_match \"$battery\" == \"discharging $battery_percent%\"}"
conky_text += "%{F\\#d79921}"
conky_text += "$else"
conky_text += "%{F\\#928374}"
conky_text += "$endif"
conky_text += "$battery_percent% "
conky_text += "${endif}"
conky_text += "%{F-}"
conky_text += '%{F\\#98971a}DAY%{F\\#928374}'

# you can define custom themes
grey_frame = Theme(bg = '#000000', fg = '#928374', padding = (3,3))

# Widget configuration:
bar = lemonbar.Lemonbar(geometry = (x,y,width,height))
bar.widget = W.ListLayout([
    W.RawLabel('%{l}'),
    hlwm.HLWMTags(hc, monitor, tag_renderer = hlwm.underlined_tags),
    conky.ConkyWidget(text='   '),
    hlwm.HLWMMonitorFocusLayout(hc, monitor,
           # this widget is shown on the focused monitor:
           grey_frame(hlwm.HLWMWindowTitle(hc)),
           # this widget is shown on all unfocused monitors:
           conky.ConkyWidget('df /: ${fs_used_perc /}%')
                                    ),
    W.RawLabel('%{r}'),
    conky.ConkyWidget(text=conky_text),
    grey_frame(W.DateTime('%Y-%m-%d %H:%M')),
])

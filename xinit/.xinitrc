# Tibor's xinit configuration file.

#xrdb -merge ~/.Xresources
xmodmap ~/.Xmodmap
xsetroot -solid black
# xsettingsd &
stalonetray &
unclutter &
qutebrowser &
nm-applet &
dunst &
autocutsel -selection CLIPBOARD -fork &
autocutsel -selection PRIMARY -fork &
exec xmonad

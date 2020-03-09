# Tibor's xinit configuration file.

#xrdb -merge ~/.Xresources
xmodmap ~/.Xmodmap
xsetroot -solid black
# xsettingsd &
stalonetray &
unclutter &
nm-applet &
dunst &
autocutsel -selection CLIPBOARD -fork &
autocutsel -selection PRIMARY -fork &
exec herbstluftwm --locked

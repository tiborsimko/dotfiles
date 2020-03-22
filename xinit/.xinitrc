# Tibor's xinit configuration file.

#xrdb -merge ~/.Xresources
xmodmap ~/.Xmodmap
xsetroot -solid black
# xsettingsd &
unclutter &
nm-applet &
dunst &
autocutsel -selection CLIPBOARD -fork &
autocutsel -selection PRIMARY -fork &
export _JAVA_AWT_WM_NONREPARENTING=1
exec herbstluftwm --locked

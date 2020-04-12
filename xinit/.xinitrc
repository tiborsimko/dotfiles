# Tibor's xinit configuration file.

xmodmap ~/.Xmodmap
xrdb -merge ~/.Xresources
xsetroot -solid '#282828'
export _JAVA_AWT_WM_NONREPARENTING=1
unclutter &
nm-applet &
clipmenud &
dunst &
autocutsel -selection CLIPBOARD -fork &
autocutsel -selection PRIMARY -fork &
slstatus &
exec dwm

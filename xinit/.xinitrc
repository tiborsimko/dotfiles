# Tibor's xinit configuration file.

xmodmap ~/.Xmodmap
xrdb -merge ~/.Xresources
xsetroot -solid '#101010'
unclutter &
nm-applet &
parcellite &
dunst &
qutebrowser &
st &
autocutsel -selection CLIPBOARD -fork &
autocutsel -selection PRIMARY -fork &
export _JAVA_AWT_WM_NONREPARENTING=1
slstatus &
exec dwm

# Tibor's xinit configuration file.

xmodmap ~/.Xmodmap
xrdb -merge ~/.Xresources
xsetroot -solid '#282828'
unclutter &
nm-applet &
clipmenud &
dunst &
qutebrowser &
st &
autocutsel -selection CLIPBOARD -fork &
autocutsel -selection PRIMARY -fork &
export _JAVA_AWT_WM_NONREPARENTING=1
slstatus &
while true; do
    dwm 2> ~/.dwm.log
done

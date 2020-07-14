# Tibor's xinit configuration file.

# Use NVIDIA graphics
xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --dpi 109
xrandr --auto

# Modify keys
xmodmap ~/.Xmodmap

# Set faster keyboard repeat rate
xset r rate 200 60

# Configure X11 resources
xrdb -merge ~/.Xresources

# Set background
xsetroot -solid '#282828'

# Fix Java app troubles in tiling WMs
export _JAVA_AWT_WM_NONREPARENTING=1

# Hide mouse when not active
unclutter &

# Notification system
dunst &

# Clipboard manager
clipmenud &

# Merge selection and clipboard for simplicity
autocutsel -selection CLIPBOARD -fork &
autocutsel -selection PRIMARY -fork &

# Run status bar monitor
slstatus &

# Run window manager
while true; do
    dwm 2> ~/.cache/dwm/dwm.log
done

# Tibor's xinit configuration file.

# Modify keys
xmodmap ~/.Xmodmap

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
exec dwm

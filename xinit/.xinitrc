# Tibor's xinit configuration file.

# Set faster keyboard repeat rate
xset r rate 200 60

# Turn off beep sounds
xset b off

# Configure X11 resources
xrdb -merge ~/.Xresources

# Set background
xsetroot -solid '#1d2021'

# Set pointer
xsetroot -cursor_name left_ptr

# Fix Java app troubles in tiling WMs
export _JAVA_AWT_WM_NONREPARENTING=1

# Hide mouse when not active
unclutter &

# Notification system
dunst &

# Network manager applet
nm-applet &

# Clipboard manager
clipmenud &

# Merge selection and clipboard for simplicity
autocutsel -selection CLIPBOARD -fork &
autocutsel -selection PRIMARY -fork &

# Configure keyboard and mouse
$HOME/private/bin/x1-k

# Run compositor
# picom &

# Start SSH agent
eval $(ssh-agent)

# Start X11 applications
firefox &
xterm &

# Start Emacs in daemon mode
emacs --daemon &

# Start hot key daemon
sxhkd &

# Start bar
polybar mybar &

# Start window manager
exec dbus-launch --exit-with-session bspwm

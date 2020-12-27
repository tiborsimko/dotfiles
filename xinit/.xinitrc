# Tibor's xinit configuration file.

# Set faster keyboard repeat rate
xset r rate 200 60

# Turn off beep sounds
xset b off

# Configure X11 resources
xrdb -merge ~/.Xresources

# Set background
xsetroot -solid '#1d2021'

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
# Configure keyboard and mouse
$HOME/private/bin/x1-k


# Run initial applications
firefox &
emacs &
st &
# Start SSH agent
eval $(ssh-agent)

# Run window manager
while true; do
    dwm 2> ~/.cache/dwm/dwm.log
done

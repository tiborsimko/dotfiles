# Tibor's X11 initialisation file.

# Set faster keyboard repeat rate
xset r rate 200 60

# Turn off beep sounds
xset b off

# Configure X11 resources
xrdb -merge "$HOME/.Xresources"

# Configure background
hsetroot -solid black

# Configure pointer
xsetroot -cursor_name left_ptr

# Fix Java app troubles in tiling WMs
export _JAVA_AWT_WM_NONREPARENTING=1

# Do not scale out Alacritty fonts for different DPI external monitors
export WINIT_X11_SCALE_FACTOR=1

# Hide mouse when not active
if [ -z "$(pgrep -x unclutter)" ]; then
  unclutter &
fi

# Start network manager applet
if [ -z "$(pgrep -x nm-applet)" ]; then
  nm-applet &
fi

# Start screen lock daemon
if [ -z "$(pgrep -x xss-lock)" ]; then
  # xss-lock --transfer-sleep-lock -- slock &
  xss-lock --transfer-sleep-lock -- "$HOME/.config/i3/i3lock.sh" &
fi

# Start compositor
if [ -z "$(pgrep -x picom)" ]; then
  picom --daemon
fi

# Merge selection and clipboard for simplicity
if [ -z "$(pgrep -x autocutsel)" ]; then
  autocutsel -selection CLIPBOARD -fork -pause 500 &
  autocutsel -selection PRIMARY -fork -pause 500 &
fi

# Start notification system
if [ -z "$(pgrep -x dunst)" ]; then
  dunst &
fi

# Start terminal
alacritty &

# Start browser
firefox &

# Start window manager
while :; do
  /etc/X11/Xsession i3
done

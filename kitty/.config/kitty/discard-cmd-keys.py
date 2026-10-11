# Discard every Cmd and Cmd-Shift key; explicit maps later in kitty.conf win.
keys = [*"abcdefghijklmnopqrstuvwxyz0123456789`-=[];',./", "backslash", "space", "enter", "backspace", "delete", "escape"]
for mods in ("cmd", "cmd+shift"):
    for key in keys:
        print(f"map {mods}+{key} discard_event")

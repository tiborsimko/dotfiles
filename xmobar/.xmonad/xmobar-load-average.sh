load=$(awk '{print $1}' /proc/loadavg)
loadint=${load/.*}

red=#fb4934
gray=#928374

[ $loadint -ge 2 ] && color=$red || color=$gray

echo "<fc=$color>($load)</fc>"

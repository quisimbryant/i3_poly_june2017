#!/bin/sh
#
# z3bra - (c) wtfpl 2014
# Fetch infos on your computer, and print them to stdout every second.

volume() {
    amixer get Master | sed -n 'N;s/^.*\[\([0-9]\+%\).*$/\1/p'
}

memused() {
    read t f <<< `grep -E 'Mem(Total|Free)' /proc/meminfo |awk '{print $2}'`
    bc <<< "scale=2; 100 - $f / $t * 100" | cut -d. -f1
}

network() {
    read lo int1 int2 <<< `ip link | sed -n 's/^[0-9]: \(.*\):.*$/\1/p'`
    if iwconfig $int1 >/dev/null 2>&1; then
        wifi=$int1
        eth0=$int2
    else
        wifi=$int2
        eth0=$int1
    fi
    ip link show $eth0 | grep 'state UP' >/dev/null && int=$eth0 ||int=$wifi

    #int=eth0

    ping -c 1 8.8.8.8 >/dev/null 2>&1 &&
        echo "$int connected" || echo "$int disconnected"
}

groups() {
    cur=`xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}'`
    tot=`xprop -root _NET_NUMBER_OF_DESKTOPS | awk '{print $3}'`

    for w in `seq 0 $((cur - 1))`; do line="${line}="; done
    line="${line}|"
    for w in `seq $((cur + 2)) $tot`; do line="${line}="; done
    echo $line
}

nowplaying() {
    cur=`mpd current`
    # this line allow to choose whether the output will scroll or not
    test "$1" = "scroll" && PARSER='skroll -n20 -d0.5 -r' || PARSER='cat'
    test -n "$cur" && $PARSER <<< $cur || echo "- stopped -"
}

battery() {
    BATC=/sys/class/power_supply/BAT1/capacity
    BATS=/sys/class/power_supply/BAT1/status

    test "`cat $BATS`" = "Charging" && echo -n '+' || echo -n '-'

    sed -n p $BATC
}

clock() {
    date '+%Y-%m-%d %H:%M'
}

# This loop will fill a buffer with our infos, and output it to stdout.
while :; do
    buf=""
    buf="${buf} CLK: $(clock) -"
    buf="${buf} NET: $(network) -"
    buf="${buf} CPU: $(cpuload)%% -"
    buf="${buf} RAM: $(memused)%% -"
    buf="${buf} VOL: $(volume)%%"
    buf="${buf} MPD: $(nowplaying)"
    buf="${buf} [$(groups)]   --  "

    echo $buf
    # use `nowplaying scroll` to get a scrolling output!
    sleep 1 # The HUD will be updated every second
done

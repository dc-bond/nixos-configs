#!/bin/bash

DIR="~/xixor/screenshots"
NAME="screenshot_$(date +%d%m%Y_%H%M%S).png"

option1="selected window (delay 3 sec)"
option2="selected area"
option3="fullscreen (delay 3 sec)"

options="$option1\n$option2\n$option3"

choice=$(echo -e "$options" | rofi -dmenu -i -no-show-icons -l 4 -width 30 -p "Take Screenshot")

case $choice in
    $option1)
        scrot $DIR$NAME -d 3 -e 'xclip -selection clipboard -t image/png -i $f' -c -z -u
        notify-send "screenshot created" "Mode: selected window"
    ;;
    $option2)
	grim -g "$(slurp)" $($DIR)/$(date +'%s_grim.png')
        notify-send "screenshot created" "Mode: selected area"
    ;;
    $option3)
        sleep 3
        grim $($DIR)/$(date +'%s_grim.png')
        notify-send "screenshot created" "Mode: fullscreen"
    ;;
esac

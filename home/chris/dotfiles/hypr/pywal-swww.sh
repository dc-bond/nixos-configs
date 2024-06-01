#!/bin/bash

# select random wallpaper and create color scheme
wal -s -t -q -i ~/nixos-configs/home/chris/wallpaper/

## load current pywal color scheme
#source "$HOME/.cache/wal/colors.sh"

## copy color file to waybar folder
#cp ~/.cache/wal/colors-waybar.css ~/.config/waybar/
#cp $wallpaper ~/.cache/current_wallpaper.jpg

# get wallpaper image name
newwall=$(echo $wallpaper | sed "s|~/nixos-configs/home/chris/wallpaper/||g")

# set the new wallpaper
swww img $wallpaper --transition-step 20 --transition-fps=20

## reload waybar
#~/cypress-dotfiles/scripts/waybar-launch.sh

## send notification
#notify-send "Theme and Wallpaper updated" "With image $newwall"
#echo "DONE!"

#!/bin/sh

# ----------------------------------------------------- 
# quit running waybar instances
# ----------------------------------------------------- 
killall waybar
# ----------------------------------------------------- 
# load the configuration based on the username
# ----------------------------------------------------- 
waybar -c ~/.config/waybar/config.json

#!/bin/bash

pkill xautolock

xautolock -time 1 -locker "swaylock -i ~/.cache/current_wallpaper.jpg" -notify 10 -notifier "notify-send 'Screen will be locked soon.' 'Locking screen in 10 seconds'"

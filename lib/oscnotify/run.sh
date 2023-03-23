#!/bin/bash
ps -ef | grep 'oscnotify' | grep -v grep | grep -v run | awk '{print $2}' | xargs -r kill -9
cd "$(dirname "$0")"
nohup ./oscnotify -path /home/we/dust/code/forestscapes/ >/dev/null 2>&1 &

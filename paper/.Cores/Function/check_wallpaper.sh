#!/bin/bash
#VERSION="1.0.2"
#预下载壁纸检测
check_wallpaper() {
   local cache_file="$1"
   local wallpaper_var="$2"
   if [ -f "$cache_file" ]; then
       eval "$wallpaper_var"="$(cat "$cache_file" 2>/dev/null)"
       if [ -n "${!wallpaper_var}" ] && [ -f "${!wallpaper_var}" ]; then
           echo "$(date '+%m-%d %H:%M') | 检测到预下载壁纸：$(basename "${!wallpaper_var}")" >&2
       else
           eval "$wallpaper_var"=""
           rm -f "$cache_file"
       fi
   else
       eval "$wallpaper_var"=""
   fi
}
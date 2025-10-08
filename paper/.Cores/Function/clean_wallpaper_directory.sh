#!/bin/bash
# 清理壁纸存储目录
clean_wallpaper_directory() {
    local wallpaper_dir="$SAVE_DIR"  # /storage/emulated/0/Wallpaper/.Cores/Papers/

    # 检查目录是否存在且非空
    [ -d "$wallpaper_dir" ] || return 0
    local files_found=0
    for file in "$wallpaper_dir"/*; do
        [ -e "$file" ] && files_found=1 && break
    done
    [ $files_found -eq 0 ] && return 0

    # 删除文件并统计
    local deleted=0
    for file in "$wallpaper_dir"/*; do
        [ -f "$file" ] && rm -f "$file" && deleted=$((deleted + 1))
    done

    [ $deleted -gt 0 ] && echo "$(date '+%m-%d %H:%M') | 共删除 $deleted 个残留文件"
}
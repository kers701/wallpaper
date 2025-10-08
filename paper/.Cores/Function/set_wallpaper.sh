#!/bin/bash
#VERSION="1.0.2"
#设置壁纸
set_wallpaper() {
    local img_path="$1"
    if [ -z "$img_path" ] || [ ! -f "$img_path" ]; then
        echo "$(date '+%m-%d %H:%M') | 壁纸文件无效或不存在：$img_path" >&2
        return 1
    fi
    if ! identify "$img_path" &>/dev/null; then
        echo "$(date '+%m-%d %H:%M') | 无效图片文件：$(basename "$img_path")" >&2
        rm -f "$img_path"
        return 1
    fi
    # 设置壁纸
    termux-wallpaper -f "$img_path" &>/dev/null
    termux-wallpaper -f "$img_path" -l &>/dev/null
    echo "$(date '+%m-%d %H:%M') | 已设置为壁纸：$(basename "$img_path")" >&2
    # 删除旧壁纸（如果存在且不是当前壁纸）
    if [ -n "$PREVIOUS_WALLPAPER" ] && [ -f "$PREVIOUS_WALLPAPER" ] && [ "$PREVIOUS_WALLPAPER" != "$img_path" ]; then
        echo "$(date '+%m-%d %H:%M') | 删除上一张壁纸：$(basename "$PREVIOUS_WALLPAPER")" >&2
        rm -f "$PREVIOUS_WALLPAPER"
    fi
    # 更新当前壁纸
    PREVIOUS_WALLPAPER="$img_path"
    return 0
}
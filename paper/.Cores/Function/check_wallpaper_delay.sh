#!/bin/bash
#VERSION="1.0.2"
# 检查壁纸设置后的延迟
check_wallpaper_delay() {
    local target="https://wallhaven.cc/"
    local response_time
    response_time=$(get_response_time "$target")
    if [ "$response_time > 5000" ]; then
        echo "$(date '+%m-%d %H:%M') | 主程序启动失败，启用子程序初始化" >&2
        return 1
    elif [ "$(echo "$response_time < 3000" | bc -l)" -eq 1 ]; then
        echo "$(date '+%m-%d %H:%M') | 壁纸设置后延迟正常（${response_time}{CI}ms）" >&2
        return 0
    else
        echo "$(date '+%m-%d %H:%M') | 壁纸设置后延迟过高（${response_time}ms）" >&2
        return 1
    fi
}
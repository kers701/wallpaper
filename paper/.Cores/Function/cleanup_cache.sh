#!/bin/bash
#VERSION="1.0.2"
#清理MAX文件
cleanup_cache() {
    if [ -z "$CACHE_FILE" ]; then
        echo "$(date '+%m-%d %H:%M') | CACHE_FILE 未定义，跳过Max清理" >&2
        return 1
    fi
    if [ ! -f "$CACHE_FILE" ]; then
        echo "$(date '+%m-%d %H:%M') | Max文件不存在：$CACHE_FILE，跳过清理" >&2
        touch "$CACHE_FILE"
        return 0
    fi
    local cache_tmp="/storage/emulated/0/Wallpaper/.Cores/Pages/page_cache$$.txt"
    local current_time=$(date +%s)
    local expiry_seconds=$((7 * 24 * 60 * 60)) # 7 天
    # 读取缓存文件，过滤过期条目
    while IFS='|' read -r query last_page timestamp; do
        if [ -z "$query" ] || [ -z "$last_page" ] || [ -z "$timestamp" ]; then
            continue
        fi
        if [ $((current_time - timestamp)) -lt $expiry_seconds ]; then
            echo "$query|$last_page|$timestamp" >> "$cache_tmp"
        fi
    done < "$CACHE_FILE"
    # 更新缓存文件
    mv -f "$cache_tmp" "$CACHE_FILE" 2>/dev/null || true
}
#!/bin/bash
#VERSION="1.0.2"
# 添加无效关键词到Fallback文件
add_to_fallback() {
    local keyword=$1
    if [ -z "$keyword" ] || [ -z "$FALLBACK_FILE" ]; then
        echo "$(date '+%m-%d %H:%M') | 无效关键词或Fallback文件未定义，跳过添加" >&2
        return 1
    fi
    # 规范化关键词：转换为小写，去除多余空格
    normalized_keyword=$(echo "$keyword" | tr '[:upper:]' '[:lower:]' | tr -s ' ')
    # 检查Really文件中是否已存在
    if [ -n "${REALLY_CACHE[$normalized_keyword]}" ]; then
        echo "$(date '+%m-%d %H:%M') | 关键词<$SEARCH_DISPLAY>已在Really文件中,跳过添加Fallback" >&2
        return 1
    fi
    # 避免重复添加到 Fallback
    if [ -z "${FALLBACK_CACHE[$normalized_keyword]}" ]; then
        echo "$normalized_keyword" >> "$FALLBACK_FILE"
        FALLBACK_CACHE["$normalized_keyword"]=1
        echo "$(date '+%m-%d %H:%M') | 添加无效关键词<$SEARCH_DISPLAY>到Fallback文件" >&2
    fi
}
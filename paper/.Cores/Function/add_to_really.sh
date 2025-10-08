#!/bin/bash
#VERSION="1.0.2"
# 添加成功关键词到Really文件
add_to_really() {
    local keyword=$1
    if [ -z "$keyword" ] || [ -z "$REALLY_FILE" ]; then
        echo "$(date '+%m-%d %H:%M') | 无效关键词或Really文件未定义，跳过添加" >&2
        return 1
    fi
    # 规范化关键词：转换为小写，去除多余空格
    normalized_keyword=$(echo "$keyword" | tr '[:upper:]' '[:lower:]' | tr -s ' ')
    # 避免重复添加
    if [ -z "${REALLY_CACHE[$normalized_keyword]}" ]; then
        echo "$normalized_keyword" >> "$REALLY_FILE"
        REALLY_CACHE["$normalized_keyword"]=1
        echo "$(date '+%m-%d %H:%M') | 添加成功关键词<$SEARCH_DISPLAY>到Really文件" >&2
    fi
}
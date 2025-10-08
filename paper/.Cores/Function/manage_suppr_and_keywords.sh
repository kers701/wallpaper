#!/bin/bash

# 管理Suppr文件和关键词文件
manage_suppr_and_keywords() {
    local keyword=$1
    local category=$2
    local keyword_file
    local legacy_keyword_file

    # 确定关键词文件路径
    if [ "$category" == "zr" ]; then
        keyword_file="/storage/emulated/0/Wallpaper/.Cores/Keywords/keywords"
        legacy_keyword_file="/data/data/com.termux/files/home/keywords"
    elif [ "$category" == "dm" ]; then
        keyword_file="/storage/emulated/0/Wallpaper/.Cores/Keywords/keywords"
        legacy_keyword_file="/data/data/com.termux/files/home/keywords"
    else
        echo "$(date '+%m-%d %H:%M') | 无效的类别<$category>，跳过关键词管理" >&2
        return 1
    fi

    # 确保Keywords目录存在
    local upgrades_dir="/storage/emulated/0/Wallpaper/.Cores/Keywords"
    if [ ! -d "$upgrades_dir" ]; then
        mkdir -p "$upgrades_dir" 2>/dev/null
    fi

    # 确保关键词文件存在
    if [ ! -f "$keyword_file" ]; then
        touch "$keyword_file" 2>/dev/null
        if [ -f "$legacy_keyword_file" ] && [ -s "$legacy_keyword_file" ]; then
            cp "$legacy_keyword_file" "$keyword_file" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "$(date '+%m-%d %H:%M') | 已从<$legacy_keyword_file>复制内容到<$keyword_file>" >&2
            else
                echo "$(date '+%m-%d %H:%M') | 复制<$legacy_keyword_file>到<$keyword_file>失败，检查权限" >&2
            fi
        fi
    fi

    # 规范化关键词
    local normalized_keyword=$(echo "$keyword" | tr '[:upper:]' '[:lower:]' | tr -s ' ')

    # 检查是否已在Suppr缓存中，避免重复添加
    if [ -n "${SUPPR_CACHE["$normalized_keyword"]}" ]; then
        echo "$(date '+%m-%d %H:%M') | 关键词<$normalized_keyword>已在Suppr缓存中，跳过" >&2
        return 0
    fi

    # 先从关键词文件删除关键词（不区分大小写）
    if [ -f "$keyword_file" ] && [ -s "$keyword_file" ]; then
        cp "$keyword_file" "${keyword_file}.tmp" 2>/dev/null
        if [ $? -eq 0 ]; then
            # 使用 grep -i 实现不区分大小写的删除
            grep -iv "^${normalized_keyword}$" "${keyword_file}.tmp" > "$keyword_file" 2>/dev/null
            if [ $? -eq 0 ]; then
                rm -f "${keyword_file}.tmp" 2>/dev/null
                echo "$(date '+%m-%d %H:%M') | Delete keywords <$normalized_keyword>" >&2
            else
                rm -f "${keyword_file}.tmp" 2>/dev/null
                echo "$(date '+%m-%d %H:%M') | Delete keywords <$normalized_keyword> Fail Skip adding" >&2
                return 1
            fi
        else
            echo "$(date '+%m-%d %H:%M') | 创建临时文件失败，跳过删除和添加" >&2
            return 1
        fi
    fi

    # 检查Suppr文件中是否已存在该关键词
    if [ -f "$SUPPR_FILE" ] && grep -Fx "$normalized_keyword" "$SUPPR_FILE" > /dev/null; then
        echo "$(date '+%m-%d %H:%M') | 关键词<$normalized_keyword>已在Suppr文件中，跳过添加" >&2
        return 0
    fi

    # 添加到Suppr文件
    add_to_suppr "$normalized_keyword" "$keyword_file" || {
        echo "$(date '+%m-%d %H:%M') | 添加关键词<$normalized_keyword>到Suppr失败" >&2
        return 1
    }

    return 0
}
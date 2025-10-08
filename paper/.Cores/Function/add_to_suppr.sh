#!/bin/bash

# 添加无效关键词到Suppr文件
add_to_suppr() {
    local keyword=$1
    local keyword_file=$2  # 参数保留，但不再使用
    local suppr_file="$SUPPR_FILE"

    # 检查输入参数
    if [ -z "$keyword" ] || [ -z "$suppr_file" ]; then
        echo "$(date '+%m-%d %H:%M') | 无效关键词或Suppr文件未定义，跳过添加" >&2
        return 1
    fi

    # 规范化关键词：去除多余空格，保留原始大小写
    local normalized_keyword=$(echo "$keyword" | tr -s ' ')

    # 确保Suppr文件存在
    if [ ! -f "$suppr_file" ]; then
        echo "$(date '+%m-%d %H:%M') | Suppr文件<$suppr_file>不存在，创建空文件" >&2
        touch "$suppr_file" 2>/dev/null || {
            echo "$(date '+%m-%d %H:%M') | 创建Suppr文件<$suppr_file>失败，检查权限" >&2
            return 1
        }
    fi

    # 检查文件可写性
    if [ ! -w "$suppr_file" ]; then
        echo "$(date '+%m-%d %H:%M') | Suppr文件<$suppr_file>不可写，检查权限" >&2
        return 1
    fi

    # 写入Suppr文件
    local lines_before=$(wc -l < "$suppr_file" 2>/dev/null || echo 0)
    echo "$normalized_keyword" >> "$suppr_file" 2>/dev/null
    if [ $? -eq 0 ]; then
        # 验证是否写入
        local lines_after=$(wc -l < "$suppr_file" 2>/dev/null || echo 0)
        if [ "$lines_after" -gt "$lines_before" ]; then
            # 安全更新SUPPR_CACHE
            declare -A SUPPR_CACHE 2>/dev/null || true
            eval "SUPPR_CACHE[\"$normalized_keyword\"]=1"
            echo "$(date '+%m-%d %H:%M') | Learning Suppr <$normalized_keyword>" >&2
        else
            echo "$(date '+%m-%d %H:%M') | 关键词<$normalized_keyword>写入Suppr文件失败，未检测到新行" >&2
            return 1
        fi
    else
        echo "$(date '+%m-%d %H:%M') | 关键词<$normalized_keyword>写入Suppr文件失败，检查权限" >&2
        return 1
    fi

    return 0
}
#!/bin/bash
#VERSION="1.0.2"

#清理Fallback文件
cleanup_fallback() {
    local max_lines=2000
    local fallback_file

    # 设置默认目录
    if [ -z "$FALLBACK_DIR" ]; then
        echo "$(date '+%m-%d %H:%M') | FALLBACK_DIR 未定义，默认使用 /storage/emulated/0/Wallpaper/.Cores/Fallbacks" >&2
        FALLBACK_DIR="/storage/emulated/0/Wallpaper/.Cores/Fallbacks"
    fi

    # 创建目录
    if [ ! -d "$FALLBACK_DIR" ]; then
        mkdir -p "$FALLBACK_DIR"
        echo "$(date '+%m-%d %H:%M') | 创建Fallback目录：$FALLBACK_DIR" >&2
    fi

    # 检查写权限
    if [ ! -w "$FALLBACK_DIR" ]; then
        echo "$(date '+%m-%d %H:%M') | Fallback目录 $FALLBACK_DIR 无写权限，尝试修复" >&2
        chmod -R 755 "$FALLBACK_DIR" 2>/dev/null
        if [ ! -w "$FALLBACK_DIR" ]; then
            echo "$(date '+%m-%d %H:%M') | 无法修复 $FALLBACK_DIR 权限，跳过Fallback文件清理" >&2
            return 1
        fi
    fi

    # 查找所有文件并检查行数
    find "$FALLBACK_DIR" -type f | while read -r fallback_file; do
        if [ -f "$fallback_file" ]; then
            local line_count=$(wc -l < "$fallback_file")
            if [ "$line_count" -gt "$max_lines" ]; then
                : > "$fallback_file" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo "$(date '+%m-%d %H:%M') | FALLBACK清理完成" >&2
                else
                    echo "$(date '+%m-%d %H:%M') | 文件 $fallback_file 清理失败，请检查权限" >&2
                    return 1
                fi
            fi
        fi
    done

    return 0
}
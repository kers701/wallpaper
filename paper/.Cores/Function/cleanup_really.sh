#!/bin/bash
#VERSION="1.0.2"
#清理Really文件中超过2000行的数据
cleanup_really() {
    local max_lines=2000
    if [ -z "$REALLY_DIR" ]; then
        echo "$(date '+%m-%d %H:%M') | REALLY_DIR 未定义，默认使用 /storage/emulated/0/Wallpaper/.Cores/Reallys" >&2
        REALLY_DIR="/storage/emulated/0/Wallpaper/.Cores/Reallys"
    fi
    if [ ! -d "$REALLY_DIR" ]; then
        mkdir -p "$REALLY_DIR"
        echo "$(date '+%m-%d %H:%M') | 创建Reallys目录：$REALLY_DIR" >&2
    fi
    if [ ! -w "$REALLY_DIR" ]; then
        echo "$(date '+%m-%d %H:%M') | Reallys目录 $REALLY_DIR 无写权限，尝试修复" >&2
        chmod -R 755 "$REALLY_DIR" 2>/dev/null
        if [ ! -w "$REALLY_DIR" ]; then
            echo "$(date '+%m-%d %H:%M') | 无法修复 $REALLY_DIR 权限，跳过Really文件清理" >&2
            return 1
        fi
    fi
    echo "$(date '+%m-%d %H:%M') | 检查Really文件中数据行数" >&2
    local file
    # 遍历目录中的每个文件
    find "$REALLY_DIR" -type f | while read -r file; do
        local line_count
        line_count=$(wc -l < "$file")
        if [ "$line_count" -gt "$max_lines" ]; then
            echo "$(date '+%m-%d %H:%M') | 文件 $file 行数 ($line_count) 超过 $max_lines，开始清理" >&2
            # 保留最新的 max_lines 行
            tail -n "$max_lines" "$file" > "${file}.tmp" 2>/dev/null
            if [ $? -eq 0 ]; then
                mv "${file}.tmp" "$file" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo "$(date '+%m-%d %H:%M') | 成功清理 $file，保留最新 $max_lines 行" >&2
                else
                    echo "$(date '+%m-%d %H:%M') | 无法移动临时文件 ${file}.tmp，清理失败" >&2
                    return 1
                fi
            else
                echo "$(date '+%m-%d %H:%M') | 无法处理文件 $file，清理失败" >&2
                rm -f "${file}.tmp" 2>/dev/null
                return 1
            fi
        else
            echo "$(date '+%m-%d %H:%M') | 文件 $file 行数 ($line_count) 未超过 $max_lines，无需清理" >&2
        fi
    done
    if [ $? -eq 0 ]; then
        echo "$(date '+%m-%d %H:%M') | 所有Really文件检查和清理完成" >&2
    else
        echo "$(date '+%m-%d %H:%M') | 处理过程中发生错误，请检查 $REALLY_DIR 权限或文件" >&2
        return 1
    fi
}
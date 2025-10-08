#!/bin/bash
#VERSION="1.0.2"
# 清理旧日志
cleanup_logs() {
    local log_retention_days=7
    if [ -z "$LOG_DIR" ]; then
        echo "$(date '+%m-%d %H:%M') | LOG_DIR 未定义，默认使用 /storage/emulated/0/Wallpaper/.Cores/Logs" >&2
        LOG_DIR="/storage/emulated/0/Wallpaper/.Cores/Logs"
    fi
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        echo "$(date '+%m-%d %H:%M') | 创建日志目录：$LOG_DIR" >&2
    fi
    if [ ! -w "$LOG_DIR" ]; then
        echo "$(date '+%m-%d %H:%M') | 日志目录 $LOG_DIR 无写权限，尝试修复" >&2
        chmod -R 755 "$LOG_DIR" 2>/dev/null
        if [ ! -w "$LOG_DIR" ]; then
            echo "$(date '+%m-%d %H:%M') | 无法修复 $LOG_DIR 权限，跳过日志清理" >&2
            return 1
        fi
    fi
    echo "$(date '+%m-%d %H:%M') | 执行清理日志备份" >&2
    find "$LOG_DIR" -type f -name "cron_log_*.txt" -mtime +$log_retention_days -delete 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "$(date '+%m-%d %H:%M') | 清理超过 $log_retention_days 天的日志备份成功" >&2
    else
        echo "$(date '+%m-%d %H:%M') | 日志清理失败，请检查 $LOG_DIR 权限或 find 命令" >&2
    fi
}
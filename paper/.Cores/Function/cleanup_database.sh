#!/bin/bash
#VERSION="1.0.2"
#清理数据库
cleanup_database() {
    local max_age_days=30
    local max_entries=4000
    if [ -f "$DB_FILE" ]; then
        # 获取当前时间
        local current_time
        current_time=$(date +%s)
        local max_age_seconds=$(( max_age_days * 86400 ))  # 转换为秒

        # 删除超过 max_age_days 的记录
        sqlite3 "$DB_FILE" "DELETE FROM downloaded WHERE created_at < ($current_time - $max_age_seconds);" || {
            echo "$(date '+%m-%d %H:%M') | 无法删除过期记录：$DB_FILE" >&2
            return 1
        }
        local deleted_rows
        deleted_rows=$(sqlite3 "$DB_FILE" "SELECT changes();")
        if [ "$deleted_rows" -gt 0 ]; then
            echo "$(date '+%m-%d %H:%M') | 数据轮转：删除了 $deleted_rows 条过期记录" >&2
        fi

        # 检查条目数并清理最早的记录
        local entry_count
        entry_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM downloaded;")
        if [ "$entry_count" -gt "$max_entries" ]; then
            local rows_to_delete=$(( entry_count - max_entries ))
            echo "$(date '+%m-%d %H:%M') | 数据库条目数 ($entry_count) 超过 $max_entries，开始清理最早的记录" >&2
            # 删除最早的 rows_to_delete 条记录
            sqlite3 "$DB_FILE" "DELETE FROM downloaded WHERE rowid IN (SELECT rowid FROM downloaded ORDER BY created_at ASC LIMIT $rows_to_delete);" || {
                echo "$(date '+%m-%d %H:%M') | 无法删除最早的 $rows_to_delete 条记录：$DB_FILE" >&2
                return 1
            }
            local deleted_rows_new
            deleted_rows_new=$(sqlite3 "$DB_FILE" "SELECT changes();")
            if [ "$deleted_rows_new" -gt 0 ]; then
                echo "$(date '+%m-%d %H:%M') | 成功删除 $deleted_rows_new 条最早的记录" >&2
            fi
        else
            echo "$(date '+%m-%d %H:%M') | 数据库条目数 ($entry_count) 未超过 $max_entries，无需清理" >&2
        fi
    else
        # 新建数据库
        sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS downloaded (url TEXT PRIMARY KEY, created_at INTEGER NOT NULL);" || {
            echo "$(date '+%m-%d %H:%M') | 无法创建数据库表：$DB_FILE" >&2
            return 1
        }
        echo "$(date '+%m-%d %H:%M') | 数据库创建成功：$DB_FILE" >&2
    fi
}
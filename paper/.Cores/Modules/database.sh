#!/bin/bash
# 初始化数据库
#VERSION="1.0.2"
if [ -f "$DB_FILE" ]; then
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS downloaded (url TEXT PRIMARY KEY, created_at INTEGER NOT NULL);" || {
        echo "$(date '+%m-%d %H:%M') | 无法创建数据库表：$DB_FILE" >&2
        exit 1
        }
    echo "$(date '+%m-%d %H:%M') | 数据库初始化成功" >&2
fi
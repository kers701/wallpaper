#!/bin/bash
#VERSION="1.0.2"
# 日志记录函数
log_message() {
    echo "$(date '+%m-%d %H:%M') | $1" >&2  # 输出到标准错误，不写入文件
}
# 检查函数目录
if [ ! -d "$FUNCTION_DIR" ]; then
    log_message "错误：函数目录 $FUNCTION_DIR 不存在"
    exit 1
fi

# 加载所有函数文件
for func_file in "$FUNCTION_DIR"/*.sh; do
    if [ -f "$func_file" ]; then
        if ! source "$func_file"; then
            exit 1
        fi
    fi
done
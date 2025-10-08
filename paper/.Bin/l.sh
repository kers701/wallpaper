#!/bin/bash
#VERSION="1.0.2"
# 定义模块目录
MODULE_DIR="/storage/emulated/0/Wallpaper/.Cores/Modules"

# 加载模块
for module in init.sh message.sh database.sh parse_args.sh setup.sh keywords_update.sh main_loop.sh; do
    module_path="$MODULE_DIR/$module"
    if [ -f "$module_path" ]; then
        source "$module_path"
    else
        echo "$(date '+%m-%d %H:%M') | 错误：模块 $module_path 不存在" >&2
        exit 1
    fi
done
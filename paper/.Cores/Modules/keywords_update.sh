#!/bin/bash

# keywords_update.sh
# 加载关键词并检查旧文件行数变化以自动更新，同时加载关键词映射
# 优化：在 suppr_file 行数大于 legacy_keywords 行数 1/2 时，更新关键词后清空 suppr_file

# 定义目录和文件路径
KEYWORD_DIR="/storage/emulated/0/Wallpaper/.Cores/Keywords"
SUPPR_DIR="/storage/emulated/0/Wallpaper/.Cores/Supprs"
LOG_DIR="/storage/emulated/0/Wallpaper/.Cores/Logs"
legacy_keywords="/data/data/com.termux/files/home/keywords"
keyword_file="$KEYWORD_DIR/keywords"
suppr_file="$SUPPR_DIR/Suppr.txt"
log_file="$LOG_DIR/keywords_update.log"

# 确保日志目录存在
mkdir -p "$LOG_DIR" || { echo "无法创建日志目录 $LOG_DIR"; exit 1; }

# 初始化日志
: > "$log_file" || { echo "无法创建日志文件 $log_file"; exit 1; }
echo "$(date '+%m-%d %H:%M') | 脚本开始执行" >> "$log_file"

# 检查关键词目录是否存在
if [ ! -d "$KEYWORD_DIR" ]; then
    echo "$(date '+%m-%d %H:%M') | 关键词目录 $KEYWORD_DIR 不存在" >> "$log_file"
    exit 1
fi

# 创建备份文件防止脚本崩溃文件损坏
cp "$legacy_keywords" "/storage/emulated/0/Wallpaper/.Cores/.bak/.keywords-y" 2>/dev/null
cp "$keyword_file" "/storage/emulated/0/Wallpaper/.Cores/.bak/.keywords" 2>/dev/null
cp "$KEYWORD_DIR/query_map" "/storage/emulated/0/Wallpaper/.Cores/.bak/query_map" 2>/dev/null
cp "$suppr_file" "/storage/emulated/0/Wallpaper/.Cores/.bak/.suppr" 2>/dev/null

# 加载关键词映射
declare -A QUERY_MAP
if [ -s "$KEYWORD_DIR/query_map" ]; then
    while IFS='|' read -r key value; do
        QUERY_MAP["$key"]="$value"
    done < "$KEYWORD_DIR/query_map"
else
    echo "$(date '+%m-%d %H:%M') | 关键词映射文件 $KEYWORD_DIR/query_map 不存在或为空" >> "$log_file"
    exit 1
fi

# 定义分类映射
declare -A CATEGORY_MAP=(
    ["zr"]="人物"
    ["dm"]="动漫"
    ["lh"]="轮换"
)

# 执行 Python 脚本（假设用于初始化或预处理）
python /data/data/com.termux/files/home/gl.py >/dev/null

# 检查原始文件
if [ -f "$legacy_keywords" ]; then
    legacy_line_count=$(wc -l < "$legacy_keywords")
    echo "$(date '+%m-%d %H:%M') | 原始文件行数: $legacy_line_count" >> "$log_file"
else
    echo "$(date '+%m-%d %H:%M') | 原始文件 $legacy_keywords 不存在" >> "$log_file"
    exit 1
fi

# 检查 Suppr 文件并清理不存在的关键词
if [ -f "$suppr_file" ]; then
    suppr_line_count=$(wc -l < "$suppr_file")
    echo "$(date '+%m-%d %H:%M') | Suppr 文件行数: $suppr_line_count" >> "$log_file"

    # 创建临时文件用于保存过滤后的 Suppr 内容
    temp_suppr_file="${suppr_file}.tmp"
    : > "$temp_suppr_file" || {
        echo "$(date '+%m-%d %H:%M') | 创建临时 Suppr 文件 $temp_suppr_file 失败" >> "$log_file"
        exit 1
    }

    # 过滤不存在的关键词
    grep -Fix -f "$suppr_file" "$legacy_keywords" > "$temp_suppr_file" || {
        echo "$(date '+%m-%d %H:%M') | 过滤 Suppr 关键词失败" >> "$log_file"
    }
    mv "$temp_suppr_file" "$suppr_file" || {
        echo "$(date '+%m-%d %H:%M') | 替换 Suppr 文件失败" >> "$log_file"
        exit 1
    }
    suppr_line_count=$(wc -l < "$suppr_file")
    echo "$(date '+%m-%d %H:%M') | 清理后 Suppr 文件行数: $suppr_line_count" >> "$log_file"
else
    echo "$(date '+%m-%d %H:%M') | Suppr 文件不存在" >> "$log_file"
    suppr_line_count=0
fi

# 检查是否需要清空 Suppr 文件
if [ -f "$suppr_file" ] && [ "$suppr_line_count" -gt $((legacy_line_count / 2)) ]; then
    echo "$(date '+%m-%d %H:%M') | Suppr 文件行数 ($suppr_line_count) 大于 keywords 文件行数 ($legacy_line_count) 的一半，将在更新后清空 Suppr 文件" >> "$log_file"
    clear_suppr=1
else
    clear_suppr=0
fi

# 清空目标文件并复制
: > "$keyword_file"
if [ -s "$legacy_keywords" ]; then
    cp "$legacy_keywords" "$keyword_file" || {
        echo "$(date '+%m-%d %H:%M') | 从 $legacy_keywords 复制到 $keyword_file 失败" >> "$log_file"
        exit 1
    }
    echo "$(date '+%m-%d %H:%M') | 成功复制关键词文件" >> "$log_file"
else
    echo "$(date '+%m-%d %H:%M') | 旧文件 $legacy_keywords 为空" >> "$log_file"
    exit 1
fi

# 清理文件：移除空白行、首尾空格、换行符、重复空格
if [ -f "$keyword_file" ]; then
    original_lines=$(wc -l < "$keyword_file")
    sed -i '/^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/\r$//; s/[[:space:]]\+/ /g' "$keyword_file" || {
        echo "$(date '+%m-%d %H:%M') | sed 清理失败，保留原始文件" >> "$log_file"
        exit 1
    }
    current_lines=$(wc -l < "$keyword_file")
    echo "$(date '+%m-%d %H:%M') | 格式调整移除 $((original_lines - current_lines)) 行 (原始: $original_lines, 当前: $current_lines)" >> "$log_file"
fi
if [ -f "$suppr_file" ]; then
    sed -i '/^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/\r$//; s/[[:space:]]\+/ /g' "$suppr_file"
fi

# 检查 keyword_file 是否有效
if [ ! -s "$keyword_file" ]; then
    echo "$(date '+%m-%d %H:%M') | $keyword_file 为空" >> "$log_file"
    exit 1
fi

# 过滤关键词（忽略大小写）
if [ -s "$suppr_file" ]; then
    pre_filter_lines=$(wc -l < "$keyword_file")
    temp_file="${keyword_file}.tmp"
    grep -vxiF -f "$suppr_file" "$keyword_file" > "$temp_file" || {
        echo "$(date '+%m-%d %H:%M') | 过滤关键词失败" >> "$log_file"
        exit 1
    }
    mv "$temp_file" "$keyword_file" || {
        echo "$(date '+%m-%d %H:%M') | 替换关键词文件失败" >> "$log_file"
        exit 1
    }
    post_filter_lines=$(wc -l < "$keyword_file")
    echo "$(date '+%m-%d %H:%M') | 过滤移除 $((pre_filter_lines - post_filter_lines)) 行 (前: $pre_filter_lines, 后: $post_filter_lines)" >> "$log_file"
fi

# 去重关键词文件
pre_dedup_lines=$(wc -l < "$keyword_file")
sort -u "$keyword_file" > "${keyword_file}.tmp" && mv "${keyword_file}.tmp" "$keyword_file" || {
    echo "$(date '+%m-%d %H:%M') | 去重关键词文件失败" >> "$log_file"
    exit 1
}
post_dedup_lines=$(wc -l < "$keyword_file")

# 加载最终关键词
mapfile -t KEYWORDS_QUERIES < <(grep -v '^[[:space:]]*$' "$keyword_file")
echo "$(date '+%m-%d %H:%M') | 更新关键词完成，剩余关键词数: ${#KEYWORDS_QUERIES[@]}" >> "$log_file"
echo "$(date '+%m-%d %H:%M') | Update Keywords <${#KEYWORDS_QUERIES[@]}>" >&2

# 清空 Suppr 文件（如果需要）
if [ "$clear_suppr" -eq 1 ]; then
    : > "$suppr_file" || {
        echo "$(date '+%m-%d %H:%M') | 清空 Suppr 文件 $suppr_file 失败" >> "$log_file"
        exit 1
    }
    echo "$(date '+%m-%d %H:%M') | Suppr 文件已清空" >> "$log_file"
fi
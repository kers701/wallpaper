# 函数：检查旧文件行数并在变化时删除关键词文件（无日志输出）
check_legacy_line_count() {
    local legacy_keywords="/data/data/com.termux/files/home/keywords"
    local line_count_file="/storage/emulated/0/Wallpaper/.Cores/Keywords/.line_counts"
    local keywords_count=0
    local prev_keywords_count=0

    # 计算当前行数（忽略空行）
    if [ -f "$legacy_keywords" ] && [ -s "$legacy_keywords" ]; then
        keywords_count=$(grep -v '^[[:space:]]*$' "$legacy_keywords" | wc -l)
    fi

    # 读取上次记录的行数
    if [ -f "$line_count_file" ]; then
        prev_keywords_count=$(grep '^keywords:' "$line_count_file" | cut -d':' -f2 || echo 0)
    fi

    # 检查行数是否变化
    if [ "$keywords_count" -ne "$prev_keywords_count" ]; then
        # 删除关键词文件以触发更新
        rm -f "$KEYWORD_DIR/keywords" 2>/dev/null
    fi

    # 更新行数记录
    echo "keywords:$keywords_count" > "$line_count_file" 2>/dev/null
}
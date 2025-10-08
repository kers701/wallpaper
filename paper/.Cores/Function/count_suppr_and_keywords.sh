# 输出Suppr文件和关键词文件的关键词个数
count_suppr_and_keywords() {
    local suppr_file="$SUPPR_FILE"
    local keyword_file
    local legacy_keyword_file

    # 确定关键词文件路径
    keyword_file="/storage/emulated/0/Wallpaper/.Cores/Keywords/keywords"
    legacy_keyword_file="/data/data/com.termux/files/home/keywords"

    # 确保Upgrades目录存在
    local upgrades_dir="/storage/emulated/0/Wallpaper/.Cores/Keywords"
    if [ ! -d "$upgrades_dir" ]; then
        mkdir -p "$upgrades_dir" 2>/dev/null
    fi

    # 确保关键词文件存在，若不存在则从legacy文件复制
    if [ ! -f "$keyword_file" ]; then
        echo "$(date '+%m-%d %H:%M') | 创建关键词文件" >&2
        touch "$keyword_file" 2>/dev/null
        if [ -f "$legacy_keyword_file" ] && [ -s "$legacy_keyword_file" ]; then
            cp "$legacy_keyword_file" "$keyword_file" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "$(date '+%m-%d %H:%M') | 创建成功" >&2
            else
                echo "$(date '+%m-%d %H:%M') | 创建失败" >&2
            fi
        fi
    fi

    # 确保Suppr文件存在
    if [ ! -f "$suppr_file" ]; then
        echo "$(date '+%m-%d %H:%M') | Suppr文件<$suppr_file>不存在，创建空文件" >&2
        touch "$suppr_file" 2>/dev/null
    fi

    # 统计关键词个数（只计数非空行）
    local suppr_count=$(grep -c -v '^[[:space:]]*$' "$suppr_file")
    local keyword_count=$(grep -c -v '^[[:space:]]*$' "$keyword_file")
    local total_count=$((suppr_count + keyword_count))

    # 输出格式：Update suppr个数/总数
    echo "$(date '+%m-%d %H:%M') | Update Suppr $suppr_count/$total_count/$keyword_count" >&2

    return 0
}
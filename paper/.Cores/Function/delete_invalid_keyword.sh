# 新增函数：删除无效关键词
delete_invalid_keyword() {
    local welfare_file="/data/data/com.termux/files/home/keywords"
    local query_map_file="/storage/emulated/0/Wallpaper/.Cores/Keywords/query_map"
    local temp_file="/storage/emulated/0/Wallpaper/.Cores/Tmps/temp_$$.txt"
    local keyword_to_delete="$normalized_search_query"

    # 删除 welfare.txt 中的关键词（忽略大小写，整行匹配）
    if [ -f "$welfare_file" ]; then
        grep -vi "^$keyword_to_delete$" "$welfare_file" > "$temp_file"
        if [ $? -eq 0 ]; then
            mv -f "$temp_file" "$welfare_file"
            echo "$(date '+%m-%d %H:%M') | 从 $welfare_file 删除无效关键词：$keyword_to_delete" >&2
        else
            echo "$(date '+%m-%d %H:%M') | 删除 $welfare_file 关键词失败，检查权限" >&2
            rm -f "$temp_file"
        fi
    fi

    # 删除 query_map 中的关键词（匹配 | 前的英文，忽略大小写）
    if [ -f "$query_map_file" ]; then
        grep -vi "^$keyword_to_delete|" "$query_map_file" > "$temp_file"
        if [ $? -eq 0 ]; then
            mv -f "$temp_file" "$query_map_file"
            echo "$(date '+%m-%d %H:%M') | 从 $query_map_file 删除无效关键词：$keyword_to_delete" >&2
        else
            echo "$(date '+%m-%d %H:%M') | 删除 $query_map_file 关键词失败，检查权限" >&2
            rm -f "$temp_file"
        fi
    fi
}
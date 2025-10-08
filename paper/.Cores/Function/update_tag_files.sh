# 更新标签文件并去重
update_tag_files() {
    local temp_tag_file="$1"
    local welfare_file="/data/data/com.termux/files/home/keywords"
    local temp_welfare="/data/data/com.termux/files/home/welfare_temp_$$"
    local temp_dm="/data/data/com.termux/files/home/dm_temp_$$"

    # 日志函数
    log_info() { echo "$(date '+%m-%d %H:%M') | $1" >&2; }
    log_error() { echo "$(date '+%m-%d %H:%M') | 错误: $1" >&2; }

    # 检查临时标签文件是否存在且不为空
    if [ ! -s "$temp_tag_file" ]; then
        log_info "临时标签文件为空或不存在，跳过去重"
        return 0
    fi

    # 确保目标文件存在
    touch "$welfare_file" "$dm_file" 2>/dev/null
    if [ ! -w "$welfare_file" ]; then
        log_error "目标文件不可写：$welfare_file"
        return 1
    fi

    # 追加到 welfare.txt 并去重（忽略大小写）
    cat "$temp_tag_file" >> "$welfare_file"
    sort -u -f "$welfare_file" > "$temp_welfare"
    mv "$temp_welfare" "$welfare_file"

    # 所有文件更新完成后输出成功日志
    log_info "写入Keyword文件成功"

    return 0
}
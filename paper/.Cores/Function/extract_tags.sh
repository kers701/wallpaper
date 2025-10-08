extract_tags() {
    local img_id="$1"
    local category="$2"
    local api_key="$3"
    local error_file="/storage/emulated/0/Wallpaper/.Cores/Tmps/tag_error_$$"
    local response_file="/storage/emulated/0/Wallpaper/.Cores/Tmps/tag_response_$$"
    local temp_tag_file="/storage/emulated/0/Wallpaper/.Cores/Tmps/temp_tags_$$"
    local max_retries=2
    local retry_delay=2
    local tag_count=0
    local exclude_count=0

    # 日志函数
    log_info() { echo "$(date '+%m-%d %H:%M') | $1" >&2; }
    log_error() { echo "$(date '+%m-%d %H:%M') | 错误: $1" >&2; }

    # 验证 img_id 格式
    if [[ ! "$img_id" =~ ^[a-zA-Z0-9]{6}$ ]]; then
        log_error "无效的壁纸 ID：$img_id，跳过标签提取"
        return 1
    fi

    # 确保临时目录存在
    mkdir -p "/storage/emulated/0/Wallpaper/.Cores/Tmps" 2>/dev/null
    if [ ! -w "/storage/emulated/0/Wallpaper/.Cores/Tmps" ]; then
        log_error "临时目录不可写：/storage/emulated/0/Wallpaper/.Cores/Tmps，跳过标签提取"
        return 1
    fi

    # 读取 country 文件
    local country_file="/storage/emulated/0/Wallpaper/.Cores/Keywords/country"
    local countries=()
    if [ -r "$country_file" ]; then
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            countries+=("$line")
        done < "$country_file"
    fi

    log_info "开始提取壁纸标签"
    local attempt=1
    while [ $attempt -le $max_retries ]; do
        : > "$error_file"
        : > "$response_file"

        # 执行 curl 请求
        local http_code
        curl -4 --tlsv1.2 -s --max-time 15 \
            "https://wallhaven.cc/api/v1/w/$img_id?apikey=$api_key" -o "$response_file" 2> "$error_file"
        http_code=$?
        [ $http_code -eq 0 ] && [ -s "$response_file" ] && http_code=200 || \
            http_code=$(curl -s -I "https://wallhaven.cc/api/v1/w/$img_id?apikey=$api_key" 2>/dev/null | awk '/^HTTP/{print $2}' || echo "unknown")

        if [ "$http_code" != "200" ]; then
            log_error "标签请求失败（尝试 $attempt/$max_retries，HTTP 状态码：$http_code）"
            attempt=$((attempt + 1))
            [ $attempt -le $max_retries ] && sleep $retry_delay || { cleanup; return 1; }
            continue
        fi

        # 读取响应
        local tag_response
        tag_response=$(cat "$response_file" 2>/dev/null)
        if [ -z "$tag_response" ]; then
            log_error "标签响应为空（尝试 $attempt/$max_retries）"
            attempt=$((attempt + 1))
            [ $attempt -le $max_retries ] && sleep $retry_delay || { cleanup; return 1; }
            continue
        fi

        # 检查 API 错误
        local error
        error=$(echo "$tag_response" | jq -r '.error // null' 2>/dev/null || echo "jq_error")
        if [ "$error" != "null" ] && [ -n "$error" ]; then
            log_error "API 错误（尝试 $attempt/$max_retries）：$error"
            attempt=$((attempt + 1))
            [ $attempt -le $max_retries ] && sleep $retry_delay || { cleanup; return 1; }
            continue
        fi

        # 提取标签
        local tags
        tags=$(echo "$tag_response" | jq -r '.data.tags[].name' 2>/dev/null)
        if [ -z "$tags" ]; then
            log_error "壁纸 $img_id 无标签或解析失败"
            attempt=$((attempt + 1))
            [ $attempt -le $max_retries ] && sleep $retry_delay || { cleanup; return 1; }
            continue
        fi

        # 写入标签并计数
        : > "$temp_tag_file"
        while IFS= read -r tag; do
            [ -z "$tag" ] && continue

            # 忽略年份标签
            if [[ "$tag" =~ ^[0-9]{4}[[:space:]]*\(.*[Yy]ear.*\)$ ]]; then
                continue
            fi
                # 忽略“纯数字加 px”的标签（不区分大小写）
            if [[ "${tag,,}" =~ ^[0-9]+px$ ]]; then
                continue
            fi

               # 忽略纯数字标签
            if [[ "$tag" =~ ^[0-9]+$ ]]; then
                continue
            fi
            # 忽略国家标签
            local is_country=0
            for country in "${countries[@]}"; do
                if [[ "${tag,,}" == "${country,,}" ]]; then
                    is_country=1
                    break
                fi
            done
            [ $is_country -eq 1 ] && continue

            # 检查 Exclude 过滤
            local exclude_match=0
            for exclude in "${exclude_tags[@]}"; do
                local encoded_exclude
                encoded_exclude=$(encode_tag "$exclude")
                # 转换为小写，处理大小写不敏感
                local tag_lower="${tag,,}"
                local exclude_lower="${exclude,,}"
                # 广义匹配：单词或词组
                if [[ "$tag_lower" =~ $exclude_lower ]]; then
                    exclude_match=1
                    exclude_count=$((exclude_count + 1))
                    break
                fi
            done

            # 若未匹配排除词，写入标签
            if [ $exclude_match -eq 0 ]; then
                echo "$tag" >> "$temp_tag_file"
                tag_count=$((tag_count + 1))
            fi
        done <<< "$tags"

        # 输出排除标签计数
        if [ $exclude_count -gt 0 ]; then
            log_info "触发Exclude,过滤$exclude_count个标签"
        fi

        # 检查是否提取到有效标签
        if [ -s "$temp_tag_file" ]; then
            log_info "提取成功，更新 $tag_count 个标签"
            update_tag_files "$temp_tag_file"
            if command -v python > /dev/null 2>&1; then
                python /storage/emulated/0/Wallpaper/.Bin/tags.py "$temp_tag_file"
            else
                log_error "未找到 Python 环境，跳过标签翻译"
            fi
        else
            log_info "壁纸 $img_id 无有效标签，跳过处理"
        fi
        cleanup
        return 0
    done
    log_error "达到最大重试次数，跳过壁纸 $img_id 的标签提取"
    cleanup
    return 1
}

cleanup() {
    rm -f "$response_file" "$error_file" "$temp_tag_file" 2>/dev/null
}
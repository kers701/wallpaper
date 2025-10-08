download_page() {
    # 定义文件路径
    LOG_DIR="/storage/emulated/0/Wallpaper/.Cores/Logs"
    log_file="$LOG_DIR/run_log"

    # 确保日志目录存在
    mkdir -p "$LOG_DIR" || { echo "$(date '+%m-%d %H:%M') | 无法创建日志目录 $LOG_DIR" >&2; exit 1; }

    # 记录接收到的变量
    #echo "$(date '+%m-%d %H:%M') | 接收到 SEARCH_QUERY: $SEARCH_QUERY, WELFARE_QUERY: $WELFARE_QUERY, SEARCH_DISPLAY: $SEARCH_DISPLAY, category: $category" >&2

    echo "$(date '+%m-%d %H:%M') | 开始匹配Max参数" >&2
    # 移除小写转换，仅规范化空格
    normalized_search_query=$(echo "$SEARCH_QUERY" | tr -s ' ')
    last_page=$(grep "^$normalized_search_query|" "$CACHE_FILE" | cut -d'|' -f2)
    if [ -n "$last_page" ] && [[ "$last_page" =~ ^[0-9]+$ ]] && [ "$last_page" -ge 1 ]; then
        echo "$(date '+%m-%d %H:%M') | 获取到Max参数：$last_page" >&2
    else
        echo "$(date '+%m-%d %H:%M') | 无Max参数，开始构造提取" >&2
        local max_retries=1
        local download_retry=2
        local retry_delay=2
        local attempt=1
        if [ "$category" == "zr" ]; then
            # 移除小写转换，仅规范化空格并编码
            ENCODED_QUERY=$(echo "$WELFARE_QUERY" | tr -s ' ' | sed 's/ /%20/g; s/+/%2B/g; s/&/%26/g; s/=/%3D/g')
        else
            # 移除小写转换，仅规范化空格并编码
            ENCODED_QUERY=$(echo "$ANIME_QUERY_TERM" | tr -s ' ' | sed 's/ /%20/g; s/+/%2B/g; s/&/%26/g; s/=/%3D/g')
        fi
        while [ $attempt -le $max_retries ]; do
            api_url="https://wallhaven.cc/api/v1/search?q=$ExcludeWords$ENCODED_QUERY&page=1&purity=$purity&$CATEGORY_FILTER&sorting=${SORT_ORDER}&atleast=${MIN_WIDTH}x${MIN_HEIGHT}&apikey=${API_KEY}"
            echo "$(date '+%m-%d %H:%M') | 整合参数执行API请求" >&2
            response=$(curl -4 --tlsv1.2 -s --max-time 15 --retry 1 --retry-delay 2 "$api_url" 2> "/storage/emulated/0/Wallpaper/.Cores/Tmps/curl_error_$$")
            curl_error=$(cat "/storage/emulated/0/Wallpaper/.Cores/Tmps/curl_error_$$")
            rm -f "/storage/emulated/0/Wallpaper/.Cores/Tmps/curl_error_$$"
            if [ -n "$curl_error" ]; then
                echo "$(date '+%m-%d %H:%M') | curl 错误：$curl_error" >&2
            fi
            error=$(echo "$response" | jq -r '.error // null')
            if [ -n "$response" ] && [ "$error" == "null" ] && [ "$(echo "$response" | jq -r '.data?')" != "null" ]; then
                last_page=$(echo "$response" | jq -r '.meta.last_page // 100')
                if [ -z "$last_page" ] || [ "$last_page" -lt 1 ]; then
                    echo "$(date '+%m-%d %H:%M') | 无法提取最大页数，默认使用 100" >&2
                    last_page=100
                fi
                data_count=$(echo "$response" | jq -r '.data | length')
                if [ "$data_count" -eq 0 ]; then
                    echo "$(date '+%m-%d %H:%M') | 第一页无数据，重试..." >&2
                    if [ $attempt -eq $max_retries ]; then
                        echo "$(date '+%m-%d %H:%M') | 达到最大重试次数，尝试仅保留关键词重新请求：$SEARCH_DISPLAY" >&2
                        # 仅保留关键词重新请求第一页
                        api_url="https://wallhaven.cc/api/v1/search?q=$ExcludeWords$ENCODED_QUERY&page=1&apikey=${API_KEY}"
                        response=$(curl -4 --tlsv1.2 -s --max-time 15 --retry 1 --retry-delay 2 "$api_url" 2> "/storage/emulated/0/Wallpaper/.Cores/Tmps/curl_error_$$")
                        curl_error=$(cat "/storage/emulated/0/Wallpaper/.Cores/Tmps/curl_error_$$")
                        rm -f "/storage/emulated/0/Wallpaper/.Cores/Tmps/curl_error_$$"
                        if [ -n "$curl_error" ]; then
                            echo "$(date '+%m-%d %H:%M') | curl 错误（仅关键词请求）：$curl_error" >&2
                        fi
                        error=$(echo "$response" | jq -r '.error // null')
                        data_count=$(echo "$response" | jq -r '.data | length')
                        if [ -n "$response" ] && [ "$error" == "null" ] && [ "$data_count" -eq 0 ]; then
                            echo "$(date '+%m-%d %H:%M') | 验证关键词$SEARCH_DISPLAY有效性" >&2
                            # 删除关键词
                            if [ "$category" == "zr" ]; then
                                keyword_file="/data/data/com.termux/files/home/keywords"
                            else
                                keyword_file="/data/data/com.termux/files/home/keywords"
                            fi
                            # 从 keyword_file 删除整行（保留大小写）
                            grep -v "^$SEARCH_QUERY$" "$keyword_file" > "/storage/emulated/0/Wallpaper/.Cores/Tmps/keyword_tmp_$$" || true
                            mv -f "/storage/emulated/0/Wallpaper/.Cores/Tmps/keyword_tmp_$$" "$keyword_file"
                            # 从 query_map 删除匹配 | 前英文的部分（保留大小写）
                            grep -v "^$normalized_search_query|" "/storage/emulated/0/Wallpaper/.Cores/Keywords/query_map" > "/storage/emulated/0/Wallpaper/.Cores/Tmps/query_map_tmp_$$" || true
                            mv -f "/storage/emulated/0/Wallpaper/.Cores/Tmps/query_map_tmp_$$" "/storage/emulated/0/Wallpaper/.Cores/Keywords/query_map"
                            echo "$(date '+%m-%d %H:%M') | 已从 $keyword_file 和 query_map 删除关键词：$SEARCH_QUERY" >&2
                            return 1
                        fi
                        echo "$(date '+%m-%d %H:%M') | 关键词$SEARCH_QUERY有效" >&2
                        return 1
                    fi
                    sleep $retry_delay
                    attempt=$((attempt + 1))
                    continue
                fi
                local timestamp=$(date +%s)
                local cache_entry="$normalized_search_query|$last_page|$timestamp"
                grep -v "^$normalized_search_query|" "$CACHE_FILE" > "/storage/emulated/0/Wallpaper/.Cores/Pages/cache_tmp_$$" || true
                echo "$cache_entry" >> "/storage/emulated/0/Wallpaper/.Cores/Pages/cache_tmp_$$"
                mv -f "/storage/emulated/0/Wallpaper/.Cores/Pages/cache_tmp_$$" "$CACHE_FILE"
                echo "$(date '+%m-%d %H:%M') | 获取到最大页数：$last_page 添加关键词<$SEARCH_DISPLAY> 到Max文件" >&2
                break
            else
                echo "$(date '+%m-%d %H:%M') | API 请求失败（尝试 $attempt/$max_retries）" >&2
                if [ $attempt -eq $max_retries ]; then
                    echo "$(date '+%m-%d %H:%M') | 达到最大重试次数，尝试仅保留关键词重新请求：$SEARCH_DISPLAY" >&2
                    # 仅保留关键词重新请求第一页
                    api_url="https://wallhaven.cc/api/v1/search?q=$ExcludeWords$ENCODED_QUERY&page=1&apikey=${API_KEY}"
                    response=$(curl -4 --tlsv1.2 -s --max-time 15 --retry 1 --retry-delay 2 "$api_url" 2> "/storage/emulated/0/Wallpaper/.Cores/Tmps/curl_error_$$")
                    curl_error=$(cat "/storage/emulated/0/Wallpaper/.Cores/Tmps/curl_error_$$")
                    rm -f "/storage/emulated/0/Wallpaper/.Cores/Tmps/curl_error_$$"
                    if [ -n "$curl_error" ]; then
                        echo "$(date '+%m-%d %H:%M') | curl 错误（仅关键词请求）：$curl_error" >&2
                    fi
                    error=$(echo "$response" | jq -r '.error // null')
                    data_count=$(echo "$response" | jq -r '.data | length')
                    if [ -n "$response" ] && [ "$error" == "null" ] && [ "$data_count" -eq 0 ]; then
                        echo "$(date '+%m-%d %H:%M') | 验证关键词$SEARCH_DISPLAY有效性" >&2
                        # 删除关键词
                        if [ "$category" == "zr" ]; then
                            keyword_file="/data/data/com.termux/files/home/keywords"
                        else
                            keyword_file="/data/data/com.termux/files/home/keywords"
                        fi
                        # 从 keyword_file 删除整行（保留大小写）
                        grep -v "^$SEARCH_QUERY$" "$keyword_file" > "/storage/emulated/0/Wallpaper/.Cores/Tmps/keyword_tmp_$$" || true
                        mv -f "/storage/emulated/0/Wallpaper/.Cores/Tmps/keyword_tmp_$$" "$keyword_file"
                        # 从 query_map 删除匹配 | 前英文的部分（保留大小写）
                        grep -v "^$normalized_search_query|" "/storage/emulated/0/Wallpaper/.Cores/Keywords/query_map" > "/storage/emulated/0/Wallpaper/.Cores/Tmps/query_map_tmp_$$" || true
                        mv -f "/storage/emulated/0/Wallpaper/.Cores/Tmps/query_map_tmp_$$" "/storage/emulated/0/Wallpaper/.Cores/Keywords/query_map"
                        echo "$(date '+%m-%d %H:%M') | 已从 $keyword_file 和 query_map 删除关键词：$SEARCH_QUERY" >&2
                        return 1
                    fi
                    echo "$(date '+%m-%d %H:%M') | 仅关键词请求获取到数据，重新选择关键词：$SEARCH_DISPLAY" >&2
                    return 1
                fi
                sleep $retry_delay
                attempt=$((attempt + 1))
            fi
        done
    fi
    local page_attempts=0
    local valid_image_found=0
    local consecutive_no_result=0
    skipped_downloaded=0
    local -a tried_pages=()
    while [ ${#tried_pages[@]} -lt "$last_page" ]; do
        if [ $consecutive_no_result -ge 7 ]; then
            PAGE=1
            echo "$(date '+%m-%d %H:%M') | 连续 $consecutive_no_result 次无结果，强制请求页面 1" >&2
            if [[ ! " ${tried_pages[*]} " =~ " $PAGE " ]]; then
                tried_pages+=("$PAGE")
            fi
        else
            while true; do
                PAGE=$((RANDOM % last_page + 1))
                if [[ ! " ${tried_pages[*]} " =~ " $PAGE " ]]; then
                    tried_pages+=("$PAGE")
                    break
                fi
            done
        fi
        echo "$(date '+%m-%d %H:%M') | 选择页面 $PAGE/$last_page (已尝试 ${#tried_pages[@]}/$last_page)" >&2
        api_url="https://wallhaven.cc/api/v1/search?q=$ExcludeWords$ENCODED_QUERY&page=${PAGE}&purity=$purity&$CATEGORY_FILTER&sorting=${SORT_ORDER}&atleast=${MIN_WIDTH}x${MIN_HEIGHT}&apikey=${API_KEY}"
        sleep 2
        response=$(curl -4 --tlsv1.2 -s --max-time 15 --retry 1 --retry-delay 2 "$api_url" 2> "/storage/emulated/0/Wallpaper/.Cores/Tmps/curl_error_$$")
        curl_error=$(cat "/storage/emulated/0/Wallpaper/.Cores/Tmps/curl_error_$$")
        rm -f "/storage/emulated/0/Wallpaper/.Cores/Tmps/curl_error_$$"
        if [ -n "$curl_error" ]; then
            echo "$(date '+%m-%d %H:%M') | curl 错误：$curl_error" >&2
        fi
        if [ -z "$response" ] || [ "$(echo "$response" | jq -r '.data?')" == "null" ]; then
            echo "$(date '+%m-%d %H:%M') | API 请求失败或无数据，页面 $PAGE，重试..." >&2
            page_attempts=$((page_attempts + 1))
            consecutive_no_result=$((consecutive_no_result + 1))
            if [ $PAGE -eq 1 ] && [ $consecutive_no_result -ge 7 ]; then
                echo "$(date '+%m-%d %H:%M') | 页面 1 无结果，跳过关键词：$SEARCH_DISPLAY" >&2
                return 1
            fi
            sleep 5
            continue
        fi
        mapfile -t images < <(echo "$response" | jq -r '.data[] | "\(.path) \(.dimension_x // "unknown") \(.dimension_y // "unknown") \(.id)"')
        if [ ${#images[@]} -eq 0 ]; then
            echo "$(date '+%m-%d %H:%M') | 页面 $PAGE 无结果，重试..." >&2
            page_attempts=$((page_attempts + 1))
            consecutive_no_result=$((consecutive_no_result + 1))
            if [ $PAGE -eq 1 ] && [ $consecutive_no_result -ge 7 ]; then
                echo "$(date '+%m-%d %H:%M') | 页面 1 无结果，跳过关键词：$SEARCH_DISPLAY" >&2
                return 1
            fi
            sleep 5
            continue
        fi
        echo "$(date '+%m-%d %H:%M') | 页面 $PAGE 获取到 ${#images[@]} 张图片" >&2
        consecutive_no_result=0

        local skipped_api=0
        local image_index=1
        local processed_images=0
        for image in "${images[@]}"; do
            processed_images=$((processed_images + 1))
            read -r img_url api_dimension_x api_dimension_y img_id <<< "$image"
            echo "$(date '+%m-%d %H:%M') | 执行API请求,获取图片 $processed_images/${#images[@]}" >&2
            [ "$MODE" == "bz" ] && is_downloaded "$img_url" && {
                skipped_downloaded=$((skipped_downloaded + 1))
                echo "$(date '+%m-%d %H:%M') | 跳过已下载图片" >&2
                continue
            }
            if [ "$api_dimension_x" != "unknown" ] && [ "$api_dimension_y" != "unknown" ]; then
                if [ "$api_dimension_x" -gt "$api_dimension_y" ]; then
                    skipped_api=$((skipped_api + 1))
                    echo "$(date '+%m-%d %H:%M') | 跳过横屏壁纸 (分辨率: ${api_dimension_x}x${api_dimension_y}) 请求下一张" >&2
                    continue
                fi
                local api_aspect_ratio=$(echo "scale=4; $api_dimension_x / $api_dimension_y" | bc -l 2>/dev/null)
                if [ -z "$api_aspect_ratio" ] || ! [[ "$api_aspect_ratio" =~ ^[0-9]*\.[0-9]+$ ]]; then
                    skipped_api=$((skipped_api + 1))
                    echo "$(date '+%m-%d %H:%M') | 跳过宽高比计算失败的壁纸 (分辨率: ${api_dimension_x}x${api_dimension_y}) 请求下一张" >&2
                    continue
                fi
                local formatted_api_aspect_ratio=$(printf "0.%02d" "$(echo "$api_aspect_ratio * 100" | bc -l | cut -d'.' -f1)")
                if [ "$(echo "$api_aspect_ratio > 0.8 || $api_aspect_ratio < 0.4" | bc -l)" -eq 1 ]; then
                    skipped_api=$((skipped_api + 1))
                    echo "$(date '+%m-%d %H:%M') | 跳过宽高比不符合的壁纸 (分辨率: ${api_dimension_x}x${api_dimension_y}, 宽高比: $formatted_api_aspect_ratio) 请求下一张" >&2
                    continue
                fi
                if [ "$api_dimension_x" -lt "$MIN_WIDTH" ] || [ "$api_dimension_y" -lt "$MIN_HEIGHT" ]; then
                    skipped_api=$((skipped_api + 1))
                    echo "$(date '+%m-%d %H:%M') | 跳过低分辨率壁纸 (分辨率: ${api_dimension_x}x${api_dimension_y}) 请求下一张" >&2
                    continue
                fi
            fi
            ext="${img_url##*.}"

            # 修改文件名生成逻辑，添加兜底翻译，不写入 query_map
            if [ "$category" == "dm" ]; then
                if [ -z "$SEARCH_DISPLAY" ] || { [ "$SEARCH_DISPLAY" == "$ANIME_QUERY_TERM" ] && ! [[ "$SEARCH_DISPLAY" =~ ^[0-9A-Z]+$ ]]; }; then
                    echo "$(date '+%m-%d %H:%M') | Bottom Translation <$ANIME_QUERY_TERM>" >&2
                    SEARCH_DISPLAY=$(python /storage/emulated/0/Wallpaper/.Bin/tag.py "$ANIME_QUERY_TERM" 2>/dev/null)
                    if [ -n "$SEARCH_DISPLAY" ] && { [ "$SEARCH_DISPLAY" != "$ANIME_QUERY_TERM" ] || [[ "$SEARCH_DISPLAY" =~ ^[0-9A-Z]+$ ]]; }; then
                        echo "$(date '+%m-%d %H:%M') | Successful Translation: $ANIME_QUERY_TERM -> $SEARCH_DISPLAY" >&2
                        prefix="[动漫-$SEARCH_DISPLAY]"
                    else
                        prefix="[动漫-$ANIME_QUERY_TERM]"
                    fi
                else
                    prefix="[动漫-$SEARCH_DISPLAY]"
                fi
            else
                if [ -z "$SEARCH_DISPLAY" ] || { [ "$SEARCH_DISPLAY" == "$WELFARE_QUERY" ] && ! [[ "$SEARCH_DISPLAY" =~ ^[0-9A-Z]+$ ]]; }; then
                    echo "$(date '+%m-%d %H:%M') | Bottom Translation <$WELFARE_QUERY>" >&2
                    SEARCH_DISPLAY=$(python /storage/emulated/0/Wallpaper/.Bin/tag.py "$WELFARE_QUERY" 2>/dev/null)
                    if [ -n "$SEARCH_DISPLAY" ] && { [ "$SEARCH_DISPLAY" != "$WELFARE_QUERY" ] || [[ "$SEARCH_DISPLAY" =~ ^[0-9A-Z]+$ ]]; }; then
                        echo "$(date '+%m-%d %H:%M') | Successful Translation: $WELFARE_QUERY -> $SEARCH_DISPLAY" >&2
                        prefix="[真人-$SEARCH_DISPLAY]"
                    else
                        prefix="[真人-$WELFARE_QUERY]"
                    fi
                else
                    prefix="[真人-$SEARCH_DISPLAY]"
                fi
            fi
            echo "$(date '+%m-%d %H:%M') | 生成文件名：${prefix}${PAGE}_${count}.${ext}" >&2
            file_name="${prefix}${PAGE}_${count}.${ext}"
            file_path="$SAVE_DIR/$file_name"
            retry=0
            success=0
            while [ $retry -lt "$download_retry" ]; do
                if curl -4 --tlsv1.2 -sL --max-time 60 --retry 1 --retry-delay 2 "$img_url" -o "$file_path" && [[ -s "$file_path" ]]; then
                    success=1
                    break
                else
                    ((retry++))
                    echo "$(date '+%m-%d %H:%M') | 下载失败，重试..." >&2
                    sleep "$retry_delay"
                fi
            done
            if [ "$success" -ne 1 ]; then
                rm -f "$file_path"
                echo "$(date '+%m-%d %H:%M') | 下载失败（已重试 $download_retry 次）：$img_url" >&2
                continue
            fi
            file_size=$(stat -c %s "$file_path")
            file_size_mb=$(echo "scale=2; $file_size / 1048576" | bc -l | awk '{printf "%.2f", $0}')
            if [ "$file_size" -lt 104858 ]; then
                echo "$(date '+%m-%d %H:%M') | 壁纸文件损坏，删除：$file_name ($file_size_mb MB)" >&2
                rm -f "$file_path"
                continue
            fi
            if [ "$api_dimension_x" != "unknown" ] && [ "$api_dimension_y" != "unknown" ]; then
                width=$api_dimension_x
                height=$api_dimension_y
                if [ "$width" -gt "$height" ]; then
                    echo "$(date '+%m-%d %H:%M') | 横屏壁纸（API检测），删除：$file_name (分辨率: ${width}x${height})" >&2
                    rm -f "$file_path"
                    continue
                fi
                local aspect_ratio=$(echo "scale=4; $width / $height" | bc -l 2>/dev/null)
                if [ -z "$aspect_ratio" ] || ! [[ "$aspect_ratio" =~ ^[0-9]*\.[0-9]+$ ]]; then
                    echo "$(date '+%m-%d %H:%M') | 宽高比计算失败（API检测），删除：$file_name (分辨率: ${width}x${height})" >&2
                    rm -f "$file_path"
                    continue
                fi
                local formatted_aspect_ratio=$(printf "0.%02d" "$(echo "$aspect_ratio * 100" | bc -l | cut -d'.' -f1)")
                if [ "$(echo "$aspect_ratio > 0.8 || $aspect_ratio < 0.4" | bc -l)" -eq 1 ]; then
                    echo "$(date '+%m-%d %H:%M') | 跳过宽高比不符合的壁纸（API检测），删除：$file_name (分辨率: ${width}x${height}, 宽高比: $formatted_aspect_ratio)" >&2
                    rm -f "$file_path"
                    continue
                fi
                if [ "$width" -lt "$MIN_WIDTH" ] || [ "$height" -lt "$MIN_HEIGHT" ]; then
                    echo "$(date '+%m-%d %H:%M') | 低分辨率壁纸（API检测），删除：$file_name (分辨率: ${width}x${height})" >&2
                    rm -f "$file_path"
                    continue
                fi
            else
                width=$(identify -format "%w" "$file_path" 2>/dev/null)
                height=$(identify -format "%h" "$file_path" 2>/dev/null)
                if [ -z "$width" ] || [ -z "$height" ]; then
                    echo "$(date '+%m-%d %H:%M') | 无法获取分辨率（identify），保留文件：$file_name" >&2
                else
                    if [ "$width" -gt "$height" ]; then
                        echo "$(date '+%m-%d %H:%M') | 横屏壁纸（identify检测），删除：$file_name (分辨率: ${width}x${height})" >&2
                        rm -f "$file_path"
                        continue
                    fi
                    local aspect_ratio=$(echo "scale=4; $width / $height" | bc -l 2>/dev/null)
                    if [ -z "$aspect_ratio" ] || ! [[ "$aspect_ratio" =~ ^[0-9]*\.[0-9]+$ ]]; then
                        echo "$(date '+%m-%d %H:%M') | 宽高比计算失败（identify检测），删除：$file_name (分辨率: ${width}x${height})" >&2
                        rm -f "$file_path"
                        continue
                    fi
                    local formatted_aspect_ratio=$(printf "0.%02d" "$(echo "$aspect_ratio * 100" | bc -l | cut -d'.' -f1)")
                    if [ "$(echo "$aspect_ratio > 0.8 || $aspect_ratio < 0.4" | bc -l)" -eq 1 ]; then
                        echo "$(date '+%m-%d %H:%M') | 跳过宽高比不符合的壁纸（identify检测），删除：$file_name (分辨率: ${width}x${height}, 宽高比: $formatted_aspect_ratio)" >&2
                        rm -f "$file_path"
                        continue
                    fi
                fi
            fi
            # 调用标签提取函数
            extract_tags "$img_id" "$category" "$API_KEY"
            if [ "$MODE" == "bz" ]; then
                safe_img_url=$(printf '%s' "$img_url" | sed "s/'/''/g")
                if ! sqlite3 "$DB_FILE" "INSERT INTO downloaded (url, created_at) VALUES ('$safe_img_url', strftime('%s', 'now'));" 2>/dev/null; then
                    echo "$(date '+%m-%d %H:%M') | SQLite 插入失败，尝试重新创建表..." >&2
                    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS downloaded (url TEXT PRIMARY KEY, created_at INTEGER NOT NULL);" || {
                        echo "$(date '+%m-%d %H:%M') | 无法创建数据库表，跳过插入数据库" >&2
                        continue
                    }
                    if sqlite3 "$DB_FILE" "INSERT INTO downloaded (url, created_at) VALUES ('$safe_img_url', strftime('%s', 'now'));" 2>/dev/null; then
                        echo "$(date '+%m-%d %H:%M') | 重新创建表后插入成功" >&2
                    else
                        echo "$(date '+%m-%d %H:%M') | 重新创建表后插入仍失败，跳过" >&2
                        continue
                    fi
                fi
            fi
            echo "$(date '+%m-%d %H:%M') | 下载成功：$file_name (分辨率: ${width:-$api_dimension_x}x${height:-$api_dimension_y}, 宽高比: ${formatted_aspect_ratio:-$formatted_api_aspect_ratio}, 大小: $file_size_mb MB)" >&2
            echo "$(date) | $file_name | 类型: ${CATEGORY_MAP[$category]} | 分分辨率: ${width:-$api_dimension_x}x${height:-$api_dimension_y} | 大小: $file_size_mb MB" >> "$LOG_DIR/cron_log.txt"
            if [ "$MODE" == "bz" ]; then
                CACHED_WALLPAPER="$file_path"
            fi
            count=$((count + 1))
            downloaded=$((downloaded + 1))
            image_index=$((image_index + 1))
            if [ "$MODE" == "xz" ]; then
                echo "$(date '+%m-%d %H:%M') | 进度：已下载 $downloaded/$TARGET_COUNT 张" >&2
                current_count=$((current_count + 1))
            else
                if [ "$CATEGORY_MODE" == "lh" ]; then
                    if [ "$current_category" == "zr" ]; then
                        current_category="dm"
                    elif [ "$current_category" == "dm" ]; then
                        current_category="zr"
                    fi
                fi
            fi
            valid_image_found=1
            return 0
        done
        echo "$(date '+%m-%d %H:%M') | 页面 $PAGE 命中率：$((image_index - 1))/${#images[@]} 张 (跳过 $skipped_api 张，已下载 $skipped_downloaded 张，已尝试 ${#tried_pages[@]}/$last_page 页)" >&2
        page_attempts=$((page_attempts + 1))
    done
    if [ $valid_image_found -eq 1 ]; then
        echo "$(date '+%m-%d %H:%M') | 页面 $PAGE 命中率：$((image_index - 1))/${#images[@]} 张 (跳过 $skipped_api 张，已下载 $skipped_downloaded 张，已尝试 张)" >&2
        return 0
    fi
    if [ ${#tried_pages[@]} -ge "$last_page" ]; then
        if [ $skipped_downloaded -eq 0 ]; then
            echo "$(date '+%m-%d %H:%M') | 已尝试所有 ${#tried_pages[@]}/$last_page 页，无有效图片，跳过关键词[<$SEARCH_DISPLAY>]" >&2
        else
            echo "$(date '+%m-%d %H:%M') | 已尝试所有 ${#tried_pages[@]}/$last_page 页，存在已下载图片（$skipped_downloaded 张），不添加关键词[<$SEARCH_DISPLAY>]到Fallback" >&2
        fi
        return 1
    fi
    echo "$(date '+%m-%d %H:%M') | 页面 $PAGE 命中率：$((image_index - 1))/${#images[@]} 张 (跳过 $skipped_api 张，已下载 $skipped_downloaded 张，已尝试 张图片)" >&2
    return 1
}
download_image() {
        # 检查 anchor_file
    while ! check_anchor_file; do
        sleep 6
    done
    download_retry=4
    retry_delay=3
    local category=$1
    local purity=$2
    local force_query=$3
    local success=0
    local skipped_api=0
    local consecutive_failures=0
    local interval_minutes=${INTERVAL_MINUTES:-7}
    local max_consecutive_failures=$((interval_minutes * 3))
    local in_fallback_mode=0
    if [ $max_consecutive_failures -lt 5 ]; then
        max_consecutive_failures=5
        echo "$(date '+%m-%d %H:%M') | max_consecutive_failures 过低，调整为 5" >&2
    elif [ $max_consecutive_failures -gt 20 ]; then
        max_consecutive_failures=20
        echo "$(date '+%m-%d %H:%M') | max_consecutive_failures 过高，调整为 20" >&2
    fi
    set_cache_file "$purity" "$category"
    set_fallback_file "$purity" "$category"
    set_suppr_file "$purity" "$category"
    set_really_file "$purity" "$category"
    cleanup_cache
    cleanup_fallback
    while [ $success -eq 0 ]; do
        if [ "${force_bottom_pocket:-0}" -eq 1 ] || [ "$FALLBACK_MECHANISM" == "enabled" ] && [ $in_fallback_mode -eq 1 ]; then
            if download_fallback_image "$category" "$purity"; then
                success=1
                in_fallback_mode=0
                consecutive_failures=0
            else
                echo "$(date '+%m-%d %H:%M') | Bottom-pocket机制下载失败，退出本次下载" >&2
            fi
            continue
        fi
        if [ "$FALLBACK_MECHANISM" == "enabled" ] && [ $consecutive_failures -ge $max_consecutive_failures ] && [ $in_fallback_mode -eq 0 ]; then
            echo "$(date '+%m-%d %H:%M') | 连续 $consecutive_failures 次关键词选择失败，触发Bottom-pocket机制" >&2
            in_fallback_mode=1
            if download_fallback_image "$category" "$purity"; then
                success=1
                in_fallback_mode=0
                consecutive_failures=0
            else
                echo "$(date '+%m-%d %H:%M') | Bottom-pocket机制下载失败，退出本次下载" >&2
            fi
            continue
        fi
        if check_wallhaven; then
            local response_time=$(get_response_time "https://wallhaven.cc/")
            local sleep_duration
            if [[ "$response_time" =~ ^[0-9]+(\.[0-9]+)?$ && "$response_time" != "-1" ]]; then
                if (( $(echo "$response_time < 1000" | bc -l) )); then
                    sleep_duration=0.5
                elif (( $(echo "$response_time < 3000" | bc -l) )); then
                    sleep_duration=1
                else
                    sleep_duration=1.5
                fi
            else
                sleep_duration=1.5
            fi
            echo "$(date '+%m-%d %H:%M') | 主程序延迟正常：(${response_time}ms），开始下载壁纸" >&2
            sleep "$sleep_duration"
        else
            if [ "$FALLBACK_MECHANISM" == "enabled" ]; then
                echo "$(date '+%m-%d %H:%M') | 主程序链接失败，触发Bottom-pocket机制" >&2
                in_fallback_mode=1
                if download_fallback_image "$category" "$purity"; then
                    success=1
                    in_fallback_mode=0
                    consecutive_failures=0
                else
                    echo "$(date '+%m-%d %H:%M') | Bottom-pocket机制下载失败，退出本次下载" >&2
                fi
                continue
            else
                echo "$(date '+%m-%d %H:%M') | 主程序链接失败，Bottom-pocket未启用，休眠2s后重试" >&2
                sleep 2
            fi
        fi
        SORT_OPTIONS=("relevance" "relevance" "relevance" "relevance" "relevance" "relevance" "relevance" "favorites" "favorites" "favorites" "favorites" "views" "views" "views" "date_added" "date_added" "random")
        SORT_ORDER=${SORT_OPTIONS[$((RANDOM % ${#SORT_OPTIONS[@]}))]}
        # 修复：明确区分 zr 和 dm 的关键词选择
        if [ "$category" == "zr" ]; then
            select_keyword KEYWORDS_QUERIES WELFARE_QUERY
            SEARCH_QUERY="${WELFARE_QUERY}"
            SEARCH_DISPLAY="${QUERY_MAP[$WELFARE_QUERY]}"
            [ -z "$SEARCH_DISPLAY" ] && SEARCH_DISPLAY="$SEARCH_QUERY"
            manage_suppr_and_keywords "$SEARCH_QUERY" "$category" "$purity"
            if [ -n "${FALLBACK_CACHE[$SEARCH_QUERY]}" ]; then
                echo "$(date '+%m-%d %H:%M') | 关键词<$SEARCH_DISPLAY>触发Fallback，重新选择..." >&2
                consecutive_failures=$((consecutive_failures + 1))
                continue
            fi
            CATEGORY_FILTER="categories=001"
            echo "$(date '+%m-%d %H:%M') | 选择关键词:$SEARCH_DISPLAY <真人类别>" >&2
        else
            select_keyword KEYWORDS_QUERIES ANIME_QUERY_TERM
            SEARCH_QUERY="$ANIME_QUERY_TERM"
            SEARCH_DISPLAY="${QUERY_MAP[$ANIME_QUERY_TERM]}"
            [ -z "$SEARCH_DISPLAY" ] && SEARCH_DISPLAY="$SEARCH_QUERY"
            manage_suppr_and_keywords "$SEARCH_QUERY" "$category" "$purity"
            if [ -n "${FALLBACK_CACHE[$SEARCH_QUERY]}" ]; then
                echo "$(date '+%m-%d %H:%M') | 关键词<$SEARCH_DISPLAY>触发Fallback，重新选择..." >&2
                consecutive_failures=$((consecutive_failures + 1))
                continue
            fi
            CATEGORY_FILTER="categories=010"
            echo "$(date '+%m-%d %H:%M') | 选择关键词:$SEARCH_DISPLAY <动漫类别>" >&2
        fi
        skipped_downloaded=0
        export SEARCH_DISPLAY
        if download_page; then
            success=1
            add_to_really "$SEARCH_QUERY"
            consecutive_failures=0
        else
            echo "$(date '+%m-%d %H:%M') | 关键词<$SEARCH_DISPLAY>无有效图片，选择下一个关键词" >&2
            if [ $skipped_downloaded -eq 0 ]; then
                add_to_fallback "$SEARCH_QUERY"
                FALLBACK_CACHE["$SEARCH_QUERY"]=1
            else
                echo "$(date '+%m-%d %H:%M') | 关键词<$SEARCH_DISPLAY>因存在已下载图片（$skipped_downloaded 张）不添加到Fallback" >&2
            fi
            consecutive_failures=$((consecutive_failures + 1))
            sleep 1
        fi
    done
}

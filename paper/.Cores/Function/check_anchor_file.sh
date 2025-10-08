check_anchor_file() {
    # 初始化日志标志
    if [ -z "$NETWORK_ANOMALY_LOGGED" ]; then
        NETWORK_ANOMALY_LOGGED=0
    fi
    if [ -z "$ANCHOR_NOT_FOUND_LOGGED" ]; then
        ANCHOR_NOT_FOUND_LOGGED=0
    fi

    # 获取两个目标的响应时间
    local time1=$(get_response_time "https://wallhaven.cc/")
    local time2=$(get_response_time "https://v2.xxapi.cn/api/baisi?return=302")

    # 检查网络状态
    local valid_network=0
    if [[ "$time1" != "-1" && $(echo "$time1 >= 10 && $time1 <= 5000" | bc -l) -eq 1 ]]; then
        valid_network=1
    fi
    if [[ "$time2" != "-1" && $(echo "$time2 >= 10 && $time2 <= 3000" | bc -l) -eq 1 ]]; then
        valid_network=1
    fi

    if [ "$valid_network" -eq 0 ]; then
        if [ "$NETWORK_ANOMALY_LOGGED" -eq 0 ]; then
            echo "$(date '+%m-%d %H:%M') | 网络异常（wallhaven: ${time1}ms, xxapi: ${time2}ms），进入休眠" >&2
            NETWORK_ANOMALY_LOGGED=1
        fi
        return 1
    else
        if [ "$NETWORK_ANOMALY_LOGGED" -eq 1 ]; then
            echo "$(date '+%m-%d %H:%M') | 网络恢复（wallhaven: ${time1}ms, xxapi: ${time2}ms）" >&2
            NETWORK_ANOMALY_LOGGED=0
        fi
    fi

    # 检查锚点文件
    if [ -f "$ANCHOR_FILE" ]; then
        echo "$(date '+%m-%d %H:%M') | 锚点链接成功" &>/dev/null
        ANCHOR_NOT_FOUND_LOGGED=0
        return 0
    else
        if [ "$ANCHOR_NOT_FOUND_LOGGED" -eq 0 ]; then
            echo "$(date '+%m-%d %H:%M') | 锚点链接失败，进入休眠" >&2
            ANCHOR_NOT_FOUND_LOGGED=1
        fi
        return 1
    fi
}
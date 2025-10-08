check_wallhaven() {
    local response_time
    local connect_success=0
    local response
    local error_msg
    local attempt=1
    local max_attempts=2

    # 测试连通性和响应时间
    while [ $attempt -le $max_attempts ]; do
        response=$(curl -4 -s --max-time 5 --tlsv1.2 -I "https://wallhaven.cc" 2>/dev/null)
        response_time=$(curl -4 -s --max-time 5 --tlsv1.2 -w "%{time_total}\n" -o /dev/null "https://wallhaven.cc" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$response" ]; then
            connect_success=1
            response_time=$(echo "$response_time" | awk '{printf "%.0f", $1*1000}')  # 转换为毫秒
            break
        fi
        error_msg=$(cat /storage/emulated/0/Wallpaper/.Cores/Logs/curl_error.log)
        echo "$(date '+%m-%d %H:%M') | 连通性测试失败（尝试 $attempt/$max_attempts）" >&2
        sleep 2
        attempt=$((attempt + 1))
    done

    if [ $connect_success -ne 1 ]; then
        echo "$(date '+%m-%d %H:%M') | 连通性测试失败，放弃验证" >&2
        return 1
    fi

    # 检查响应时间
    if [[ ! "$response_time" =~ ^[0-9]+(\.[0-9]+)?$ || "$response_time" == "-1" ]]; then
        echo "$(date '+%m-%d %H:%M') | 响应时间无效：${response_time}" >&2
        return 1
    fi

    if (( $(echo "$response_time <= 10 || $response_time >= 5000" | bc -l) )); then
        echo "$(date '+%m-%d %H:%M') | 响应时间异常：${response_time}ms（超时无响应）" >&2
        return 1
    fi

    # 验证 API 密钥
    if test_api_key; then
        echo "$(date '+%m-%d %H:%M') | 主程序链接成功，开启关键词搜索" >&2
        return 0
    else
        echo "$(date '+%m-%d %H:%M') | API 密钥验证失败" >&2
        return 1
    fi
}
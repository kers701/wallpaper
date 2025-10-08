#!/bin/bash
#VERSION="1.0.2"
# 动态休眠
dynamic_sleep() {
    local target="https://v2.xxapi.cn/api/baisi?return=302"
    local response_time
    local sleep_duration

    response_time=$(get_response_time "$target")
    if [[ "$response_time" =~ ^[0-9]+(\.[0-9]+)?$ && "$response_time" != "-1" ]]; then
        if (( $(echo "$response_time < 1000" | bc -l) )); then
            sleep_duration=0.5
        elif (( $(echo "$response_time < 3000" | bc -l) )); then
            sleep_duration=1
        else
            sleep_duration=1.5
        fi
    else
        sleep_duration=1.5  # 无效或超时，休眠1.5秒
    fi

    echo "$(date '+%m-%d %H:%M') | 动态休眠：${sleep_duration}s（延迟：${response_time}ms）" &>/dev/null
    sleep "$sleep_duration"
}
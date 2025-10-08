#!/bin/bash
#VERSION="1.0.2"
#延迟提取
get_response_time() {
    local target="$1"
    # 使用 curl 获取总响应时间（毫秒），超时设为5秒
    local response_time=$(curl -o /dev/null -s -w "%{time_total}" "$target" --max-time 7 2>/dev/null)
    # 转换为毫秒（curl 返回秒，乘以1000）
    if [[ -n "$response_time" && "$response_time" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        response_time=$(echo "$response_time * 1000" | bc -l | awk '{printf "%.2f", $0}')
        echo "$response_time"
    else
        echo "-1"  # 无效响应返回 -1
    fi
}

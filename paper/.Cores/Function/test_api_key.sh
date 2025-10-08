test_api_key() {
    local max_api_retries=1
    local api_retry_delay=2
    local api_attempt
    local response
    local error
    local key_index
    local tried_keys=() # 记录已尝试的密钥索引

    if [ ${#API_KEYS[@]} -eq 0 ]; then
        echo "$(date '+%m-%d %H:%M') | 无可用 API 密钥" >&2
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "$(date '+%m-%d %H:%M') | jq 未安装，无法解析 API 响应" >&2
        return 1
    fi

    while [ ${#tried_keys[@]} -lt ${#API_KEYS[@]} ]; do
        # 从剩余未尝试的密钥中随机选择
        local remaining_keys=()
        for i in "${!API_KEYS[@]}"; do
            if [[ ! " ${tried_keys[*]} " =~ " $i " ]]; then
                remaining_keys+=("$i")
            fi
        done

        # 如果没有剩余密钥，退出循环
        if [ ${#remaining_keys[@]} -eq 0 ]; then
            break
        fi

        # 随机选择一个密钥索引
        key_index=${remaining_keys[$((RANDOM % ${#remaining_keys[@]}))]}
        tried_keys+=("$key_index")

        API_KEY="${API_KEYS[$key_index]}"
        key_display=$(echo "$API_KEY" | sed 's/\(.\{2\}\).*\(.\{2\}\)/\1****\2/')
        api_attempt=1

        while [ $api_attempt -le $max_api_retries ]; do
            response=$(curl -4 -s --max-time 7 --tlsv1.2 "https://wallhaven.cc/api/v1/search?page=1&apikey=${API_KEY}" 2>/dev/null)
            if [ $? -ne 0 ]; then
                error_msg=$(cat /tmp/curl_error.log 2>/dev/null || echo "未知错误")
                echo "$(date '+%m-%d %H:%M') | API 密钥 $key_display 请求失败（尝试 $api_attempt/$max_api_retries）：$error_msg" >&2
            else
                error=$(echo "$response" | jq -r '.error // null' 2>/dev/null)
                if [ -n "$response" ] && [ "$error" == "null" ]; then
                    echo "$(date '+%m-%d %H:%M') | API 密钥 $key_display 验证成功" >&2
                    return 0
                fi
                echo "$(date '+%m-%d %H:%M') | API 密钥 $key_display 验证失败（尝试 $api_attempt/$max_api_retries）" >&2
            fi
            sleep $api_retry_delay
            api_attempt=$((api_attempt + 1))
        done
    done

    echo "$(date '+%m-%d %H:%M') | 所有 API 密钥均验证失败" >&2
    return 1
}
dynamic_adjust_parameters() {
    local config_file="$1"
    local interval_hours=$(echo "scale=2; $INTERVAL_MINUTES / 5" | bc) # INTERVAL_MINUTES ÷ 5，单位为小时
    local current_time=$(date +%s)
    local last_adjust_file="$CONFIG_DIR/Adjust"
    local last_adjust_time=0
    local sleep_seconds=$(echo "$interval_hours * 3600" | bc) # 转换为秒

    # 检查配置文件是否可写
    if [ ! -w "$config_file" ]; then
        echo "$(date '+%m-%d %H:%M') | 配置文件 $config_file 不可写" >&2
        return 1
    fi

    # 读取原配置文件中的参数（如果存在）
    local MODE INTERVAL_MINUTES FALLBACK_MECHANISM RESOLUTION_MODE SCREEN_OFF_SLEEP DYNAMIC_ADJUST MIN_WIDTH MIN_HEIGHT
    if [ -f "$config_file" ]; then
        source "$config_file" 2>/dev/null || {
            echo "$(date '+%m-%d %H:%M') | 读取配置文件 $config_file 失败" >&2
            return 1
        }
    else
        echo "$(date '+%m-%d %H:%M') | 配置文件 $config_file 不存在" >&2
        return 1
    fi

    # 读取上次调整时间（如果存在）
    if [ -f "$last_adjust_file" ]; then
        last_adjust_time=$(cat "$last_adjust_file")
    fi

    # 检查是否需要进行动态调参
    if [ $(echo "$current_time - $last_adjust_time >= $sleep_seconds" | bc -l) -eq 1 ] || [ ! -f "$last_adjust_file" ]; then
        PURITY_VALUES=("110" "111" "010" "001" "011" "101")
        #PURITY_VALUES=("100" "110" "010")
        CATEGORY_MODE_VALUES=("zr" "dm" "lh")

        # 随机选择新值
        NEW_PURITY=${PURITY_VALUES[$((RANDOM % ${#PURITY_VALUES[@]}))]}
        NEW_CATEGORY_MODE=${CATEGORY_MODE_VALUES[$((RANDOM % ${#CATEGORY_MODE_VALUES[@]}))]}

        # 转换为描述性文本
        case "$NEW_PURITY" in
            "100") PURITY_DESC="R8" ;;
            "110") PURITY_DESC="R13" ;;
            "111") PURITY_DESC="R18" ;;
            "010") PURITY_DESC="Only13" ;;
            "001") PURITY_DESC="Only18" ;;
            "011") PURITY_DESC="R18D" ;;
            "101") PURITY_DESC="Heartbeat" ;;
            *) PURITY_DESC="未知" ;;
        esac

        case "$NEW_CATEGORY_MODE" in
            "zr") CATEGORY_DESC="真人类别" ;;
            "dm") CATEGORY_DESC="动漫类别" ;;
            "lh") CATEGORY_DESC="类别轮换" ;;
            *) CATEGORY_DESC="未知" ;;
        esac

        # 更新全局变量
        PURITY="$NEW_PURITY"
        CATEGORY_MODE="$NEW_CATEGORY_MODE"
        PURITY_DESC="$PURITY_DESC"
        CATEGORY_DESC="$CATEGORY_DESC"
        SEARCH_DESC="$SEARCH_DESC"

        # 备份配置文件
        cp "$config_file" "${config_file}.bak" 2>/dev/null || {
            echo "$(date '+%m-%d %H:%M') | 备份配置文件失败" >&2
        }

        # 重写配置文件，使用原配置文件的值（非随机参数）
        if ! cat > "$config_file" << EOF
MODE=${MODE:-}
INTERVAL_MINUTES=${INTERVAL_MINUTES:-}
PURITY=$NEW_PURITY
CATEGORY_MODE=$NEW_CATEGORY_MODE
FALLBACK_MECHANISM=${FALLBACK_MECHANISM:-}
RESOLUTION_MODE=${RESOLUTION_MODE:-}
SCREEN_OFF_SLEEP=${SCREEN_OFF_SLEEP:-}
DYNAMIC_ADJUST=${DYNAMIC_ADJUST:-}
#MIN_WIDTH=${MIN_WIDTH:-}
#MIN_HEIGHT=${MIN_HEIGHT:-}
EOF
        then
            echo "$(date '+%m-%d %H:%M') | 写入配置文件 $config_file 失败" >&2
            return 1
        fi

        # 记录本次调整时间
        echo "$current_time" > "$last_adjust_file"

        # 输出描述性日志
        echo "$(date '+%m-%d %H:%M') | 动态调参（$PURITY_DESC，$CATEGORY_DESC）" >&2
    fi
}
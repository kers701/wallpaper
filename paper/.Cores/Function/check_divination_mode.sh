check_divination_mode() {
    local mode="$1"
    local interval_minutes="$2"
    local purity="$3"
    local category_mode="$4"
    local fallback_mechanism="$5"
    local resolution_mode="$6"
    local min_width="$7"
    local min_height="$8"
    local screen_off_sleep="$9"
    local dynamic_adjust="${10}"
    DIVINATION_FILE="$CONFIG_DIR/Diagram"
    THOUSAND_FILE="$CONFIG_DIR/Thousand"
    OLD_THOUSAND_FILE="$CONFIG_DIR/Oldthousand"

    # 保存原始参数（仅在第一次进入时保存）
    if [ -z "$ORIGINAL_MODE" ]; then
        ORIGINAL_MODE="$mode"
        ORIGINAL_INTERVAL_MINUTES="$interval_minutes"
        ORIGINAL_PURITY="$purity"
        ORIGINAL_CATEGORY_MODE="$category_mode"
        ORIGINAL_FALLBACK_MECHANISM="$fallback_mechanism"
        ORIGINAL_RESOLUTION_MODE="$resolution_mode"
        ORIGINAL_MIN_WIDTH="$min_width"
        ORIGINAL_MIN_HEIGHT="$min_height"
        ORIGINAL_SCREEN_OFF_SLEEP="$screen_off_sleep"
        ORIGINAL_DYNAMIC_ADJUST="$dynamic_adjust"
    fi

    # 初始化当前参数
    CURRENT_MODE="${CURRENT_MODE:-$ORIGINAL_MODE}"
    CURRENT_INTERVAL_MINUTES="${CURRENT_INTERVAL_MINUTES:-$ORIGINAL_INTERVAL_MINUTES}"
    CURRENT_PURITY="${CURRENT_PURITY:-$ORIGINAL_PURITY}"
    CURRENT_CATEGORY_MODE="${CURRENT_CATEGORY_MODE:-$ORIGINAL_CATEGORY_MODE}"
    CURRENT_FALLBACK_MECHANISM="${CURRENT_FALLBACK_MECHANISM:-$ORIGINAL_FALLBACK_MECHANISM}"
    CURRENT_RESOLUTION_MODE="${CURRENT_RESOLUTION_MODE:-$ORIGINAL_RESOLUTION_MODE}"
    CURRENT_MIN_WIDTH="${CURRENT_MIN_WIDTH:-$ORIGINAL_MIN_WIDTH}"
    CURRENT_MIN_HEIGHT="${CURRENT_MIN_HEIGHT:-$ORIGINAL_MIN_HEIGHT}"
    CURRENT_SCREEN_OFF_SLEEP="${CURRENT_SCREEN_OFF_SLEEP:-$ORIGINAL_SCREEN_OFF_SLEEP}"
    CURRENT_DYNAMIC_ADJUST="${CURRENT_DYNAMIC_ADJUST:-$ORIGINAL_DYNAMIC_ADJUST}"

    # 参数值到中文描述的映射函数
    get_mode_desc() {
        case "$1" in
            xz) echo "自动下载模式" ;;
            bz) echo "更换壁纸模式" ;;
            *) echo "$1" ;;
        esac
    }

    get_purity_desc() {
        case "$1" in
            100) echo "R8" ;;
            110) echo "R13" ;;
            111) echo "R18" ;;
            010) echo "Only13" ;;
            001) echo "Only18" ;;
            011) echo "R18D" ;;
            101) echo "Heartbeat" ;;
            *) echo "$1" ;;
        esac
    }

    get_category_mode_desc() {
        case "$1" in
            zr) echo "真人类别" ;;
            dm) echo "动漫类别" ;;
            lh) echo "类别轮换" ;;
            *) echo "$1" ;;
        esac
    }
    get_enabled_desc() {
        case "$1" in
            enabled) echo "启用" ;;
            disabled) echo "禁用" ;;
            *) echo "$1" ;;
        esac
    }

    get_resolution_mode_desc() {
        case "$1" in
            zsy) echo "自适应" ;;
            zdy) echo "自定义" ;;
            1.5k) echo "1.5K" ;;
            *) echo "$1" ;;
        esac
    }

    # 检查万化归一模式
    if [ -f "$DIVINATION_FILE" ]; then
        local reload_config=0
        if [ "${IS_DIVINATION_MODE:-0}" -eq 0 ]; then
            IS_DIVINATION_MODE=1
            echo "$(date '+%m-%d %H:%M') | 千变万化神莫测" >&2
            if [ -f "$THOUSAND_FILE" ]; then
                cp "$THOUSAND_FILE" "$OLD_THOUSAND_FILE" 2>/dev/null
            else
                echo "$(date '+%m-%d %H:%M') | 万化归一配置文件不存在：$THOUSAND_FILE，跳过复制" >&2
            fi
            reload_config=1
        else
            if [ -f "$THOUSAND_FILE" ] && [ -f "$OLD_THOUSAND_FILE" ]; then
                cmp -s "$THOUSAND_FILE" "$OLD_THOUSAND_FILE"
                if [ $? -ne 0 ]; then
                    echo "$(date '+%m-%d %H:%M') | 仙无言神不语" >&2
                    reload_config=1
                fi
            elif [ -f "$THOUSAND_FILE" ] && [ ! -f "$OLD_THOUSAND_FILE" ]; then
                reload_config=1
            fi
        fi

        if [ $reload_config -eq 1 ]; then
            if [ -f "$THOUSAND_FILE" ]; then
                local valid_params=0
                while IFS='=' read -r key value; do
                    # 跳过空行或以 # 开头的行（注释）
                    if [[ -z "$key" ]] || [[ "$key" =~ ^[[:space:]]*# ]]; then
                        continue
                    fi
                    key=$(echo "$key" | tr -d '[:space:]')
                    value=$(echo "$value" | tr -d '[:space:]')
                    valid_params=$((valid_params + 1))
                    case "$key" in
                        MODE)
                            if [[ "$value" == "xz" || "$value" == "bz" ]]; then
                                CURRENT_MODE="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：运行模式=$(get_mode_desc "$value")" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：运行模式=$value，保持运行模式=$(get_mode_desc "$CURRENT_MODE")" >&2
                            fi
                            ;;
                        INTERVAL_MINUTES)
                            if [[ "$value" =~ ^[0-9]+$ ]]; then
                                CURRENT_INTERVAL_MINUTES="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：更换壁纸间隔=$value" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：更换壁纸间隔=$value，保持更换壁纸间隔=$CURRENT_INTERVAL_MINUTES" >&2
                            fi
                            ;;
                        PURITY)
                            if [[ "$value" =~ ^[0-1]{3}$ ]]; then
                                CURRENT_PURITY="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：壁纸纯度=$(get_purity_desc "$value")" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：壁纸纯度=$value，保持壁纸纯度=$(get_purity_desc "$CURRENT_PURITY")" >&2
                            fi
                            ;;
                        CATEGORY_MODE)
                            if [[ "$value" == "zr" || "$value" == "dm" || "$value" == "lh" ]]; then
                                CURRENT_CATEGORY_MODE="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：搜索类别=$(get_category_mode_desc "$value")" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：搜索类别=$value，保持搜索类别=$(get_category_mode_desc "$CURRENT_CATEGORY_MODE")" >&2
                            fi
                            ;;
                        FALLBACK_MECHANISM)
                            if [[ "$value" == "enabled" || "$value" == "disabled" ]]; then
                                CURRENT_FALLBACK_MECHANISM="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：Bottom-pocket机制=$(get_enabled_desc "$value")" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：Bottom-pocket机制=$value，保持Bottom-pocket机制=$(get_enabled_desc "$CURRENT_FALLBACK_MECHANISM")" >&2
                            fi
                            ;;
                        RESOLUTION_MODE)
                            if [[ "$value" == "zsy" || "$value" == "1.5k" || "$value" == "zdy" ]]; then
                                CURRENT_RESOLUTION_MODE="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：分辨率模式=$(get_resolution_mode_desc "$value")" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：分辨率模式=$value，保持分辨率模式=$(get_resolution_mode_desc "$CURRENT_RESOLUTION_MODE")" >&2
                            fi
                            ;;
                        MIN_WIDTH)
                            if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ]; then
                                CURRENT_MIN_WIDTH="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：最低宽度=$value" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：最低宽度=$value，保持最低宽度=$CURRENT_MIN_WIDTH" >&2
                            fi
                            ;;
                        MIN_HEIGHT)
                            if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ]; then
                                CURRENT_MIN_HEIGHT="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：最低高度=$value" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：最低高度=$value，保持最低高度=$CURRENT_MIN_HEIGHT" >&2
                            fi
                            ;;
                        SCREEN_OFF_SLEEP)
                            if [[ "$value" == "enabled" || "$value" == "disabled" ]]; then
                                CURRENT_SCREEN_OFF_SLEEP="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：息屏Doze=$(get_enabled_desc "$value")" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：息屏Doze=$value，保持息屏Doze=$(get_enabled_desc "$CURRENT_SCREEN_OFF_SLEEP")" >&2
                            fi
                            ;;
                        DYNAMIC_ADJUST)
                            if [[ "$value" == "enabled" || "$value" == "disabled" ]]; then
                                CURRENT_DYNAMIC_ADJUST="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：动态调参=$(get_enabled_desc "$value")" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：动态调参=$value，保持动态调参=$(get_enabled_desc "$CURRENT_DYNAMIC_ADJUST")" >&2
                            fi
                            ;;
                        *)
                            echo "$(date '+%m-%d %H:%M') | 未知参数：$key=$value，忽略" >&2
                            ;;
                    esac
                done < "$THOUSAND_FILE"
                cp "$THOUSAND_FILE" "$OLD_THOUSAND_FILE" 2>/dev/null
                if [ $valid_params -eq 0 ]; then
                    echo "$(date '+%m-%d %H:%M') | 万化归一配置文件无有效参数，使用当前参数" >&2
                fi
            else
                echo "$(date '+%m-%d %H:%M') | 万化归一配置文件不存在：$THOUSAND_FILE，使用当前参数" >&2
            fi
            DIVINATION_LOGGED=1
        fi
        return 1
    else
        if [ "${IS_DIVINATION_MODE:-0}" -eq 1 ]; then
            IS_DIVINATION_MODE=0
            DIVINATION_LOGGED=0
            CURRENT_MODE="$ORIGINAL_MODE"
            CURRENT_INTERVAL_MINUTES="$ORIGINAL_INTERVAL_MINUTES"
            CURRENT_PURITY="$ORIGINAL_PURITY"
            CURRENT_CATEGORY_MODE="$ORIGINAL_CATEGORY_MODE"
            CURRENT_FALLBACK_MECHANISM="$ORIGINAL_FALLBACK_MECHANISM"
            CURRENT_RESOLUTION_MODE="$ORIGINAL_RESOLUTION_MODE"
            CURRENT_MIN_WIDTH="$ORIGINAL_MIN_WIDTH"
            CURRENT_MIN_HEIGHT="$ORIGINAL_MIN_HEIGHT"
            CURRENT_SCREEN_OFF_SLEEP="$ORIGINAL_SCREEN_OFF_SLEEP"
            CURRENT_DYNAMIC_ADJUST="$ORIGINAL_DYNAMIC_ADJUST"
            echo "$(date '+%m-%d %H:%M') | 万灵归一鸿蒙启" >&2
            echo "$(date '+%m-%d %H:%M') | 参数恢复：运行模式=$(get_mode_desc "$CURRENT_MODE"), 壁纸更换间隔=$CURRENT_INTERVAL_MINUTES, 壁纸纯度=$(get_purity_desc "$CURRENT_PURITY"), 搜索类别=$(get_category_mode_desc "$CURRENT_CATEGORY_MODE"),Bottom-pocket机制=$(get_enabled_desc "$CURRENT_FALLBACK_MECHANISM"), 分辨率模式=$(get_resolution_mode_desc "$CURRENT_RESOLUTION_MODE"), 最低分辨率=${CURRENT_MIN_WIDTH}x${CURRENT_MIN_HEIGHT}, 息屏Doze=$(get_enabled_desc "$CURRENT_SCREEN_OFF_SLEEP"), 动态调参=$(get_enabled_desc "$CURRENT_DYNAMIC_ADJUST")" >&2
        fi
        return 0
    fi
}
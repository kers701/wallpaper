check_screen_sleep() {
    local screen_off_sleep="$1"

    # 获取电池电量
    local battery_data
    battery_data=$(termux-battery-status 2>/dev/null)
    if [ -z "$battery_data" ]; then
        echo "$(date '+%m-%d %H:%M') | 无法获取电池数据，跳过检测" >&2
        return 1
    fi

    local percentage
    percentage=$(echo "$battery_data" | jq -r '.percentage // 0')
    if [ "$percentage" = "0" ]; then
        echo "$(date '+%m-%d %H:%M') | 电池数据无效，跳过检测" >&2
        return 1
    fi

    # 检查电量是否大于50%
    if [ "$percentage" -gt 50 ]; then
        echo "$(date '+%m-%d %H:%M') | 电量充足(${percentage}%),跳过息屏Doze" >/dev/null
        return 0
    fi

    # 检查是否启用息屏Doze
    if [ "$screen_off_sleep" != "enabled" ]; then
        echo "$(date '+%m-%d %H:%M') | 息屏Doze未启用，跳过检测" >/dev/null
        return 0
    fi

    # 检查充电状态
    local charging_status
    charging_status=$(su -c "cat /sys/class/power_supply/battery/status" 2>/dev/null)
    case "$charging_status" in
        Charging|Full)
            return 0
            ;;
        Discharging|Not\ charging|"")
            # 继续检测屏幕状态
            ;;
        *)
            echo "$(date '+%m-%d %H:%M') | 未知充电状态: $charging_status，假设非充电" >&2
            ;;
    esac

    local screen_check_script="/storage/emulated/0/Wallpaper/.Bin/doze.py"
    if [ ! -f "$screen_check_script" ]; then
        echo "$(date '+%m-%d %H:%M') | 屏幕检测脚本 $screen_check_script 不存在" >&2
        return 1
    fi

    local is_doze_mode=0  # 0: 未进入Doze模式, 1: 已进入Doze模式
    local doze_start_time=0  # 记录Doze开始时间（秒）
    while true; do
        local screen_status
        screen_status=$(python3 "$screen_check_script" 2>/dev/null)
        if [ $? -ne 0 ]; then
            echo "$(date '+%m-%d %H:%M') | 执行屏幕检测脚本失败，请检查 $screen_check_script" >&2
            return 1
        fi

        if [ "$screen_status" == "屏幕已熄灭" ]; then
            if [ $is_doze_mode -eq 0 ]; then
                echo "$(date '+%m-%d %H:%M') | 屏幕熄灭,进入Doze模式" >&2
                is_doze_mode=1
                doze_start_time=$(date +%s)  # 记录开始时间
            fi
            sleep 120
            continue
        elif [ "$screen_status" == "屏幕实际开启" ]; then
            if [ $is_doze_mode -eq 1 ]; then
                local doze_end_time=$(date +%s)  # 记录结束时间
                local doze_duration=$((doze_end_time - doze_start_time))  # 计算时长（秒）
                local minutes=$((doze_duration / 60))  # 分钟
                local seconds=$((doze_duration % 60))  # 秒
                echo "$(date '+%m-%d %H:%M') | 屏幕亮起,退出Doze模式，Doze:${minutes}分${seconds}秒" >&2
                is_doze_mode=0
            fi
            break
        else
            if [ $is_doze_mode -eq 1 ]; then
                local doze_end_time=$(date +%s)
                local doze_duration=$((doze_end_time - doze_start_time))
                local minutes=$((doze_duration / 60))
                local seconds=$((doze_duration % 60))
                echo "$(date '+%m-%d %H:%M') | 屏幕亮起,退出Doze模式，Doze时长${minutes}分${seconds}秒" >&2
                is_doze_mode=0
            fi
            echo "$(date '+%m-%d %H:%M') | 无效屏幕状态: $screen_status" >&2
            break
        fi
    done
    return 0
}
#!/bin/bash

# ================= 检查 Notice 文件 ====================
NOTICE_FILE="/storage/emulated/0/Wallpaper/.Cores/Configs/Notice"
NOTIFICATION_ID="main_program_status"
if [ ! -f "$NOTICE_FILE" ]; then
    termux-notification-remove "$NOTIFICATION_ID"
    exit 0
fi

# ================= 初始设置区域 ====================
RUN_TIME_FILE="/storage/emulated/0/Wallpaper/.Cores/Logs/.run_time"
SESSION_TIME_FILE="/storage/emulated/0/Wallpaper/.Cores/Logs/.session_time"
CHARGING_TIME_FILE="/storage/emulated/0/Wallpaper/.Cores/Logs/.charging_time"
BATTERY_INFO_FILE="/storage/emulated/0/Wallpaper/.Cores/Logs/.battery_info"
CHARGING_STATUS_FILE="/storage/emulated/0/Wallpaper/.Cores/Logs/.charging_status"
START_TIME=0
SESSION_START_TIME=0
CHARGING_START_TIME=0
RUNNING=false
SESSION_RUNNING=false
CHARGING=false
INITIAL_CAPACITY=""
SESSION_INITIAL_CAPACITY=""
CHARGING_INITIAL_CAPACITY=""

# ================= 工具函数：补零 ====================
pad_decimal() {
    printf "%.2f" "$1"
}

# ================= 计算 CPU 总负载 ====================
get_cpu_load() {
    stat1=$(su -c "cat /proc/stat" | head -n 1)
    sleep 1
    stat2=$(su -c "cat /proc/stat" | head -n 1)
    read user1 nice1 sys1 idle1 < <(echo $stat1 | awk '{print $2,$3,$4,$5}')
    read user2 nice2 sys2 idle2 < <(echo $stat2 | awk '{print $2,$3,$4,$5}')
    total1=$((user1 + nice1 + sys1 + idle1))
    total2=$((user2 + nice2 + sys2 + idle2))
    used=$((total2 - total1 - (idle2 - idle1)))
    total=$((total2 - total1))
    if [ $total -gt 0 ]; then
        usage=$(echo "scale=2; $used * 100 / $total" | bc)
        if [ "$(echo "$usage <= 0" | bc)" -eq 1 ]; then
            echo "处理器总负载: $usage% | 静默状态"
        elif [ "$(echo "$usage <= 50" | bc)" -eq 1 ]; then
            echo "处理器总负载: $usage% | 轻度负载"
        elif [ "$(echo "$usage <= 85" | bc)" -eq 1 ]; then
            echo "处理器总负载: $usage% | 中度负载"
        elif [ "$(echo "$usage <= 100" | bc)" -eq 1 ]; then
            echo "处理器总负载: $usage% | 重度负载"
        else
            echo "处理器总负载: $usage% | 超频超载"
        fi
    else
        echo "处理器总负载: 获取异常"
    fi
}

# ========== 主程序运行时间与电池数据记录 ============
start_timer() {
    START_TIME=$(date +%s)
    RUNNING=true
    echo $START_TIME > "$RUN_TIME_FILE"
    INITIAL_CAPACITY=$(su -c "cat /sys/class/power_supply/battery/capacity" 2>/dev/null || echo "未知")
    echo "$INITIAL_CAPACITY" > "$BATTERY_INFO_FILE"
    # 主程序启动时重置会话时间和充电时间
    rm -f "$SESSION_TIME_FILE" "$CHARGING_TIME_FILE"
    start_session_timer
}

start_session_timer() {
    SESSION_START_TIME=$(date +%s)
    SESSION_RUNNING=true
    SESSION_INITIAL_CAPACITY=$(su -c "cat /sys/class/power_supply/battery/capacity" 2>/dev/null || echo "未知")
    {
        echo "$SESSION_START_TIME"
        echo "$SESSION_INITIAL_CAPACITY"
    } > "$SESSION_TIME_FILE"
}

start_charging_timer() {
    CHARGING_START_TIME=$(date +%s)
    CHARGING=true
    CHARGING_INITIAL_CAPACITY=$(su -c "cat /sys/class/power_supply/battery/capacity" 2>/dev/null || echo "未知")
    {
        echo "$CHARGING_START_TIME"
        echo "$CHARGING_INITIAL_CAPACITY"
    } > "$CHARGING_TIME_FILE"
}

stop_timer() {
    RUNNING=false
    rm -f "$RUN_TIME_FILE" "$BATTERY_INFO_FILE"
}

stop_session_timer() {
    SESSION_RUNNING=false
    rm -f "$SESSION_TIME_FILE"
}

stop_charging_timer() {
    CHARGING=false
    rm -f "$CHARGING_TIME_FILE"
}

get_run_time() {
    if [ "$RUNNING" = true ] && [ -f "$RUN_TIME_FILE" ]; then
        START_TIME=$(cat "$RUN_TIME_FILE")
        CURRENT_TIME=$(date +%s)
        DIFF=$((CURRENT_TIME - START_TIME))
        DAYS=$((DIFF / 86400))
        HOURS=$(( (DIFF % 86400) / 3600 ))
        MINUTES=$(( (DIFF % 3600) / 60 ))
        SECONDS=$((DIFF % 60))
        echo "${DAYS}天${HOURS}时${MINUTES}分${SECONDS}秒"
    else
        echo "0天0时0分0秒"
    fi
}

get_session_run_time() {
    if [ "$SESSION_RUNNING" = true ] && [ -f "$SESSION_TIME_FILE" ]; then
        SESSION_START_TIME=$(sed -n '1p' "$SESSION_TIME_FILE")
        CURRENT_TIME=$(date +%s)
        DIFF=$((CURRENT_TIME - SESSION_START_TIME))
        DAYS=$((DIFF / 86400))
        HOURS=$(( (DIFF % 86400) / 3600 ))
        MINUTES=$(( (DIFF % 3600) / 60 ))
        echo "${DAYS}天${HOURS}时${MINUTES}分"
    else
        echo "0天0时0分"
    fi
}

get_charging_time() {
    if [ "$CHARGING" = true ] && [ -f "$CHARGING_TIME_FILE" ]; then
        CHARGING_START_TIME=$(sed -n '1p' "$CHARGING_TIME_FILE")
        CURRENT_TIME=$(date +%s)
        DIFF=$((CURRENT_TIME - CHARGING_START_TIME))
        DAYS=$((DIFF / 86400))
        HOURS=$(( (DIFF % 86400) / 3600 ))
        MINUTES=$(( (DIFF % 3600) / 60 ))
        echo "${DAYS}天${HOURS}时${MINUTES}分"
    else
        echo "0天0时0分"
    fi
}

# ================== 用于 cron 的通知函数 ===================
notify_status() {
    local PID=$(cat /storage/emulated/0/Wallpaper/.Cores/Configs/Wallpaper 2>/dev/null || echo "未知")

    # 检查主进程是否存活
    if [ "$PID" = "未知" ] || ! ps -p "$PID" > /dev/null 2>&1; then
        termux-notification-remove "$NOTIFICATION_ID"
        return
    fi

    # 检查日志是否包含“进入休眠”并提取 | 后面的内容
    local SLEEP_LOG=$(tail -n 1 /storage/emulated/0/Wallpaper/run_log | grep -E "进入休眠" | cut -d '|' -f 2- | sed 's/^[[:space:]]*//g' || echo "")
    local NOTIFICATION_TITLE="😋壁纸核心驱动运行中"
    local NOTIFICATION_CONTENT=""
    if [ -n "$SLEEP_LOG" ]; then
        NOTIFICATION_TITLE="😪壁纸核心驱动正在休眠"
        NOTIFICATION_CONTENT="$SLEEP_LOG"
    else
        local WALLPAPER_LOG=$(tail -n 1000 /storage/emulated/0/Wallpaper/run_log | grep -E "壁纸1设置成功|壁纸2设置成功|已设置为壁纸" | tail -n 2)
        local DESKTOP_WALLPAPER=$(echo "$WALLPAPER_LOG" | grep "设置成功（桌面）" | tail -n 1 | grep -oE "\[.*?\]" || echo "正在初始化...")
        local LOCKSCREEN_WALLPAPER=$(echo "$WALLPAPER_LOG" | grep "设置成功（锁屏）" | tail -n 1 | grep -oE "\[.*?\]" || echo "正在初始化...")

        if [ -z "$DESKTOP_WALLPAPER" ] && [ -z "$LOCKSCREEN_WALLPAPER" ]; then
            local LATEST_WALLPAPER=$(echo "$WALLPAPER_LOG" | grep "已设置为壁纸" | tail -n 1 | grep -oE "\[.*?\]" || echo "未知")
            DESKTOP_WALLPAPER="$LATEST_WALLPAPER"
            LOCKSCREEN_WALLPAPER="$LATEST_WALLPAPER"
        fi

        local CURRENT_CAPACITY=$(su -c "cat /sys/class/power_supply/battery/capacity" 2>/dev/null || echo "未知")
        local BATTERY_STATUS_RAW=$(su -c "cat /sys/class/power_supply/battery/status" 2>/dev/null || echo "未知")
        local IS_CHARGING=""
        if [ "$BATTERY_STATUS_RAW" = "Charging" ] || [ "$BATTERY_STATUS_RAW" = "Full" ]; then
            IS_CHARGING="true"
        else
            IS_CHARGING=""
        fi
        local LAST_CHARGING_STATUS=$(cat "$CHARGING_STATUS_FILE" 2>/dev/null || echo "Unknown")
        local BATTERY_STATUS="未知"

        # 检查 SESSION_START_TIME 是否早于 START_TIME
        if [ "$SESSION_RUNNING" = true ] && [ -f "$SESSION_TIME_FILE" ] && [ "$RUNNING" = true ] && [ -f "$RUN_TIME_FILE" ]; then
            SESSION_START_TIME=$(sed -n '1p' "$SESSION_TIME_FILE")
            START_TIME=$(cat "$RUN_TIME_FILE")
            if [ "$SESSION_START_TIME" -lt "$START_TIME" ]; then
                rm -f "$SESSION_TIME_FILE"
                start_session_timer
            fi
        fi

        # 检查 CHARGING_START_TIME 是否早于 START_TIME
        if [ "$CHARGING" = true ] && [ -f "$CHARGING_TIME_FILE" ] && [ "$RUNNING" = true ] && [ -f "$RUN_TIME_FILE" ]; then
            CHARGING_START_TIME=$(sed -n '1p' "$CHARGING_TIME_FILE")
            START_TIME=$(cat "$RUN_TIME_FILE")
            if [ "$CHARGING_START_TIME" -lt "$START_TIME" ]; then
                rm -f "$CHARGING_TIME_FILE"
                start_charging_timer
            fi
        fi

        if [ -n "$IS_CHARGING" ]; then
            # 手机正在充电
            if [ "$LAST_CHARGING_STATUS" != "Charging" ]; then
                rm -f "$SESSION_TIME_FILE" "$CHARGING_TIME_FILE"
                start_session_timer
                start_charging_timer
                echo "Charging" > "$CHARGING_STATUS_FILE"
            fi
            if [ -f "$CHARGING_TIME_FILE" ]; then
                CHARGING_INITIAL_CAPACITY=$(sed -n '2p' "$CHARGING_TIME_FILE" || echo "未知")
            fi
            if [ "$CURRENT_CAPACITY" != "未知" ] && [ "$CHARGING_INITIAL_CAPACITY" != "未知" ]; then
                local CHARGED_AMOUNT=$((CURRENT_CAPACITY - CHARGING_INITIAL_CAPACITY))
                if [ "$BATTERY_STATUS_RAW" = "Full" ]; then
                    stop_charging_timer  # 停止充电计时
                    BATTERY_STATUS="手机已充满电"
                elif [ $CHARGED_AMOUNT -ge 0 ]; then
                    BATTERY_STATUS="$(get_charging_time) | 正在充电: ${CHARGED_AMOUNT}%"
                else
                    BATTERY_STATUS="$(get_charging_time) | 正在充电: 0%"
                fi
            else
                BATTERY_STATUS="$(get_charging_time) | 正在充电: 未知"
            fi
        else
            # 手机未充电
            if [ "$LAST_CHARGING_STATUS" != "NotCharging" ]; then
                rm -f "$SESSION_TIME_FILE" "$CHARGING_TIME_FILE"
                start_session_timer
                echo "NotCharging" > "$CHARGING_STATUS_FILE"
            fi
            if [ -f "$SESSION_TIME_FILE" ]; then
                SESSION_INITIAL_CAPACITY=$(sed -n '2p' "$SESSION_TIME_FILE" || echo "未知")
            fi
            if [ "$CURRENT_CAPACITY" != "未知" ] && [ "$SESSION_INITIAL_CAPACITY" != "未知" ]; then
                local CONSUMED_POWER=$((SESSION_INITIAL_CAPACITY - CURRENT_CAPACITY))
                if [ $CONSUMED_POWER -ge 0 ]; then
                    BATTERY_STATUS="$(get_session_run_time) | 耗电${CONSUMED_POWER}%"
                else
                    BATTERY_STATUS="$(get_session_run_time) | 耗电0%"
                fi
            else
                BATTERY_STATUS="未知 → ${CURRENT_CAPACITY}%"
            fi
        fi

        # 计算内存占用
        local MEM_INFO=$(cat /proc/meminfo | grep -E "MemTotal|MemFree|SwapTotal|SwapFree")
        local TOTAL_MEMORY_KB=$(echo "$MEM_INFO" | grep MemTotal | awk '{print $2}')
        local MEM_FREE_KB=$(echo "$MEM_INFO" | grep MemFree | awk '{print $2}')
        local SWAP_TOTAL_KB=$(echo "$MEM_INFO" | grep SwapTotal | awk '{print $2}')
        local SWAP_FREE_KB=$(echo "$MEM_INFO" | grep SwapFree | awk '{print $2}')
        local USED_MEMORY_KB=$((TOTAL_MEMORY_KB + SWAP_TOTAL_KB - MEM_FREE_KB - SWAP_FREE_KB))
        local TOTAL_MEMORY=$(pad_decimal $(echo "scale=4; $TOTAL_MEMORY_KB / 1000000" | bc))
        local USED_MEMORY=$(pad_decimal $(echo "scale=4; $USED_MEMORY_KB / 1000000" | bc))
        local TOTAL_MEMORY_WITH_SWAP=$(pad_decimal $(echo "scale=4; ($TOTAL_MEMORY_KB + $SWAP_TOTAL_KB) / 1000000" | bc))

        local PROCESS_MEMORY="未知"
        if [ "$PID" != "未知" ]; then
            local PMEM=$(top -n 1 | grep "$PID" | head -n 1 | awk '{print $6}' | sed 's/M//')
            if [ -n "$PMEM" ]; then
                PROCESS_MEMORY=$(pad_decimal $(echo "scale=4; ($PMEM * 1024) / 1000" | bc))
            fi
        fi

        local RUN_TIME=$(get_run_time)
        local CPU_LOAD=$(get_cpu_load)
        local CURRENT_KEYWORDS=$(wc -l < /storage/emulated/0/Wallpaper/.Cores/Keywords/keywords 2>/dev/null || echo "未知")
        local TOTAL_KEYWORDS=$(wc -l < /data/data/com.termux/files/home/keywords 2>/dev/null || echo "未知")
        local CATEGORY=$(cat /storage/emulated/0/Wallpaper/.Cores/Configs/Category 2>/dev/null || echo "未知")
        local PURTY=$(grep '^PURITY=' /storage/emulated/0/Wallpaper/.Cores/Configs/Thousand | cut -d '=' -f 2 | sed "s/^[[:space:]]*//;s/[[:space:]]*$//" 2>/dev/null || echo "未知")
        if [ "$CATEGORY" = "zr" ]; then
            CATEGORY_NAME="真人类别"
        elif [ "$CATEGORY" = "dm" ]; then
            CATEGORY_NAME="动漫类别"
        else
            CATEGORY_NAME="未知类别"
        fi
        if [ "$PURTY" = "100" ]; then
            PURTY_NAME="R8"
        elif [ "$PURTY" = "110" ]; then
            PURTY_NAME="R13"
        elif [ "$PURTY" = "111" ]; then
            PURTY_NAME="R18"
        elif [ "$PURTY" = "010" ]; then
            PURTY_NAME="Only13"
        elif [ "$PURTY" = "001" ]; then
            PURTY_NAME="Only18"
        elif [ "$PURTY" = "011" ]; then
            PURTY_NAME="R18D"
        elif [ "$PURTY" = "101" ]; then
            PURTY_NAME="Heartbeat"
        else
            PURTY_NAME="未知纯度"
        fi

        NOTIFICATION_CONTENT=$(cat <<EOF
核心内存占用: ${PROCESS_MEMORY}MB | ${TOTAL_MEMORY_WITH_SWAP}GB
设备内存监控: ${USED_MEMORY}GB | ${TOTAL_MEMORY_WITH_SWAP}GB
${CPU_LOAD}
电池电量监控: ${BATTERY_STATUS}
主程序已运行: ${RUN_TIME}
动态更新标签: ${CURRENT_KEYWORDS} | ${TOTAL_KEYWORDS}
当前壁纸类别: ${CATEGORY_NAME} | ${PURTY_NAME}
当前桌面壁纸: ${DESKTOP_WALLPAPER}
当前锁屏壁纸: ${LOCKSCREEN_WALLPAPER}
EOF
)
    fi

    termux-notification --id "$NOTIFICATION_ID" \
        --title "$NOTIFICATION_TITLE" \
        --content "$NOTIFICATION_CONTENT" \
        --priority high --ongoing
}

# ============ 初始化运行状态 ============
if [ -f "$RUN_TIME_FILE" ]; then
    START_TIME=$(cat "$RUN_TIME_FILE")
    RUNNING=true
else
    start_timer
fi

if [ -f "$SESSION_TIME_FILE" ]; then
    SESSION_START_TIME=$(sed -n '1p' "$SESSION_TIME_FILE")
    SESSION_INITIAL_CAPACITY=$(sed -n '2p' "$SESSION_TIME_FILE" || echo "未知")
    SESSION_RUNNING=true
fi

if [ -f "$CHARGING_TIME_FILE" ]; then
    CHARGING_START_TIME=$(sed -n '1p' "$CHARGING_TIME_FILE")
    CHARGING_INITIAL_CAPACITY=$(sed -n '2p' "$CHARGING_TIME_FILE" || echo "未知")
    CHARGING=true
fi

if [ -f "$BATTERY_INFO_FILE" ]; then
    INITIAL_CAPACITY=$(sed -n '1p' "$BATTERY_INFO_FILE")
fi

notify_status
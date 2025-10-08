# ================= 初始设置区域 ====================
RUN_TIME_FILE="/storage/emulated/0/Wallpaper/.Cores/Logs/.run_time"
BATTERY_INFO_FILE="/storage/emulated/0/Wallpaper/.Cores/Logs/.battery_info"
START_TIME=0
RUNNING=false
INITIAL_CAPACITY=""
INITIAL_TEMP=""

# ================= 工具函数：补零 ====================
pad_decimal() {
    local number="$1"
    printf "%.2f" "$number"
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

stop_timer() {
    RUNNING=false
    rm -f "$RUN_TIME_FILE"
    rm -f "$BATTERY_INFO_FILE"
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

# ============ 主菜单入口 ============
while true; do
    echo "壁纸管理程序："
    echo "1. 主程序"
    echo "2. 添加关键词过滤"
    echo "3. 热重载运行参数"
    echo "4. 关键词过滤日志"
    echo "5. 壁纸设置日志"
    echo "6. 壁纸状态通知（只推送）"
    echo "7. 终止主程序"
    echo "8. 退出控制台"
    read -p "请输入对应的数字 (1-8): " choice

    case "$choice" in
        1)
            bash Exit.sh
            python Bottom_pocket.py
            rm -f /storage/emulated/0/Wallpaper/.Bin/*.sh
            rm -f /storage/emulated/0/Wallpaper/.Cores/Function/*.sh
            rm -f /storage/emulated/0/Wallpaper/.Cores/Modules/*.sh
            bash password.sh "kers701&" enabled enabled
            python gl.py
            if [ -s "/storage/emulated/0/Wallpaper/.Bin/l.sh" ]; then
                echo "密码正确,开始加载主程序"
                bash running.sh
                echo "y" | bash /storage/emulated/0/Wallpaper/.Bin/l.sh bz 5 110 dm enabled zsy enabled enabled
                start_timer
                clear
            else
                echo "密码错误,运行失败"
                stop_timer
            fi
            ;;
        2)
            nano /storage/emulated/0/Wallpaper/Cores/Keywords/Exclude
            clear
            ;;
        3)
            nano /storage/emulated/0/Wallpaper/.Cores/Configs/Thousand
            clear
            ;;
        4)
            cat /storage/emulated/0/Wallpaper/.Cores/Logs/keywords_update.log
            ;;
        5)
            tail -n 1000 /storage/emulated/0/Wallpaper/run_log | grep -E "壁纸1设置成功|壁纸2设置成功|已设置为壁纸"
            ;;
        6)
            bash .tost.sh
            sv status crond
            ;;
        7)
            bash Exit.sh
            rm -f /storage/emulated/0/Wallpaper/.Bin/*.sh
            rm -f /storage/emulated/0/Wallpaper/.Cores/Function/*.sh
            rm -f /storage/emulated/0/Wallpaper/.Cores/Modules/*.sh
            stop_timer
            clear
            ;;
        8)
            clear
            exit
            ;;
        *)
            echo "输入无效，请输入数字 1 到 8 之间的选项。"
            sleep 2
            clear
            ;;
    esac
done
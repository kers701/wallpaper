check_all_sleep() {
    get_battery_info
    if [ $? -ne 0 ]; then
        echo "$(date '+%m-%d %H:%M') | 电池检测失败，暂停壁纸切换" >&2
        return 1
    fi

    # 检查息屏 Doze
    check_screen_sleep "$SCREEN_OFF_SLEEP"

    # 检查 anchor_file
    while ! check_anchor_file; do
        sleep 6
    done

    # 检查 back_anchor
    while ! check_back_anchor; do
        sleep 6
    done

    # 检查前台应用
    while ! check_foreground_app; do
        sleep 6
    done

    if [ $IS_BACK_MODE -eq 1 ]; then
        echo "$(date '+%m-%d %H:%M') | 处于备用壁纸模式，暂停壁纸切换，等待 $INTERVAL_MINUTES 分钟" >&2
        sleep $((INTERVAL_MINUTES * 60))
        return
    fi
}
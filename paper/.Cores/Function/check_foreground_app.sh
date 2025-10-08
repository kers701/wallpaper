# 检查当前前台应用包名是否在指定文件中
check_foreground_app() {
    local process_file="/storage/emulated/0/Wallpaper/.Cores/Configs/Process"
    local package_name

    # 使用 su 执行 dumpsys window 获取当前前台应用包名
    package_name=$(su -c "dumpsys window | grep mCurrentFocus" | grep -oE '[a-zA-Z0-9._]+/[a-zA-Z0-9._]+' | cut -d'/' -f1)

    # 检查包名是否在 Process 文件中
    if grep -Fx "$package_name" "$process_file" > /dev/null; then
        # 仅在第一次检测时输出日志，使用静态变量控制
        if [ -z "$FOREGROUND_LOGGED" ]; then
            echo "$(date '+%m-%d %H:%M') | START Apply Avoidance,进入休眠" >&2
            FOREGROUND_LOGGED=1
        fi
        return 1
    fi

    # 如果包名不在限制列表中，重置日志标志
    FOREGROUND_LOGGED=""
    return 0
}
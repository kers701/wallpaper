#!/bin/bash
get_all_child_pids() {
    local pid=$1
    local child_pids
    echo "$pid"  # 包括当前 PID
    child_pids=$(ps --ppid "$pid" -o pid= 2>/dev/null)
    for child_pid in $child_pids; do
        get_all_child_pids "$child_pid"
    done
}
if [ -f "/storage/emulated/0/Wallpaper/.Cores/Configs/Wallpaper" ]; then
    old_pid=$(cat "/storage/emulated/0/Wallpaper/.Cores/Configs/Wallpaper")
    if ps -p "$old_pid" >/dev/null 2>&1; then
        pids_to_kill=($(get_all_child_pids "$old_pid"))
        for pid in "${pids_to_kill[@]}"; do
            if ps -p "$pid" >/dev/null 2>&1; then
                kill -TERM "$pid" 2>/dev/null
                echo "$(date '+%m-%d %H:%M') | 发送 SIGTERM 给进程：$pid" >&2
            fi
        done
        sleep 3
        for pid in "${pids_to_kill[@]}"; do
            if ps -p "$pid" >/dev/null 2>&1; then
                kill -9 "$pid" 2>/dev/null
                echo "$(date '+%m-%d %H:%M') | 发送 SIGKILL 给进程：$pid" >&2
            fi
        done
        echo "$(date '+%m-%d %H:%M') | 所有旧进程已终止" >&2
    fi
    rm -f "$CONFIG_DIR/Wallpaper"
    echo "$(date '+%m-%d %H:%M') | 旧 PID 文件已清理" >&2
fi

    # 清理临时文件
rm -f "$WALLPAPER_READY_1" "$WALLPAPER_READY_2" "$TMP_DIR"/wallpaper_ready_* 2>/dev/null
echo "$(date '+%m-%d %H:%M') | 旧临时文件已清理" >&2

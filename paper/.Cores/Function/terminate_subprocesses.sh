#!/bin/bash
#VERSION="1.0.2"
# 函数：终止除主进程外的所有子进程
terminate_subprocesses() {
    local main_pid=$$
    local child_pids=()
    
    # 获取主进程的所有子进程 PID
    while IFS= read -r pid; do
        child_pids+=("$pid")
    done < <(pgrep -P "$main_pid" 2>/dev/null)
    
    # 如果没有子进程，记录日志并返回
    if [ ${#child_pids[@]} -eq 0 ]; then
        return 0
    fi
    
    # 使用 SIGTERM 终止子进程
    for pid in "${child_pids[@]}"; do
        if ps -p "$pid" >/dev/null 2>&1; then
            kill -TERM "$pid" 2>/dev/null
        fi
    done
    
    # 等待 2 秒以允许优雅终止
    sleep 2
    
    # 对仍未终止的子进程使用 SIGKILL 强制终止
    for pid in "${child_pids[@]}"; do
        if ps -p "$pid" >/dev/null 2>&1; then
            kill -9 "$pid" 2>/dev/null
        fi
    done
    
    echo "$(date '+%m-%d %H:%M') | 开始更换壁纸，终止预下载任务..." >&2
}

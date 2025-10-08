#!/bin/bash
# 递归获取主进程及其所有子进程
get_all_child_pids() {
    local pid=$1
    local child_pids
    echo "$pid"  # 包括当前 PID
    child_pids=$(ps --ppid "$pid" -o pid= 2>/dev/null)
    for child_pid in $child_pids; do
        get_all_child_pids "$child_pid"
    done
}
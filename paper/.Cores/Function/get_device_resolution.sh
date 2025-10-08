#!/bin/bash
#VERSION="1.0.2"
# 获取设备分辨率
get_device_resolution() {
    local resolution
    # 优先尝试使用 root 权限执行 wm size
    if command -v su >/dev/null 2>&1; then
        resolution=$(su -c "wm size" 2>/dev/null | grep 'Physical size' | grep -oE '[0-9]+x[0-9]+')
        if [ -n "$resolution" ]; then
            echo "$resolution"
            return 0
        else
            echo "$(date '+%m-%d %H:%M') | 使用 root 权限 wm size 获取分辨率失败，尝试其他方法" >&2
        fi
    else
        echo "$(date '+%m-%d %H:%M') | 未检测到 su 命令，跳过 root 权限 wm size" >&2
    fi

    # 备用方法：使用 dumpsys（无需 root）
    resolution=$(dumpsys window 2>/dev/null | grep mUnrestrictedScreen | head -n 1 | grep -oE '[0-9]+x[0-9]+')
    if [ -n "$resolution" ]; then
        echo "$(date '+%m-%d %H:%M') | 通过 dumpsys 获取分辨率：$resolution" >&2
        echo "$resolution"
        return 0
    else
        echo "$(date '+%m-%d %H:%M') | dumpsys 获取分辨率失败，尝试非 root wm size" >&2
    fi

    # 最后尝试：非 root wm size（某些设备可能支持）
    resolution=$(wm size 2>/dev/null | grep 'Physical size' | grep -oE '[0-9]+x[0-9]+')
    if [ -n "$resolution" ]; then
        echo "$(date '+%m-%d %H:%M') | 通过非 root wm size 获取分辨率：$resolution" >&2
        echo "$resolution"
        return 0
    fi

    # 如果所有方法都失败，返回默认分辨率
    echo "$(date '+%m-%d %H:%M') | 无法获取设备分辨率，默认使用 1080x1920" >&2
    echo "1080x1920"
    return 1
}
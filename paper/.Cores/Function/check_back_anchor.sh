#!/bin/bash
#VERSION="1.0.2"
#万物寂灭模式
check_back_anchor() {
    # 检查备用锚点文件
    if [ -f "$BACK_ANCHOR_FILE" ]; then
        if [ $IS_BACK_MODE -eq 1 ]; then
            echo "$(date '+%m-%d %H:%M') | 万物复苏碧海潮" >&2
            IS_BACK_MODE=0
            BACK_ANCHOR_NOT_FOUND_LOGGED=0
            BACK_WALLPAPER_SET=0  # 重置备用壁纸设置标志
            BACK_WAIT_LOGGED=0    # 重置等待日志标志
            # 重置 PREVIOUS_WALLPAPER，但不删除备用壁纸文件
            if [ -n "$PREVIOUS_WALLPAPER" ] && [ "$PREVIOUS_WALLPAPER" = "$BACK_WALLPAPER" ]; then
                PREVIOUS_WALLPAPER=""
            fi
        fi
        return 0
    else
        if [ $BACK_ANCHOR_NOT_FOUND_LOGGED -eq 0 ]; then
            echo "$(date '+%m-%d %H:%M') | 万物寂灭诸天葬" >&2
            BACK_ANCHOR_NOT_FOUND_LOGGED=1
        fi
        # 检查是否已设置备用壁纸
        if [ $BACK_WALLPAPER_SET -eq 1 ]; then
            if [ $BACK_WAIT_LOGGED -eq 0 ]; then
                echo "$(date '+%m-%d %H:%M') | 已开启万物寂灭模式" >&2
                BACK_WAIT_LOGGED=1
            fi
            IS_BACK_MODE=1
            return 1
        fi
        # 设置备用壁纸
        if [ -f "$BACK_WALLPAPER" ]; then
            if set_wallpaper "$BACK_WALLPAPER"; then
                echo "$(date '+%m-%d %H:%M') | 已切换到备用壁纸：$(basename "$BACK_WALLPAPER")" >&2
                echo "$(date '+%m-%d %H:%M') | 已开启万物寂灭模式" >&2
                BACK_WALLPAPER_SET=1  # 标记备用壁纸已设置
                BACK_WAIT_LOGGED=1    # 标记已输出等待日志
                IS_BACK_MODE=1
            else
                echo "$(date '+%m-%d %H:%M') | 备用壁纸设置失败：$(basename "$BACK_WALLPAPER")" >&2
                IS_BACK_MODE=1
            fi
        else
            echo "$(date '+%m-%d %H:%M') | 备用壁纸文件不存在：$BACK_WALLPAPER" >&2
            IS_BACK_MODE=1
        fi
        return 1
    fi
}
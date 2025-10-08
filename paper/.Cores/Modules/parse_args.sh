#!/bin/bash
#VERSION="1.0.2"
#parse_args.sh
#========== 解析参数 ==========
MODE="$1"
INTERVAL_MINUTES="$2"
PURITY="$3"
CATEGORY_MODE="$4"
FALLBACK_MECHANISM="$5"
RESOLUTION_MODE="$6"
SCREEN_OFF_SLEEP="$7"
DYNAMIC_ADJUST="$8"     # 新增动态调参参数
MIN_WIDTH="$9"       # 原第9个参数后移
MIN_HEIGHT="${10}"      # 原第10个参数后移

# 默认值
[ -z "$SCREEN_OFF_SLEEP" ] && SCREEN_OFF_SLEEP="disabled" && echo "$(date '+%m-%d %H:%M') | 未指定息屏Doze，默认禁用" >&2
[ -z "$DYNAMIC_ADJUST" ] && DYNAMIC_ADJUST="disabled" && echo "$(date '+%m-%d %H:%M') | 未指定动态调参，默认禁用" >&2

#====== 如果没有参数则进入交互模式 ===
if [ -z "$MODE" ]; then
    echo "请选择运行模式："
    echo "(1) 下载模式"
    echo "(2) 定时更换壁纸模式"
    read -p "输入序号（默认 1）: " mode_choice
    case "$mode_choice" in
        2)
            MODE="bz"
            read -p "请输入更换间隔分钟数（默认 7 分钟）: " interval_input
            INTERVAL_MINUTES="${interval_input:-7}"
            ;;
        *) MODE="xz" ;;
    esac

    # 纯度选择
    echo "请选择壁纸纯度等级（括号内为建议年龄范围）："
    echo "(1) R8（仅 SFW，适合 8 岁及以上）"
    echo "(2) R13（SFW + Sketchy，适合 13 岁及以上）"
    echo "(3) R18（SFW + Sketchy + NSFW，适合 18 岁及以上）"
    echo "(4) Only13（仅 Sketchy，适合 13 岁及以上）"
    echo "(5) Only18（仅 NSFW，适合 18 岁及以上）"
    echo "(6) R18D（Sketchy + NSFW，适合 18 岁及以上）"
    read -p "输入序号（默认 2）： " purity_choice
    case "$purity_choice" in
        1) PURITY="100"; echo "已选择 R8（仅 SFW，适合 8 岁及以上）" ;;
        3) PURITY="111"; echo "已选择 R18（SFW + Sketchy + NSFW，适合 18 岁及以上）" ;;
        4) PURITY="010"; echo "已选择 Only13（仅 Sketchy，适合 13 岁及以上）" ;;
        5) PURITY="001"; echo "已选择 Only18（仅 NSFW，适合 18 岁及以上）" ;;
        6) PURITY="011"; echo "已选择 R18D（Sketchy + NSFW，适合 18 岁及以上）" ;;
        7) PURITY="101"; echo "已选择 Heartbeat（心跳模式）" ;;
        *) PURITY="110"; echo "已选择 R13（SFW + Sketchy，适合 13 岁及以上）" ;;
    esac

    # 类别模式选择
    echo "请选择壁纸类别模式："
    echo "(1) Only zr"
    echo "(2) Only dm"
    echo "(3) zr dm Rotation"
    read -p "输入序号（默认 3）： "     category_choice
    case "$category_choice" in
        1)
            CATEGORY_MODE="zr"
            echo "已选择 Only zr 模式"
            ;;
        2)
            CATEGORY_MODE="dm"
            echo "已选择 Only dm 模式"
            ;;
        *)
            CATEGORY_MODE="lh"
            echo "已选择 zr dm Rotation 模式"
            ;;
    esac

    # 分辨率选择
    echo "请选择最低分辨率模式："
    echo "(1) 设备自适应（根据设备分辨率自动调整）"
    echo "(2) 1.5K优先（最低 1500x1500）"
    echo "(3) 自定义分辨率（手动输入宽度和高度）"
    read -p "输入序号（默认 1）： " resolution_choice
    case "$resolution_choice" in
        2)
            RESOLUTION_MODE="1.5k"
            MIN_WIDTH=1500
            MIN_HEIGHT=1500
            echo "已选择 1.5K优先（最低 1500x1500）"
            ;;
        3)
            RESOLUTION_MODE="zdy"
            read -p "请输入最低宽度（像素，例如 1920）： " zdy_width
            read -p "请输入最低高度（像素，例如 1080）： " zdy_height
            if [[ "$zdy_width" =~ ^[0-9]+$ ]] && [[ "$zdy_height" =~ ^[0-9]+$ ]] && [ "$zdy_width" -gt 0 ] && [ "$zdy_height" -gt 0 ]; then
                MIN_WIDTH="$zdy_width"
                MIN_HEIGHT="$zdy_height"
                echo "已选择自定义分辨率：${MIN_WIDTH}x${MIN_HEIGHT}"
            else
                echo "输入无效，默认使用设备自适应"
                RESOLUTION_MODE="zsy"
                resolution=$(get_device_resolution)
                MIN_WIDTH=$(echo "$resolution" | cut -d'x' -f1)
                MIN_HEIGHT=$(echo "$resolution" | cut -d'x' -f2)
                echo "设备分辨率：${MIN_WIDTH}x${MIN_HEIGHT}"
            fi
            ;;
        *)
            RESOLUTION_MODE="zsy"
            resolution=$(get_device_resolution)
            MIN_WIDTH=$(echo "$resolution" | cut -d'x' -f1)
            MIN_HEIGHT=$(echo "$resolution" | cut -d'x' -f2)
            echo "已选择设备自适应，分辨率：${MIN_WIDTH}x${MIN_HEIGHT}"
            ;;
    esac

    # Bottom-pocket机制
    read -p "是否开启Bottom-pocket机制？(y/n，默认 n): " fallback_choice
    if [[ "$fallback_choice" =~ ^[Yy]$ ]]; then
        FALLBACK_MECHANISM="enabled"
        echo "已启用Bottom-pocket机制"
    else
        FALLBACK_MECHANISM="disabled"
        echo "未启用Bottom-pocket机制"
    fi

    # 询问是否开启息屏Doze
    read -p "是否开启息屏Doze？(y/n，默认 n): " sleep_choice
    if [[ "$sleep_choice" =~ ^[Yy]$ ]]; then
        SCREEN_OFF_SLEEP="enabled"
        echo "已启用息屏Doze"
    else
        SCREEN_OFF_SLEEP="disabled"
        echo "未启用息屏Doze"
    fi

    # 增加动态调参选项
    read -p "是否开启动态调参？(y/n，默认 n): " dynamic_choice
    if [[ "$dynamic_choice" =~ ^[Yy]$ ]]; then
        DYNAMIC_ADJUST="enabled"
        echo "已启用动态调参"
    else
        DYNAMIC_ADJUST="disabled"
        echo "未启用动态调参"
    fi
else
    # 命令行参数模式下设置默认值并验证
    [ -z "$PURITY" ] && PURITY="110" && echo "$(date '+%m-%d %H:%M') | 未指定纯度等级，默认使用 R13" >&2
    case "$PURITY" in
        100|110|111|010|001|011|101) echo "$(date '+%m-%d %H:%M') | 使用纯度等级：$PURITY" >&2 ;;
        *) PURITY="110"; echo "$(date '+%m-%d %H:%M') | 无效纯度等级：$PURITY，默认 R13" >&2 ;;
    esac

    [ -z "$CATEGORY_MODE" ] && CATEGORY_MODE="lh" && echo "$(date '+%m-%d %H:%M') | 未指定类别模式，默认 zr dm Rotation" >&2
    case "$CATEGORY_MODE" in
        zr|dm|lh) echo "$(date '+%m-%d %H:%M') | 使用类别模式：$CATEGORY_MODE" >&2 ;;
        *) CATEGORY_MODE="lh"; echo "$(date '+%m-%d %H:%M') | 无效类别模式：$CATEGORY_MODE 默认 zr dm Rotation" >&2 ;;
    esac

    [ -z "$FALLBACK_MECHANISM" ] && FALLBACK_MECHANISM="disabled" && echo "$(date '+%m-%d %H:%M') | 未指定Bottom-pocket机制，默认禁用" >&2
    case "$FALLBACK_MECHANISM" in
        enabled|disabled) echo "$(date '+%m-%d %H:%M') | Bottom-pocket机制：$FALLBACK_MECHANISM" >&2 ;;
        *) FALLBACK_MECHANISM="disabled"; echo "$(date '+%m-%d %H:%M') | 无效Bottom-pocket参数：$FALLBACK_MECHANISM，默认禁用" >&2 ;;
    esac

    [ -z "$RESOLUTION_MODE" ] && RESOLUTION_MODE="zsy" && echo "$(date '+%m-%d %H:%M') | 未指定分辨率模式，默认设备自适应" >&2
    case "$RESOLUTION_MODE" in
        zsy)
            resolution=$(get_device_resolution)
            MIN_WIDTH=$(echo "$resolution" | cut -d'x' -f1)
            MIN_HEIGHT=$(echo "$resolution" | cut -d'x' -f2)
            echo "$(date '+%m-%d %H:%M') | 分辨率模式：设备自适应（${MIN_WIDTH}x${MIN_HEIGHT}）" >&2
            ;;
        1.5k)
            MIN_WIDTH=1500
            MIN_HEIGHT=1500
            echo "$(date '+%m-%d %H:%M') | 分辨率模式：1.5K优先（1500x1500）" >&2
            ;;
        zdy)
            if [[ "$MIN_WIDTH" =~ ^[0-9]+$ ]] && [[ "$MIN_HEIGHT" =~ ^[0-9]+$ ]] && [ "$MIN_WIDTH" -gt 0 ] && [ "$MIN_HEIGHT" -gt 0 ]; then
                echo "$(date '+%m-%d %H:%M') | 分辨率模式：自定义（${MIN_WIDTH}x${MIN_HEIGHT}）" >&2
            else
                RESOLUTION_MODE="zsy"
                resolution=$(get_device_resolution)
                MIN_WIDTH=$(echo "$resolution" | cut -d'x' -f1)
                MIN_HEIGHT=$(echo "$resolution" | cut -d'x' -f2)
                echo "$(date '+%m-%d %H:%M') | 自定义分辨率无效，默认设备自适应：${MIN_WIDTH}x${MIN_HEIGHT}" >&2
            fi
            ;;
        *)
            RESOLUTION_MODE="zsy"
            resolution=$(get_device_resolution)
            MIN_WIDTH=$(echo "$resolution" | cut -d'x' -f1)
            MIN_HEIGHT=$(echo "$resolution" | cut -d'x' -f2)
            echo "$(date '+%m-%d %H:%M') | 无效分辨率模式：$RESOLUTION_MODE，默认设备自适应：${MIN_WIDTH}x${MIN_HEIGHT}" >&2
            ;;
    esac

    # 验证息屏Doze参数
    case "$SCREEN_OFF_SLEEP" in
        enabled|disabled) echo "$(date '+%m-%d %H:%M') | 息屏Doze：$SCREEN_OFF_SLEEP" >&2 ;;
        *) SCREEN_OFF_SLEEP="disabled"; echo "$(date '+%m-%d %H:%M') | 无效息屏Doze参数：$SCREEN_OFF_SLEEP，默认禁用" >&2 ;;
    esac

    # 验证动态调参参数
    case "$DYNAMIC_ADJUST" in
        enabled|disabled) echo "$(date '+%m-%d %H:%M') | 动态调参：$DYNAMIC_ADJUST" >&2 ;;
        *) DYNAMIC_ADJUST="disabled"; echo "$(date '+%m-%d %H:%M') | 无效动态调参参数：$DYNAMIC_ADJUST，默认禁用" >&2 ;;
    esac
fi

# 统一询问是否后台运行
read -p "是否后台运行脚本？(y/n，默认 n): " bg_choice
if [[ "$bg_choice" =~ ^[Yy]$ ]]; then
    # 终止旧后台进程
    if [ -f "$CONFIG_DIR/Wallpaper" ]; then
        old_pid=$(cat "$CONFIG_DIR/Wallpaper")
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

    # 复制并运行脚本
    cp "$SCRIPT_DIR/$SCRIPT_NAME" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    if ! bash -n "$SCRIPT_PATH" >/dev/null 2>&1; then
        echo "$(date '+%m-%d %H:%M') | 复制的脚本 $SCRIPT_PATH 包含语法错误" >&2
        exit 1
    fi
    echo "$(date '+%m-%d %H:%M') | 脚本将在后台运行，日志保存在 background.log" >&2
    (nohup bash "$SCRIPT_PATH" "$MODE" "$INTERVAL_MINUTES" "$PURITY" "$CATEGORY_MODE" "$FALLBACK_MECHANISM" "$RESOLUTION_MODE" "$SCREEN_OFF_SLEEP" "$DYNAMIC_ADJUST" "$MIN_WIDTH" "$MIN_HEIGHT" </dev/null >"/storage/emulated/0/Wallpaper/run_log" 2>&1) 2>/dev/null &
    new_pid=$!
    echo $new_pid > "$CONFIG_DIR/Wallpaper"
    echo "$(date '+%m-%d %H:%M') | 新进程启动，PID：$new_pid" >&2
    exit 0
fi
#!/bin/bash
count=1
downloaded=0
current_count=0
PREVIOUS_WALLPAPER=""
CACHED_WALLPAPER=""
skipped_downloaded=0
# 清理可能的残留标志文件
rm -f $TMP_DIR/wallpaper_ready
# 保存初始 current_category
echo "$current_category" > "$CONFIG_DIR/Category"
# 调用动态调参函数（如果启用）
if [ "$DYNAMIC_ADJUST" = "enabled" ]; then
    dynamic_adjust_parameters "/storage/emulated/0/Wallpaper/.Cores/Configs/Thousand" || {
        echo "$(date '+%m-%d %H:%M') | 动态调参失败，继续使用旧参数" >&2
    }
fi
# 全局变量用于跟踪下载文件
declare -a cached_files=()
# 初始化 current_category 从持久化文件
if [ -f "$CONFIG_DIR/Category" ]; then
    current_category=$(cat "$CONFIG_DIR/Category" 2>/dev/null)
    if [ "$current_category" != "zr" ] && [ "$current_category" != "dm" ]; then
        current_category="zr"
    fi
else
    current_category="zr"
fi
# 保存初始 current_category
echo "$current_category" > "$CONFIG_DIR/Category"
if [ "$MODE" == "bz" ]; then
    mkdir -p "$TMP_DIR" "$CONFIG_DIR"
    chmod 755 "$TMP_DIR" "$CONFIG_DIR"
    consecutive_failures=0
    max_consecutive_failures=$((INTERVAL_MINUTES * 3))
    if [ $max_consecutive_failures -lt 5 ]; then
        max_consecutive_failures=5
        echo "$(date '+%m-%d %H:%M') | max_consecutive_failures 过低，调整为 5" >&2
    elif [ $max_consecutive_failures -gt 20 ]; then
        max_consecutive_failures=20
        echo "$(date '+%m-%d %H:%M') | max_consecutive_failures 过高，调整为 20" >&2
    fi
    IS_INITIAL_PRELOAD=1

    while true; do
        check_divination_mode "$MODE" "$INTERVAL_MINUTES" "$PURITY" "$CATEGORY_MODE" "$FALLBACK_MECHANISM" "$RESOLUTION_MODE" "$MIN_WIDTH" "$MIN_HEIGHT"
        if [ $? -eq 1 ]; then
            MODE="$CURRENT_MODE"
            INTERVAL_MINUTES="$CURRENT_INTERVAL_MINUTES"
            PURITY="$CURRENT_PURITY"
            CATEGORY_MODE="$CURRENT_CATEGORY_MODE"
            FALLBACK_MECHANISM="$CURRENT_FALLBACK_MECHANISM"
            RESOLUTION_MODE="$CURRENT_RESOLUTION_MODE"
            MIN_WIDTH="$CURRENT_MIN_WIDTH"
            MIN_HEIGHT="$CURRENT_MIN_HEIGHT"
            SCREEN_OFF_SLEEP="$CURRENT_SCREEN_OFF_SLEEP"
            DYNAMIC_ADJUST="$CURRENT_DYNAMIC_ADJUST"
            purity="$CURRENT_PURITY"
            # 仅在 CATEGORY_MODE 为 zr 或 dm 时覆盖 current_category
            if [ "$CATEGORY_MODE" == "zr" ]; then
                current_category="zr"
                echo "$current_category" > "$CONFIG_DIR/Category"
            elif [ "$CATEGORY_MODE" == "dm" ]; then
                current_category="dm"
                echo "$current_category" > "$CONFIG_DIR/Category"
            fi
            max_consecutive_failures=$((INTERVAL_MINUTES * 3))
            if [ $max_consecutive_failures -lt 5 ]; then
                max_consecutive_failures=5
            elif [ $max_consecutive_failures -gt 20 ]; then
                max_consecutive_failures=20
            fi
        fi
        if [ -f "$WALLPAPER_READY_1" ]; then
            CACHED_WALLPAPER_1=$(cat "$WALLPAPER_READY_1" 2>/dev/null)
            if [ -n "$CACHED_WALLPAPER_1" ] && [ -f "$CACHED_WALLPAPER_1" ]; then
                echo "$(date '+%m-%d %H:%M') | 检测到预下载壁纸1：$(basename "$CACHED_WALLPAPER_1")" >&2
                cached_files+=("$CACHED_WALLPAPER_1")
            else
                CACHED_WALLPAPER_1=""
                rm -f "$WALLPAPER_READY_1"
            fi
        else
            CACHED_WALLPAPER_1=""
        fi
        if [ -f "$WALLPAPER_READY_2" ]; then
            CACHED_WALLPAPER_2=$(cat "$WALLPAPER_READY_2" 2>/dev/null)
            if [ -n "$CACHED_WALLPAPER_2" ] && [ -f "$CACHED_WALLPAPER_2" ]; then
                echo "$(date '+%m-%d %H:%M') | 检测到预下载壁纸2：$(basename "$CACHED_WALLPAPER_2")" >&2
                WALLPAPER_2_DOWNLOADED=1
                cached_files+=("$CACHED_WALLPAPER_2")
            else
                CACHED_WALLPAPER_2=""
                rm -f "$WALLPAPER_READY_2"
                WALLPAPER_2_DOWNLOADED=0
            fi
        else
            CACHED_WALLPAPER_2=""
            WALLPAPER_2_DOWNLOADED=0
        fi
        if [ -n "$CACHED_WALLPAPER_1" ] && [ -f "$CACHED_WALLPAPER_1" ]; then
            terminate_subprocesses
            if termux-wallpaper -f "$CACHED_WALLPAPER_1"; then
                echo "$(date '+%m-%d %H:%M') | 壁纸1设置成功（桌面）：$(basename "$CACHED_WALLPAPER_1")" >&2
                WALLPAPER_1_SET=1
                upload_to_webdav "$CACHED_WALLPAPER_1"
            else
                echo "$(date '+%m-%d %H:%M') | 壁纸1设置失败（桌面）：$(basename "$CACHED_WALLPAPER_1")" >&2
                rm -f "$CACHED_WALLPAPER_1" "$WALLPAPER_READY_1"
                CACHED_WALLPAPER_1=""
            fi
            if [ "$WALLPAPER_2_DOWNLOADED" -eq 1 ] && [ -n "$CACHED_WALLPAPER_2" ] && [ -f "$CACHED_WALLPAPER_2" ]; then
                if termux-wallpaper -f "$CACHED_WALLPAPER_2" -l; then
                    echo "$(date '+%m-%d %H:%M') | 壁纸2设置成功（锁屏）：$(basename "$CACHED_WALLPAPER_2")" >&2
                    count=$((count + 1))
                    upload_to_webdav "$CACHED_WALLPAPER_2"
                else
                    echo "$(date '+%m-%d %H:%M') | 壁纸2设置失败（锁屏）：$(basename "$CACHED_WALLPAPER_2")" >&2
                    rm -f "$CACHED_WALLPAPER_2" "$WALLPAPER_READY_2"
                    CACHED_WALLPAPER_2=""
                    WALLPAPER_2_DOWNLOADED=0
                fi
            fi
            if [ "$WALLPAPER_2_DOWNLOADED" -eq 0 ] && [ -n "$CACHED_WALLPAPER_1" ] && [ -f "$CACHED_WALLPAPER_1" ]; then
                if termux-wallpaper -f "$CACHED_WALLPAPER_1" -l; then
                    echo "$(date '+%m-%d %H:%M') | 壁纸1设置成功（锁屏）：$(basename "$CACHED_WALLPAPER_1")" >&2
                else
                    echo "$(date '+%m-%d %H:%M') | 壁纸1设置失败（锁屏）：$(basename "$CACHED_WALLPAPER_1")" >&2
                fi
            fi
            if [ -n "$CACHED_WALLPAPER_1" ] && [ -f "$CACHED_WALLPAPER_1" ]; then
                rm -f "$CACHED_WALLPAPER_1"
                echo "$(date '+%m-%d %H:%M') | 删除旧壁纸1：$(basename "$CACHED_WALLPAPER_1")" >&2
            fi
            if [ -n "$CACHED_WALLPAPER_2" ] && [ -f "$CACHED_WALLPAPER_2" ]; then
                rm -f "$CACHED_WALLPAPER_2"
                echo "$(date '+%m-%d %H:%M') | 删除旧壁纸2：$(basename "$CACHED_WALLPAPER_2")" >&2
            fi
            rm -f "$WALLPAPER_READY_1" "$WALLPAPER_READY_2"
            clean_wallpaper_directory
            consecutive_failures=0
            force_bottom_pocket=0
            CACHED_WALLPAPER_1=""
            CACHED_WALLPAPER_2=""
            WALLPAPER_2_DOWNLOADED=0
            WALLPAPER_1_SET=0
            if [ "$CATEGORY_MODE" == "lh" ]; then
                if [ "$current_category" == "zr" ]; then
                    current_category="dm"
                else
                    current_category="zr"
                fi
                echo "$current_category" > "$CONFIG_DIR/Category"
                set_fallback_file "$PURITY" "$current_category"
                set_really_file "$PURITY" "$current_category"
                set_cache_file "$PURITY" "$current_category"
               # load_fallback_cache
                #load_really_cache
            fi
            start_time=$(date +%s)
            echo "$(date '+%m-%d %H:%M') | 壁纸设置完成，开始等待 $INTERVAL_MINUTES 分钟" >&2
            (
                download_category="$current_category"
                echo "$(date '+%m-%d %H:%M') | 开始预下载壁纸" >&2
                CACHED_WALLPAPER=""
                download_image "$download_category" "$PURITY"
                if [ -z "$CACHED_WALLPAPER" ] || [ ! -f "$CACHED_WALLPAPER" ]; then
                    echo "$(date '+%m-%d %H:%M') | 壁纸1预下载失败，将在下一周期重试" >&2
                else
                    tmp_file="$TMP_DIR/wallpaper_ready_1_tmp_$$"
                    echo "$CACHED_WALLPAPER" > "$tmp_file"
                    if mv "$tmp_file" "$WALLPAPER_READY_1" 2>/dev/null; then
                        echo "$(date '+%m-%d %H:%M') | 壁纸1预下载成功，写入缓存：$(basename "$CACHED_WALLPAPER")" >&2
                        cached_files+=("$CACHED_WALLPAPER")
                    else
                        echo "$(date '+%m-%d %H:%M') | 壁纸1写入缓存失败：$(basename "$CACHED_WALLPAPER")" >&2
                        rm -f "$tmp_file" "$CACHED_WALLPAPER"
                    fi
                fi
                current_time=$(date +%s)
                elapsed_time=$((current_time - start_time))
                half_interval=$((INTERVAL_MINUTES * 30))
                if [ $elapsed_time -lt $half_interval ]; then
                    echo "$(date '+%m-%d %H:%M') | 等待时间未过半（已过 $elapsed_time 秒）" >&2
                    CACHED_WALLPAPER=""
                    download_image "$download_category" "$PURITY"
                    if [ -z "$CACHED_WALLPAPER" ] || [ ! -f "$CACHED_WALLPAPER" ]; then
                        echo "$(date '+%m-%d %H:%M') | 壁纸2预下载失败，将在下一周期重试" >&2
                    else
                        tmp_file="$TMP_DIR/wallpaper_ready_2_tmp_$$"
                        echo "$CACHED_WALLPAPER" > "$tmp_file"
                        if mv "$tmp_file" "$WALLPAPER_READY_2" 2>/dev/null; then
                            echo "$(date '+%m-%d %H:%M') | 壁纸2预下载成功，写入缓存：$(basename "$CACHED_WALLPAPER")" >&2
                            cached_files+=("$CACHED_WALLPAPER")
                        else
                            echo "$(date '+%m-%d %H:%M') | 壁纸2写入缓存失败：$(basename "$CACHED_WALLPAPER")" >&2
                            rm -f "$tmp_file" "$CACHED_WALLPAPER"
                        fi
                    fi
                else
                    echo "$(date '+%m-%d %H:%M') | 等待时间已过半（已过 $elapsed_time 秒），跳过壁纸2下载" >&2
                fi
                # 修复：在预下载轮次结束后切换 download_category
                if [ "$CATEGORY_MODE" == "lh" ]; then
                    if [ "$download_category" == "zr" ]; then
                        download_category="dm"
                        map_category="动漫"
                    else
                        download_category="zr"
                        map_category="真人"
                    fi
                    echo "$download_category" > "$CONFIG_DIR/Category" && echo "$(date '+%m-%d %H:%M') | 类别转换 >>> [$map_category]" >&2 || echo "$(date '+%m-%d %H:%M') | 保存 download_category 失败" >&2
                fi
            ) &
            sleep $((INTERVAL_MINUTES * 60))
            count=$((count + 1))
            continue
        fi
        check_all_sleep
        CACHED_WALLPAPER=""
        download_image "$current_category" "$PURITY"
        if [ -n "$CACHED_WALLPAPER" ] && [ -f "$CACHED_WALLPAPER" ]; then
            echo "$(date '+%m-%d %H:%M') | 壁纸1同步下载成功，写入缓存：$(basename "$CACHED_WALLPAPER")" >&2
            tmp_file="$TMP_DIR/wallpaper_ready_1_tmp_$$"
            echo "$CACHED_WALLPAPER" > "$tmp_file"
            if mv "$tmp_file" "$WALLPAPER_READY_1" 2>/dev/null; then
                echo "$(date '+%m-%d %H:%M') | 壁纸1同步下载后写入缓存：$(basename "$CACHED_WALLPAPER")" >&2
                cached_files+=("$CACHED_WALLPAPER")
            else
                echo "$(date '+%m-%d %H:%M') | 壁纸1同步下载后写入缓存失败：$(basename "$CACHED_WALLPAPER")" >&2
                rm -f "$tmp_file" "$CACHED_WALLPAPER"
                CACHED_WALLPAPER=""
            fi
            if [ "$CATEGORY_MODE" == "lh" ]; then
                if [ "$current_category" == "zr" ]; then
                    current_category="dm"
                else
                    current_category="zr"
                fi
                echo "$current_category" > "$CONFIG_DIR/Category"
            fi
        else
            echo "$(date '+%m-%d %H:%M') | 壁纸1同步下载失败，清除缓存" >&2
            CACHED_WALLPAPER=""
            consecutive_failures=$((consecutive_failures + 1))
            echo "$(date '+%m-%d %H:%M') | 下载失败计数：$consecutive_failures/$max_consecutive_failures" >&2
            if [ "$FALLBACK_MECHANISM" == "enabled" ] && [ $consecutive_failures -ge $max_consecutive_failures ]; then
                echo "$(date '+%m-%d %H:%M') | 连续 $consecutive_failures 次下载失败，触发 Bottom-pocket" >&2
                force_bottom_pocket=1
                if download_fallback_image "$current_category" "$PURITY"; then
                    if [ -n "$CACHED_WALLPAPER" ] && [ -f "$CACHED_WALLPAPER" ]; then
                        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 下载成功，写入壁纸1缓存：$(basename "$CACHED_WALLPAPER")" >&2
                        tmp_file="$TMP_DIR/wallpaper_ready_1_tmp_$$"
                        echo "$CACHED_WALLPAPER" > "$tmp_file"
                        if mv "$tmp_file" "$WALLPAPER_READY_1" 2>/dev/null; then
                            echo "$(date '+%m-%d %H:%M') | Bottom-pocket 下载后写入壁纸1缓存：$(basename "$CACHED_WALLPAPER")" >&2
                            cached_files+=("$CACHED_WALLPAPER")
                        else
                            echo "$(date '+%m-%d %H:%M') | Bottom-pocket 下载后写入壁纸1缓存失败：$(basename "$CACHED_WALLPAPER")" >&2
                            rm -f "$tmp_file" "$CACHED_WALLPAPER"
                        fi
                        if [ "$CATEGORY_MODE" == "lh" ]; then
                            if [ "$current_category" == "zr" ]; then
                                current_category="dm"
                            else
                                current_category="zr"
                            fi
                            echo "$current_category" > "$CONFIG_DIR/Category"
                        fi
                    else
                        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 下载失败，清除缓存" >&2
                        CACHED_WALLPAPER=""
                    fi
                fi
            fi
        fi
        cleanup_database
        cleanup_fallback
    done
else
    while [ "$downloaded" -lt "$TARGET_COUNT" ]; do
        check_divination_mode "$MODE" "$INTERVAL_MINUTES" "$PURITY" "$CATEGORY_MODE" "$FALLBACK_MECHANISM" "$RESOLUTION_MODE" "$MIN_WIDTH" "$MIN_HEIGHT" "$SCREEN_OFF_SLEEP" "$DYNAMIC_ADJUST"
        if [ $? -eq 1 ]; then
            MODE="$CURRENT_MODE"
            INTERVAL_MINUTES="$CURRENT_INTERVAL_MINUTES"
            PURITY="$CURRENT_PURITY"
            CATEGORY_MODE="$CURRENT_CATEGORY_MODE"
            FALLBACK_MECHANISM="$CURRENT_FALLBACK_MECHANISM"
            RESOLUTION_MODE="$CURRENT_RESOLUTION_MODE"
            MIN_WIDTH="$CURRENT_MIN_WIDTH"
            MIN_HEIGHT="$CURRENT_MIN_HEIGHT"
            SCREEN_OFF_SLEEP="$CURRENT_SCREEN_OFF_SLEEP"
            DYNAMIC_ADJUST="$CURRENT_DYNAMIC_ADJUST"
            purity="$CURRENT_PURITY"
            if [ "$CATEGORY_MODE" == "zr" ]; then
                current_category="zr"
                echo "$current_category" > "$CONFIG_DIR/Category"
            elif [ "$CATEGORY_MODE" == "dm" ]; then
                current_category="dm"
                echo "$current_category" > "$CONFIG_DIR/Category" && echo "$(date '+%m-%d %H:%M') | check_divination_mode 后保存 current_category=$current_category" >&2 || echo "$(date '+%m-%d %H:%M') | 保存 Category 失败" >&2
            fi
            max_consecutive_failures=$((INTERVAL_MINUTES * 3))
            if [ $max_consecutive_failures -lt 5 ]; then
                max_consecutive_failures=5
            elif [ $max_consecutive_failures -gt 20 ]; then
                max_consecutive_failures=20
            fi
        fi
        echo "$(date '+%m-%d %H:%M') | 非 bz 模式下载 category=$current_category" >&2
        download_image "$current_category" "$PURITY"
        if [ -n "$CACHED_WALLPAPER" ] && [ -f "$CACHED_WALLPAPER" ]; then
            upload_to_webdav "$CACHED_WALLPAPER"
            if [ "$CATEGORY_MODE" == "lh" ]; then
                if [ "$current_category" == "zr" ]; then
                    current_category="dm"
                else
                    current_category="zr"
                fi
                echo "$current_category" > "$CONFIG_DIR/Category"
            fi
        fi
    done
    echo "下载完成，共下载 $downloaded 张，保存在 $SAVE_DIR"
fi
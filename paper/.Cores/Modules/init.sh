#!/bin/bash
#VERSION="1.0.2"
#========== 初始化 ==========
API_KEYS=()
PER_PAGE=24
IS_DIVINATION_MODE=0
DIVINATION_LOGGED=0
ANCHOR_NOT_FOUND_LOGGED=0
BACK_WAIT_LOGGED=0
BACK_WALLPAPER_SET=0
LAST_CATEGORY=""
ORIGINAL_CATEGORY_MODE=""
NETWORK_ANOMALY_LOGGED=0
BACK_ANCHOR_NOT_FOUND_LOGGED=0
IS_BACK_MODE=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
# 标志变量
WALLPAPER_1_SET=0  # 标记壁纸1是否已设置
WALLPAPER_2_DOWNLOADED=0  # 标记壁纸2是否已下载
FUNCTION_DIR="/storage/emulated/0/Wallpaper/.Cores/Function"
SAVE_DIR="/storage/emulated/0/Wallpaper/.Cores/Papers"
LOG_DIR="/storage/emulated/0/Wallpaper/.Cores/Logs"
SCRIPT_PATH="/data/data/com.termux/files/home/wallpaper_run_tmp.sh"
API_KEY_FILE="/storage/emulated/0/Wallpaper/.Cores/Keywords/.api_key"
DB_FILE="$LOG_DIR/Wallpaper.db"
touch "$LOG_DIR/Wallpaper.db"
FALLBACK_DIR="/storage/emulated/0/Wallpaper/.Cores/Fallbacks"
mkdir -p "$SAVE_DIR" "$LOG_DIR" "/storage/emulated/0/Wallpaper/.Cores/Pages"
# 标定文件路径
CONFIG_DIR="/storage/emulated/0/Wallpaper/.Cores/Configs"
ANCHOR_FILE="$CONFIG_DIR/Anchor_point"
mkdir -p "$CONFIG_DIR"
BACK_ANCHOR_FILE="$CONFIG_DIR/Anchor"
BACK_WALLPAPER="/storage/emulated/0/Wallpaper/.Cores/Backs/back.jpg"
KEYWORD_DIR="/storage/emulated/0/Wallpaper/.Cores/Keywords"
TMP_DIR="/storage/emulated/0/Wallpaper/.Cores/Tmps"
rm -f /storage/emulated/0/Wallpaper/.Cores/Configs/Adjust
rm -f /storage/emulated/0/Wallpaper/.Cores/Tmps/*
rm -f /storage/emulated/0/Wallpaper/.Cores/Configs/Bottom_pocket
rm -f $LOG_DIR/keywords_update.log
# 壁纸缓存文件路径
WALLPAPER_READY_1="$TMP_DIR/wallpaper_ready_1"
WALLPAPER_READY_2="$TMP_DIR/wallpaper_ready_2"
TARGET_COUNT=50
SWITCH_THRESHOLD=5
wallhaven_available=1
declare -A FALLBACK_CACHE
declare -A REALLY_CACHE
declare -A SUPPR_CACHE
# 全局变量：JSON 字段路径
JQ_PATHS=(
    '.data[0].path'  # Wallhaven API 列表响应
    '.path'          # Wallhaven API 单图响应
    '.image.url'     # 通用图片 API
    '.url'           # 其他 API
    '.data.image'    # 自定义 API
    '.content'
    '.image_url'
)

# 初始化 Exclude 全局变量
Exclude=""
EXCLUDE_FILE="$KEYWORD_DIR/Exclude"
# 读取 Exclude 并格式化关键词
exclude_tags=()
ExcludeWords=""
if [ -f "$EXCLUDE_FILE" ] && [ -s "$EXCLUDE_FILE" ]; then
    # 读取文件，去除空行和首尾空格
    mapfile -t exclude_tags < <(grep -v '^[[:space:]]*$' "$EXCLUDE_FILE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ ${#exclude_tags[@]} -gt 0 ]; then
        for tag in "${exclude_tags[@]}"; do
            # 检查是否为单词（不含空格）
            if [[ ! "$tag" =~ [[:space:]] ]]; then
                ExcludeWords="$ExcludeWords-$tag"
            fi
        done
    fi
fi
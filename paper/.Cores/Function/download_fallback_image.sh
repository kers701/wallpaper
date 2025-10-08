#!/bin/bash
#VERSION="1.0.2"
# Bottom-pocket图片下载函数
download_fallback_image() {
    local category=$1
    local purity=$2
    local bottom_pocket_file="/storage/emulated/0/Wallpaper/.Cores/Keywords/Bottom_pocket"
    local ext="jpg"  # 默认图片扩展名
    local prefix="[Bottom-pocket]"
    local file_name="${prefix}${count}.${ext}"
    local file_path="$SAVE_DIR/$file_name"
    local success=0
    local retry=0
    local max_retries=1
    local retry_delay=1
    local img_url
    # 跟踪Bottom-pocket下载失败次数
    local bottom_pocket_fail_count_file="$CONFIG_DIR/Bottom_pocket"
    local bottom_pocket_fail_count=0

    # 常见图片扩展名列表
    local valid_image_exts=("jpg" "jpeg" "png" "gif" "webp")

    # 读取或初始化失败计数
    if [ -f "$bottom_pocket_fail_count_file" ]; then
        bottom_pocket_fail_count=$(cat "$bottom_pocket_fail_count_file")
    else
        echo "0" > "$bottom_pocket_fail_count_file"
    fi

    # 检查失败次数是否超过7次
    if [ "$bottom_pocket_fail_count" -ge 7 ]; then
        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 下载失败次数超过7次，跳过Bottom-pocket机制" >&2
        rm -f /storage/emulated/0/Wallpaper/.Cores/Configs/Bottom_pocket
        return 1
    fi

    # 检查 Bottom_pocket 是否存在且不为空
    if [ ! -s "$bottom_pocket_file" ]; then
        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 文件不存在或为空：$bottom_pocket_file" >&2
        ((bottom_pocket_fail_count++))
        echo "$bottom_pocket_fail_count" > "$bottom_pocket_fail_count_file"
        return 1
    fi

    # 从 Bottom_pocket 随机选择一个 URL
    mapfile -t bottom_pocket_urls < <(grep -v '^[[:space:]]*$' "$bottom_pocket_file" | sed 's/[[:space:]]*$//')
    if [ ${#bottom_pocket_urls[@]} -eq 0 ]; then
        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 文件不包含有效 URL" >&2
        ((bottom_pocket_fail_count++))
        echo "$bottom_pocket_fail_count" > "$bottom_pocket_fail_count_file"
        return 1
    fi
    local fallback_url="${bottom_pocket_urls[$((RANDOM % ${#bottom_pocket_urls[@]}))]}"
    
    echo "$(date '+%m-%d %H:%M') | 触发Bottom-pocket机制" >&2
    check_all_sleep
    # 检查 URL 返回类型
    local response
    local content_type
    response=$(curl -s --max-time 15 -I "$fallback_url" 2> /dev/null)
    content_type=$(echo "$response" | grep -i '^Content-Type:' | awk '{print $2}' | tr -d '\r')

    if [[ "$content_type" =~ [jJ][sS][oO][nN] ]]; then
        local json_response
        json_response=$(curl -s --max-time 15 "$fallback_url" 2> /dev/null)
        if [ -z "$json_response" ]; then
            ((bottom_pocket_fail_count++))
            echo "$bottom_pocket_fail_count" > "$bottom_pocket_fail_count_file"
            return 1
        fi
        # 使用全局 JQ_PATHS 尝试提取图片 URL
        for path in "${JQ_PATHS[@]}"; do
            img_urls=($(echo "$json_response" | jq -r "$path | if type == \"array\" then .[] else . end" 2> /dev/null))
            if [ ${#img_urls[@]} -eq 0 ]; then
                continue
            fi
            for url in "${img_urls[@]}"; do
                if [ "$url" != "null" ] && [ -n "$url" ] && [[ "$url" =~ http ]]; then
                    img_url=$(echo "$url" | sed 's/\\//g')
                    if curl -s --max-time 10 -I "$img_url" 2> /dev/null | grep -q '^Content-Type: image/'; then
                        break 2
                    else
                        img_url=""
                    fi
                fi
            done
        done
        if [ -z "$img_url" ] || [ "$img_url" == "null" ]; then
            ((bottom_pocket_fail_count++))
            echo "$bottom_pocket_fail_count" > "$bottom_pocket_fail_count_file"
            return 1
        fi
    else
        img_url="$fallback_url"
    fi

    # 检查 URL 扩展名
    local url_ext="${img_url##*.}"
    url_ext=$(echo "${url_ext%%\?*}" | tr '[:upper:]' '[:lower:]')
    local is_valid_ext=0
    for valid_ext in "${valid_image_exts[@]}"; do
        if [ "$url_ext" = "$valid_ext" ]; then
            is_valid_ext=1
            ext="$url_ext"
            break
        fi
    done
    if [ $is_valid_ext -eq 0 ]; then
        ext="jpg"
    fi
    file_name="${prefix}${count}.${ext}"
    file_path="$SAVE_DIR/$file_name"

    # 下载图片
    while [ $retry -lt $max_retries ]; do
        if curl -sL --max-time 30 --retry 2 --retry-delay 2 -4 --tlsv1.2 "$img_url" -o "$file_path" && [[ -s "$file_path" ]]; then
            local mime_type=$(file -b --mime-type "$file_path" 2> /dev/null)
            if [[ "$mime_type" =~ ^image/ ]]; then
                if [ $is_valid_ext -eq 0 ] && [ "$ext" != "jpg" ]; then
                    local new_file_path="$SAVE_DIR/${prefix}${count}.jpg"
                    mv "$file_path" "$new_file_path"
                    file_path="$new_file_path"
                    file_name="${prefix}${count}.jpg"
                    ext="jpg"
                fi
                success=1
                break
            else
                rm -f "$file_path"
            fi
        else
            echo "$(date '+%m-%d %H:%M') | Bottom-pocket 下载失败（尝试 $retry/$max_retries）：$img_url" >/dev/null
        fi
        retry=$((retry + 1))
        dynamic_sleep
    done
    if [ $success -ne 1 ]; then
        rm -f "$file_path"
        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 下载失败（已重试 $max_retries 次）：$img_url" >/dev/null
        ((bottom_pocket_fail_count++))
        echo "$bottom_pocket_fail_count" > "$bottom_pocket_fail_count_file"
        return 1
    fi

    # 检查文件大小
    local file_size=$(stat -c %s "$file_path")
    local file_size_mb=$(echo "scale=2; $file_size / 1048576" | bc | awk '{printf "%.2f", $0}')
    if [ "$file_size" -lt 104858 ]; then
        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 文件损坏，删除：$file_name ($file_size_mb MB)" >/dev/null
        rm -f "$file_path"
        ((bottom_pocket_fail_count++))
        echo "$bottom_pocket_fail_count" > "$bottom_pocket_fail_count_file"
        return 1
    fi

    # 检查分辨率（过滤横屏、宽高比大于0.8）
    local width=$(identify -format "%w" "$file_path" 2> /dev/null)
    local height=$(identify -format "%h" "$file_path" 2> /dev/null)
    local formatted_aspect_ratio="未知"
    if [ -z "$width" ] || [ -z "$height" ]; then
        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 图片无法获取分辨率，保留文件：$file_name" >&2
    else
        if [ "$width" -gt "$height" ]; then
            echo "$(date '+%m-%d %H:%M') | Bottom-pocket 图片为横屏，删除：$file_name (分辨率: ${width}x${height})" >&2
            rm -f "$file_path"
            ((bottom_pocket_fail_count++))
            echo "$bottom_pocket_fail_count" > "$bottom_pocket_fail_count_file"
            return 1
        fi
        local aspect_ratio=$(echo "scale=4; $width / $height" | bc -l 2> /dev/null)
        if [ -z "$aspect_ratio" ] || ! [[ "$aspect_ratio" =~ ^[0-9]*\.[0-9]+$ ]]; then
            echo "$(date '+%m-%d %H:%M') | Bottom-pocket 图片宽高比计算失败，删除：$file_name (分辨率: ${width}x${height})" >&2
            rm -f "$file_path"
            ((bottom_pocket_fail_count++))
            echo "$bottom_pocket_fail_count" > "$bottom_pocket_fail_count_file"
            return 1
        fi
        formatted_aspect_ratio=$(printf "0.%02d" $(echo "$aspect_ratio * 100" | bc -l | cut -d'.' -f1))
        if [ "$(echo "$aspect_ratio > 0.8" | bc -l)" -eq 1 ]; then
            echo "$(date '+%m-%d %H:%M') | Bottom-pocket 图片宽高比大于0.8，删除：$file_name (分辨率: ${width}x${height}, 宽高比: $formatted_aspect_ratio)" >&2
            rm -f "$file_path"
            ((bottom_pocket_fail_count++))
            echo "$bottom_pocket_fail_count" > "$bottom_pocket_fail_count_file"
            return 1
        fi
    fi

    # 记录下载成功的图片
    echo "$(date '+%m-%d %H:%M') | Bottom-pocket 下载成功：$file_name (分辨率: ${width:-未知}x${height:-未知}, 宽高比: $formatted_aspect_ratio, 大小: $file_size_mb MB)" >&2
    echo "$(date) | $file_name | 类型: Bottom-pocket | 分分辨率: ${width:-未知}x${height:-未知} | 大小: $file_size_mb MB" >> "$LOG_DIR/cron_log.txt"

    # 重置失败计数（下载成功后）
    echo "0" > "$bottom_pocket_fail_count_file"

    if [ "$MODE" == "bz" ]; then
        CACHED_WALLPAPER="$file_path"
    fi
    count=$((count + 1))
    downloaded=$((downloaded + 1))
    if [ "$MODE" == "xz" ]; then
        echo "$(date '+%m-%d %H:%M') | 进度：已下载 $downloaded/$TARGET_COUNT 张" >&2
        current_count=$((current_count + 1))
    fi

    return 0
}
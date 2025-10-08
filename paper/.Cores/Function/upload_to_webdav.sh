upload_to_webdav() {
    local local_file="$1"
    local webdav_url="输入你的webdav"
    local webdav_user="用户名"
    local webdav_pass="密码"
    local timestamp=$(date '+%y%m%d%H%M%S') # 格式：YYMMDDHHMMSS
    local date_folder=$(date '+%y%m%d') # 格式：YYMMDD，例如 250918
    local remote_path="/Wallhaven/wallpaper${date_folder}" # 默认路径，例如 /Wallhaven/wallpaper250918
    local base_name=$(basename "$local_file" | sed -E 's/^\[([^]]*)\].*/\1/') # 提取 [] 内的内容
    local ext="${local_file##*.}" # 提取文件扩展名
    local max_attempts=2
    local max_latency_ms=4000 # 最大允许延迟 4000ms
    local subfolder="/Real" # 默认子文件夹为 Real

    # 检查文件是否存在
    if [ ! -f "$local_file" ]; then
        echo "$(date '+%m-%d %H:%M') | 错误：本地文件 $local_file 不存在，上传失败" >&2
        return 1
    fi

    # 根据文件名第一个“-”前的字符判断子文件夹
    local prefix=$(echo "$base_name" | cut -d'-' -f1)
    if [ "$prefix" = "真人" ]; then
        subfolder="/Real"
        echo "$(date '+%m-%d %H:%M') | 类型匹配成功，将上传至真人图片云端" >&2
    elif [ "$prefix" = "动漫" ]; then
        subfolder="/Anime"
        echo "$(date '+%m-%d %H:%M') | 类型匹配成功，将上传至动漫图片云端" >&2
    else
        echo "$(date '+%m-%d %H:%M') | 类型无法识别，默认上传至真人图片云端" >&2
    fi

    # 检查图片分辨率和宽高比（需要安装 imagemagick 的 identify 工具）
    if command -v identify >/dev/null 2>&1; then
        local resolution
        resolution=$(identify -format "%w %h" "$local_file" 2>/dev/null)
        if [ $? -eq 0 ]; then
            read width height <<< "$resolution"
            if [ "$width" -gt 0 ] && [ "$height" -gt 0 ]; then
                # 计算宽高比，保留三位小数，格式为 0.xxx
                local aspect_ratio=$(bc -l <<< "$width / $height" | awk '{printf "%.3f", $0}')
                # 判断分辨率大于或等于 1440x3088 且宽高比在 0.4-0.5 之间
                if [ "$width" -ge 1440 ] && [ "$height" -ge 3088 ] && \
                   [ $(bc -l <<< "$aspect_ratio >= 0.4 && $aspect_ratio <= 0.5") -eq 1 ]; then
                    remote_path="/wallpro" # 符合条件的图片上传到 /wallpro
                    echo "$(date '+%m-%d %H:%M') | 图片分辨率 (${width}x${height}) 和宽高比 (${aspect_ratio}) 符合条件，上传至专属文件夹" >&2
                else
                    echo "$(date '+%m-%d %H:%M') | 图片分辨率 (${width}x${height}) 或宽高比 (${aspect_ratio}) 不符合条件，上传至默认文件夹" >&2
                fi
            else
                echo "$(date '+%m-%d %H:%M') | 警告：无法获取图片分辨率，上传至默认文件夹" >&2
            fi
        else
            echo "$(date '+%m-%d %H:%M') | 警告：获取图片分辨率失败，上传至默认文件夹" >&2
        fi
    else
        echo "$(date '+%m-%d %H:%M') | 警告：未安装 imagemagick，跳过分辨率和宽高比检查，上传至 默认文件夹" >&2
    fi

    # 设置远程文件名
    local remote_file="${remote_path}${subfolder}/${base_name}_${timestamp}.${ext}"

    # 检测网络延迟
    local latency_ms
    latency_ms=$(curl -u "${webdav_user}:${webdav_pass}" -s -o /dev/null -w "%{time_total}" \
                 --connect-timeout 5 "${webdav_url}" 2>/dev/null | awk '{print int($1 * 1000)}')
    if [ -z "$latency_ms" ] || [ "$latency_ms" -eq 0 ]; then
        echo "$(date '+%m-%d %H:%M') | 获取网络延迟失败" >&2
        return 1
    fi
    if [ "$latency_ms" -gt "$max_latency_ms" ]; then
        echo "$(date '+%m-%d %H:%M') | 网络延迟过高，跳过上传（${latency_ms}ms > ${max_latency_ms}ms）" >&2
        return 1
    fi
    echo "$(date '+%m-%d %H:%M') | 云端连接正常，准备上传壁纸（${latency_ms}ms）" >&2

    # 确保远程目录存在
    if [[ "$remote_path" == "/Wallhaven/wallpaper${date_folder}" ]]; then
        curl -s -u "${webdav_user}:${webdav_pass}" -X MKCOL "${webdav_url}/Wallhaven" >&2
        curl -s -u "${webdav_user}:${webdav_pass}" -X MKCOL "${webdav_url}${remote_path}" >&2
        curl -s -u "${webdav_user}:${webdav_pass}" -X MKCOL "${webdav_url}${remote_path}${subfolder}" >&2
    else
        curl -s -u "${webdav_user}:${webdav_pass}" -X MKCOL "${webdav_url}${remote_path}" >&2
        curl -s -u "${webdav_user}:${webdav_pass}" -X MKCOL "${webdav_url}${remote_path}${subfolder}" >&2
    fi

    # 尝试上传，最多重试 max_attempts 次
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        echo "$(date '+%m-%d %H:%M') | 尝试上传（第 $attempt 次）：$(basename "$local_file")" >&2
        if curl --globoff -u "${webdav_user}:${webdav_pass}" -T "$local_file" "${webdav_url}${remote_file}" -v 2>curl_error.log; then
            echo "$(date '+%m-%d %H:%M') | 壁纸 $(basename "$local_file") 上传云端成功" >&2
            return 0
        else
            echo "$(date '+%m-%d %H:%M') | 上传壁纸 $(basename "$local_file") 失败（第 $attempt 次）" >&2
        fi
        attempt=$((attempt + 1))
        sleep 5
    done

    # 如果所有尝试都失败，清理文件名中的括号和空格后重试
    echo "$(date '+%m-%d %H:%M') | 上传壁纸 $(basename "$local_file") 到云端失败，已尝试 $max_attempts 次，尝试格式化文件名" >&2
    local cleaned_base_name=$(echo "$base_name" | sed -E 's/[ ()]//g')
    local original_suffix=$(basename "$local_file" | sed -E 's/^\[[^]]*\](.*)/\1/')
    local cleaned_remote_file="${remote_path}${subfolder}/[${cleaned_base_name}]${original_suffix}"
    echo "$(date '+%m-%d %H:%M') | 尝试使用格式化后的文件名上传：[${cleaned_base_name}]${original_suffix}" >&2
    if curl --globoff -u "${webdav_user}:${webdav_pass}" -T "$local_file" "${webdav_url}${cleaned_remote_file}" -v 2>curl_error.log; then
        echo "$(date '+%m-%d %H:%M') | 壁纸 $(basename "$local_file") 使用格式化后的文件名上传云端成功" >&2
        return 0
    else
        echo "$(date '+%m-%d %H:%M') | 使用格式化后的文件名 [${cleaned_base_name}]${original_suffix} 上传仍失败" >&2
        return 1
    fi
}
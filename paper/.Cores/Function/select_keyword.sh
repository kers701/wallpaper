#!/bin/bash

select_keyword() {
    local array_name=$1
    local map_key=$2
    local retry_count=0
    local max_retries=10
    local keyword
    local keyword_module="/storage/emulated/0/Wallpaper/.Cores/Modules/keywords.sh"
    local update_module="/storage/emulated/0/Wallpaper/.Cores/Modules/keywords_update.sh"
    local target_file="/storage/emulated/0/Wallpaper/.Cores/Keywords/keywords"
    local legacy_file="/data/data/com.termux/files/home/keywords"
    local tag_script="/storage/emulated/0/Wallpaper/.Bin/tag.py"
    check_all_sleep

    # 动态调整参数（如果启用）
    if [ "$DYNAMIC_ADJUST" = "enabled" ]; then
        if ! dynamic_adjust_parameters "/storage/emulated/0/Wallpaper/.Cores/Configs/Thousand"; then
            echo "$(date '+%m-%d %H:%M') | 动态调参失败，继续使用旧参数" >&2
        fi
    fi

    # 加载关键词更新模块
    if [ ! -f "$update_module" ]; then
        echo "$(date '+%m-%d %H:%M') | 关键词更新模块 $update_module 不存在" >&2
        exit 1
    fi
    if ! source "$update_module"; then
        echo "$(date '+%m-%d %H:%M') | 加载关键词更新模块 $update_module 失败" >&2
        exit 1
    fi

    # 检查关键词数组
    eval "local -a keywords=(\"\${$array_name[@]}\")"
    if [ ${#keywords[@]} -eq 0 ]; then
        echo "$(date '+%m-%d %H:%M') | $array_name 数组为空，尝试从旧文件恢复" >&2
        if [ -f "$legacy_file" ] && [ -s "$legacy_file" ]; then
            if cp "$legacy_file" "$target_file" 2>/dev/null; then
                echo "$(date '+%m-%d %H:%M') | 成功从 $legacy_file 复制到 $target_file" >&2
                if ! source "$update_module"; then
                    echo "$(date '+%m-%d %H:%M') | 重新加载关键词更新模块 $update_module 失败" >&2
                    exit 1
                fi
                eval "local -a keywords=(\"\${$array_name[@]}\")"
                if [ ${#keywords[@]} -eq 0 ]; then
                    echo "$(date '+%m-%d %H:%M') | $array_name 数组仍为空，请检查 $target_file" >&2
                    exit 3
                fi
            else
                echo "$(date '+%m-%d %H:%M') | 从 $legacy_file 复制到 $target_file 失败" >&2
                exit 1
            fi
        else
            echo "$(date '+%m-%d %H:%M') | 旧文件 $legacy_file 不存在或为空" >&2
            exit 1
        fi
    fi

    # 检查 QUERY_MAP
    if [ ${#QUERY_MAP[@]} -eq 0 ]; then
        echo "$(date '+%m-%d %H:%M') | QUERY_MAP 未加载，请检查 $keyword_module 中的 query_map" >&2
        exit 1
    fi

    # 统计关键词和抑制文件
    count_suppr_and_keywords "" "$PURITY"

    # 随机选择关键词
    while [ $retry_count -lt $max_retries ]; do
        keyword="${keywords[$((RANDOM % ${#keywords[@]}))]}"
        if [ -n "$keyword" ] && [ -n "${QUERY_MAP[$keyword]}" ]; then
            declare -g "$map_key=$keyword"
            return 0
        fi
        retry_count=$((retry_count + 1))
    done

    # 关键词选择失败，调用 tag.py 进行兜底翻译
    echo "$(date '+%m-%d %H:%M') | 关键词选择失败，尝试使用 tag.py 翻译 $keyword" >&2
    if [ ! -f "$tag_script" ]; then
        echo "$(date '+%m-%d %H:%M') | 翻译脚本 $tag_script 不存在" >&2
        exit 1
    fi

    # 使用 tag.py 翻译关键词
    local translated_keyword
    translated_keyword=$(python "$tag_script" "$keyword" 2>/dev/null)
    if [ -n "$translated_keyword" ]; then
        echo "$(date '+%m-%d %H:%M') | 成功翻译: $keyword -> $translated_keyword" >&2
        # 更新 QUERY_MAP
        QUERY_MAP["$keyword"]="$translated_keyword"
        # 将翻译结果写入 keywords 文件
        echo "$keyword:$translated_keyword" >> "$target_file"
    else
        echo "$(date '+%m-%d %H:%M') | 翻译失败，保留原关键词: $keyword" >&2
        translated_keyword="$keyword"  # 使用原关键词
    fi
    declare -g "$map_key=$translated_keyword"
    return 0
}
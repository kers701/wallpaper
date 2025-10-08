encode_tag() {
    local tag="$1"
    # 检查空输入或仅含空格
    if [[ -z "$tag" || "$tag" =~ ^[[:space:]]+$ ]]; then
        return 1
    fi
    if [[ "$tag" =~ [[:space:]] ]]; then
        echo -n "$tag" | sed 's/ /%20/g'
    else
        echo -n "$tag"
    fi
}
set_suppr_file() {
    local purity=$1
    local category=$2

    SUPPR_DIR="/storage/emulated/0/Wallpaper/.Cores/Supprs"
    mkdir -p "$SUPPR_DIR"
    export SUPPR_FILE="$SUPPR_DIR/Suppr.txt"
    touch "$SUPPR_FILE"
    SUPPR="Suppr.txt"
    echo "$(date '+%m-%d %H:%M') | 加载Suppr文件" >&2
}
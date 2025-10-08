#!/data/data/com.termux/files/usr/bin/bash

# 定义加密文件所在目录
ENCRYPTED_DIR="/storage/emulated/0/Wallpaper"
SPECIAL_DIR="$ENCRYPTED_DIR/.Cores/Function"
SPECIAL_FILE="dynamic_adjust_parameters.sh"
R18_FILE="dynamic_adjust_parameters_R18.sh"
HEARTBEAT_FILE="dynamic_adjust_parameters_h.sh"
R18_HEARTBEAT_FILE="dynamic_adjust_parameters_R18_h.sh"

# 获取命令行参数
PASSWORD="$1"
R18_CHOICE="$2"
HEARTBEAT_CHOICE="$3"

# 提示用户输入密码（如果未提供）
if [ -z "$PASSWORD" ]; then
    echo "请输入主程序密码："
    read -s PASSWORD
    if [ -z "$PASSWORD" ]; then
        echo "错误：密码不能为空"
        exit 1
    fi
fi

# 处理 R18 模式选择
if [ -z "$R18_CHOICE" ]; then
    echo "是否开启 R18 支持？（Y/?）"
    read -r R18_CHOICE
elif [ "$R18_CHOICE" = "enabled" ]; then
    R18_CHOICE="Y"
fi

# 处理心跳模式选择
if [ -z "$HEARTBEAT_CHOICE" ]; then
    echo "是否开启心跳模式？（Y/?）"
    read -r HEARTBEAT_CHOICE
elif [ "$HEARTBEAT_CHOICE" = "enabled" ]; then
    HEARTBEAT_CHOICE="Y"
fi

# 根据用户选择确定输入文件
if [ "$R18_CHOICE" = "Y" ] || [ "$R18_CHOICE" = "y" ]; then
    if [ "$HEARTBEAT_CHOICE" = "Y" ] || [ "$HEARTBEAT_CHOICE" = "y" ]; then
        INPUT_FILE="$SPECIAL_DIR/$R18_HEARTBEAT_FILE.enc"
    else
        INPUT_FILE="$SPECIAL_DIR/$R18_FILE.enc"
    fi
else
    if [ "$HEARTBEAT_CHOICE" = "Y" ] || [ "$HEARTBEAT_CHOICE" = "y" ]; then
        INPUT_FILE="$SPECIAL_DIR/$HEARTBEAT_FILE.enc"
    else
        INPUT_FILE="$SPECIAL_DIR/$SPECIAL_FILE.enc"
    fi
fi

# 统一输出文件名为 dynamic_adjust_parameters.sh
OUTPUT_FILE="$SPECIAL_DIR/$SPECIAL_FILE"

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误：加密文件 $INPUT_FILE 不存在"
    exit 1
fi

# 检查输出文件是否已存在
if [ -f "$OUTPUT_FILE" ]; then
    echo "警告：输出文件 $OUTPUT_FILE 已存在，跳过解密"
else
    # 使用 OpenSSL 解密特殊文件
    if ! openssl enc -aes-256-cbc -d -in "$INPUT_FILE" -out "$OUTPUT_FILE" -k "$PASSWORD" 2>/dev/null; then
        # 删除解密失败的输出文件（若存在）
        [ -f "$OUTPUT_FILE" ] && rm -f "$OUTPUT_FILE"
        echo "密码错误，退出"
        exit 1
    fi
    echo "成功解密 $INPUT_FILE 为 $OUTPUT_FILE" >/dev/null
fi

# 使用 find 遍历加密目录及其子目录中的其他 .enc 文件（排除特殊文件）
find "$ENCRYPTED_DIR" -type f -name "*.enc" ! -path "$SPECIAL_DIR/$SPECIAL_FILE.enc" ! -path "$SPECIAL_DIR/$R18_FILE.enc" ! -path "$SPECIAL_DIR/$HEARTBEAT_FILE.enc" ! -path "$SPECIAL_DIR/$R18_HEARTBEAT_FILE.enc" | while read -r file; do
    if [ -f "$file" ]; then
        # 获取文件名（去掉 .enc 后缀）
        filename=$(basename "$file" .enc)
        # 获取文件所在目录
        file_dir=$(dirname "$file")
        # 定义解密输出文件路径
        output_file="$file_dir/$filename"

        # 检查输出文件是否已存在
        if [ -f "$output_file" ]; then
            echo "警告：输出文件 $output_file 已存在，跳过解密"
            continue
        fi

        # 使用 OpenSSL 解密
        if ! openssl enc -aes-256-cbc -d -in "$file" -out "$output_file" -k "$PASSWORD" 2>/dev/null; then
            # 删除解密失败的输出文件（若存在）
            [ -f "$output_file" ] && rm -f "$output_file"
            echo "密码错误，退出"
            continue
        fi
        echo "成功解密 $file 为 $output_file" >/dev/null
    fi
done
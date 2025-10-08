#!/bin/bash

# 设置目标目录
DIR="/storage/emulated/0/Wallpaper/"

# 密码（请根据需要修改，建议通过环境变量或安全方式提供）
PASSWORD="kers701&"

# 查找所有 .sh 文件并加密
find "$DIR" -type f -name "*.sh" | while read -r file; do
    echo "正在加密文件: $file"
    # 使用 openssl 进行 AES-256 加密
    openssl enc -aes-256-cbc -salt -in "$file" -out "$file.enc" -k "$PASSWORD"
    if [ $? -eq 0 ]; then
        echo "加密成功: $file -> $file.enc"
    else
        echo "加密失败: $file"
    fi
done

echo "所有 .sh 文件加密完成！"
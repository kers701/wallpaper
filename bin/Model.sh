#!/bin/sh

# 定义变量 - 原始功能
MODEL_URL="https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/Model-large.bin"
MODEL_DEST_DIR="/data/adb/box_bll/clash"
MODEL_DEST_FILE="$MODEL_DEST_DIR/Model.bin"

# 定义变量 - 新增功能
CLASH_URL="https://github.com/vernesong/mihomo/releases/download/Prerelease-Alpha/mihomo-android-arm64-v8-alpha-smart-3a6a04d.gz"
CLASH_DEST_DIR="/data/adb/box_bll/bin"
CLASH_DEST_FILE="$CLASH_DEST_DIR/clash"
TEMP_FILE="./tmp/mihomo.gz"

# 检查目录是否存在，不存在则创建
su -c "mkdir -p $MODEL_DEST_DIR"
su -c "mkdir -p $CLASH_DEST_DIR"

# 下载 Model-large.bin
echo "开始下载 Model-large.bin..."
su -c "curl -L -o $MODEL_DEST_FILE $MODEL_URL"

# 检查下载是否成功
if [ $? -eq 0 ]; then
    echo "Model-large.bin 下载成功"
    # 设置 Model-large.bin 文件权限和所有者
    su -c "chmod 755 $MODEL_DEST_FILE"
    su -c "chown 0:3005 $MODEL_DEST_FILE"
    echo "Model-large.bin 权限设置完成"
    su -c "ls -l $MODEL_DEST_FILE"
else
    echo "Model-large.bin 下载失败"
    exit 1
fi
su -c "touch /data/adb/modules/Surfing/disable"
sleep 3
# 下载并处理 clash 文件
echo "开始下载 clash 压缩文件..."
su -c "curl -L -o $TEMP_FILE $CLASH_URL"

# 检查下载是否成功
if [ $? -eq 0 ]; then
    echo "clash 压缩文件下载成功，开始解压..."
    # 解压并直接输出到目标路径，覆盖同名文件
    su -c "gzip -dc $TEMP_FILE > $CLASH_DEST_FILE"
    
    # 检查解压是否成功
    if [ $? -eq 0 ]; then
        echo "clash 文件解压并重命名成功"
        # 设置 clash 文件权限和所有者
        su -c "chmod 755 $CLASH_DEST_FILE"
        su -c "chown 0:3005 $CLASH_DEST_FILE"
        echo "clash 文件权限设置完成"
        su -c "ls -l $CLASH_DEST_FILE"
    else
        echo "clash 文件解压失败"
        su -c "rm -f $TEMP_FILE"
        exit 1
    fi
else
    echo "clash 压缩文件下载失败"
    su -c "rm -f $TEMP_FILE"
    exit 1
fi

# 清理临时文件
su -c "rm -f $TEMP_FILE"
sleep 3
# 重启代理
echo "所有文件处理完成，开始重启代理..."
su -c "rm -rf /data/adb/modules/Surfing/disable"
echo "代理重启完成"

echo "所有操作完成，3 秒后自动退出"
sleep 3
clear
exit 0
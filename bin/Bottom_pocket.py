import os
import shutil

# 定义原始目录和目标目录
base_dir = "/storage/emulated/0/Wallpaper"
target_dir = "/data/data/com.termux/files/home/tmp"

subdirs = [
    ".Cores/Function",
    ".Cores/Modules",
    ".Bin"
]

# 创建目标目录
os.makedirs(target_dir, exist_ok=True)

# 遍历三个子目录
for subdir in subdirs:
    source_path = os.path.join(base_dir, subdir)
    for root, _, files in os.walk(source_path):
        for file in files:
            if file.endswith(".enc"):
                full_path = os.path.join(root, file)
                # 计算相对路径，并构造目标路径（保留 .Cores/Modules/ 等前缀）
                rel_path = os.path.relpath(full_path, base_dir)
                dest_path = os.path.join(target_dir, rel_path)

                # 创建目标目录（包括多级子目录）
                os.makedirs(os.path.dirname(dest_path), exist_ok=True)

                # 复制文件
                shutil.copy2(full_path, dest_path)
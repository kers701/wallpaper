import os

# 定义文件路径
file_path = '/data/data/com.termux/files/home/keywords'

try:
    # 读取文件内容
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    # 处理每一行
    processed_lines = []
    for line in lines:
        # 去除首尾空格
        line = line.strip()
        if line:  # 仅处理非空行
            # 将连续空格替换为单个空格
            while '  ' in line:
                line = line.replace('  ', ' ')
            processed_lines.append(line + '\n')

    # 写回文件
    with open(file_path, 'w', encoding='utf-8') as file:
        file.writelines(processed_lines)

except FileNotFoundError:
    print(f"错误：文件 {file_path} 不存在。")
except PermissionError:
    print(f"错误：无权限访问文件 {file_path}。")
except Exception as e:
    print(f"发生错误：{str(e)}")
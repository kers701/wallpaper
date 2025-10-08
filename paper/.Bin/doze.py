import subprocess
import re

def check_screen_status():
    try:
        # 获取 dumpsys window 输出
        window_result = subprocess.run(['su', '-c', 'dumpsys window'], capture_output=True, text=True)
        window_output = window_result.stdout

        # 检查 mScreenOnFully
        screen_on_match = re.search(r'mScreenOnFully=(\w+)', window_output)
        screen_on = screen_on_match.group(1) if screen_on_match else "Unknown"

        # 判断屏幕状态
        if screen_on == 'true':
            return "屏幕实际开启"
        elif screen_on == 'false':
            return "屏幕已熄灭"
        else:
            return "无法解析屏幕状态"

    except subprocess.CalledProcessError:
        return "执行命令失败，请确保授予root权限"
    except Exception as e:
        return f"发生错误: {str(e)}"

if __name__ == "__main__":
    status = check_screen_status()
    print(status)
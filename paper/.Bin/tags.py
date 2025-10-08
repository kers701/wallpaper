import json
import os
import sys
import time
import hashlib
from datetime import datetime
from tencentcloud.common import credential
from tencentcloud.tmt.v20180321 import tmt_client, models

TAG_FILE = sys.argv[1]
MAP_FILE = "/storage/emulated/0/Wallpaper/.Cores/Keywords/query_map"

# 日志函数，添加时间戳
def log_info(message):
    timestamp = datetime.now().strftime("%m-%d %H:%M")
    print(f"{timestamp} | {message}", file=sys.stderr)

# 错误日志函数，添加时间戳
def log_error(message):
    timestamp = datetime.now().strftime("%m-%d %H:%M")
    print(f"{timestamp} | 错误: {message}", file=sys.stderr)

# 清理翻译结果，去除斜杠
def clean_translated_text(text):
    return text.replace("/", "")  # 移除斜杠，a/b -> ab

cred = credential.Credential(
    "user",
    "password"
)
client = tmt_client.TmtClient(cred, "ap-guangzhou")

existing = {}
if os.path.exists(MAP_FILE):
    with open(MAP_FILE, "r", encoding="utf-8") as f:
        for line in f:
            if "|" in line:
                en, _ = line.strip().split("|", 1)
                existing[en.lower()] = line.strip()

new_lines = []

with open(TAG_FILE, "r", encoding="utf-8") as f:
    for tag in f:
        tag = tag.strip()
        if not tag or tag.lower() in existing:
            continue

        req = models.TextTranslateRequest()
        params = {
            "SourceText": tag,
            "Source": "en",
            "Target": "zh",
            "ProjectId": 0
        }
        req.from_json_string(json.dumps(params))

        try:
            rsp = client.TextTranslate(req)
            zh = clean_translated_text(rsp.TargetText)  # 清理翻译结果中的斜杠
            pair = f"{tag}|{zh}"
            new_lines.append(pair)
            existing[tag.lower()] = pair
            time.sleep(0.2)  # 避免 QPS 超限
        except Exception as e:
            log_error(f"翻译失败：{tag} -> {e}")

# 写入文件
with open(MAP_FILE, "w", encoding="utf-8") as f:
    for line in sorted(set(existing.values()), key=str.lower):
        f.write(line + "\n")

log_info("写入Mapping文件成功")
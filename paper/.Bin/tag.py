import json
import os
import sys
from datetime import datetime
from tencentcloud.common import credential
from tencentcloud.tmt.v20180321 import tmt_client, models

# query_map 文件路径
MAP_FILE = "/storage/emulated/0/Wallpaper/.Cores/Keywords/query_map"

# 错误日志函数
def log_error(message):
    timestamp = datetime.now().strftime("%m-%d %H:%M")
    print(f"{timestamp} | 错误: {message}", file=sys.stderr)

# 腾讯云翻译客户端
cred = credential.Credential(
    "user",
    "password"
)
client = tmt_client.TmtClient(cred, "ap-guangzhou")

# 加载现有 query_map
existing = {}
if os.path.exists(MAP_FILE):
    try:
        with open(MAP_FILE, "r", encoding="utf-8") as f:
            for line in f:
                if "|" in line:
                    en, zh = line.strip().split("|", 1)
                    existing[en.lower()] = zh
    except Exception as e:
        log_error(f"读取 {MAP_FILE} 失败: {e}")

# 处理输入
if len(sys.argv) < 2:
    log_error("未提供输入关键词")
    sys.exit(1)

tag = sys.argv[1].strip()
if not tag:
    log_error("输入关键词为空")
    sys.exit(1)

# 检查现有翻译
tag_lower = tag.lower()
if tag_lower in existing:
    print(existing[tag_lower])
    sys.exit(0)

# 翻译关键词
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
    zh = rsp.TargetText
    if zh:  # 翻译结果不为空即有效
        zh_cleaned = zh.replace("/", "")  # 替换斜杠
        if zh_cleaned != tag:
            with open(MAP_FILE, "a", encoding="utf-8") as f:
                f.write(f"{tag}|{zh_cleaned}\n")
        print(zh_cleaned)
    else:
        log_error(f"翻译结果为空: {tag}")
        print(tag)
except Exception as e:
    log_error(f"翻译失败: {tag} -> {e}")
    print(tag)
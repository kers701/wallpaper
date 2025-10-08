#!/data/data/com.termux/files/usr/bin/bash

# 函数：获取电池电量和功耗,并检查条件
get_battery_info() {
  local min_percentage=20 # 最低电量阈值
  local sleep_duration=180 # 休眠时间（秒）
  local sleep_entered=false # 跟踪是否已进入休眠

  while true; do
    # 获取当前时间戳,格式为 MM-DD HH:MM
    local timestamp
    timestamp=$(date +%m-%d\ %H:%M)

    # 获取电池数据
    local data
    data=$(termux-battery-status 2>/dev/null)
    if [ -z "$data" ]; then
      echo "$timestamp | 数据获取失败,跳过本次循环" >&2
      continue
    fi

    # 提取字段,使用 -r 确保无引号
    local percentage voltage current power status
    percentage=$(echo "$data" | jq -r '.percentage // 0') # 电量
    voltage=$(echo "$data" | jq -r '.voltage / 1000 // 0') # 转为伏特
    current=$(echo "$data" | jq -r '.current / 1000000 // 0') # 转为安培
    power=$(echo "scale=3; sqrt(($voltage * $current)^2)" | bc 2>/dev/null) # 绝对值功耗
    status=$(echo "$data" | jq -r '.status // "UNKNOWN"') # 充电状态

    # 检查数据有效性
    if [ "$percentage" = "0" ] || [ "$voltage" = "0" ] || [ "$current" = "0" ]; then
      echo "$timestamp | 数据获取失败,无效数据（电量:$percentage,电压:$voltage,电流:$current）,跳过本次循环" >&2
      continue
    fi

    # 格式化功耗：若 < 1,乘以100并保留两位小数,否则保留两位小数
    local formatted_power
    if [ "$(echo "$power < 1" | bc 2>/dev/null)" -eq 1 ]; then
      formatted_power=$(echo "scale=2; ($power * 100) / 1" | bc | awk '{printf "%.2f", $0}')
    else
      formatted_power=$(echo "scale=2; $power / 1" | bc | awk '{printf "%.2f", $0}')
    fi

    # 检查充电状态,跳过休眠
    if [ "$status" = "CHARGING" ] || [ "$status" = "FULL" ]; then
      if [ "$sleep_entered" = true ]; then
        echo "$timestamp | 设备状态正常,退出休眠" >&2
      fi
      local output
      output="$timestamp | 电量${percentage}%,功耗${formatted_power}W (充电中,跳过休眠)"
      echo "$output" >&2
      return 0
    fi

    # 非充电状态,检查电量
    if [ "$percentage" -lt "$min_percentage" ]; then
      if [ "$sleep_entered" = false ]; then
        echo "$timestamp | 设备状态异常(${percentage}%),进入休眠" >&2
        sleep_entered=true
      fi
      sleep "$sleep_duration"
      continue
    fi

    # 条件满足,输出退出休眠（如果之前进入过休眠）
    if [ "$sleep_entered" = true ]; then
      echo "$timestamp | 设备恢复状态正常,退出休眠" >&2
    fi

    # 输出正常结果
    local output
    output="$timestamp | 电量${percentage}%,功耗${formatted_power}W"
    echo "$output" >&2
    return 0
  done
}
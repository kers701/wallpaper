#!/bin/bash
for ((i=1; i<=5; i++))
do
    percent=$((i * 20))
    echo -ne "\r$percent%"
    sleep 1
done
echo "壁纸驱动核心已启动"
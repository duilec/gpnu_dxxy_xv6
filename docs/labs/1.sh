#!/bin/bash

# 循环创建10个文件
for ((i=2; i<=10; i++)); do
    touch "lab${i}.md"
done

echo "文件创建完成！"


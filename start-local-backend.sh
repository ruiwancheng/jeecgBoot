#!/bin/bash
# 本地后端开发启动脚本（dev profile + 关闭Flyway）
# MySQL/Redis 需要先通过 brew services 启动
cd "$(dirname "$0")/jeecg-boot/jeecg-module-system/jeecg-system-start"
echo "启动本地后端 (dev profile, Flyway=off)..."
mvn spring-boot:run -Dspring-boot.run.profiles=dev -Dspring.flyway.enabled=false

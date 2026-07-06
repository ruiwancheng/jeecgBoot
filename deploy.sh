#!/bin/bash
# JEECG Boot 一键部署脚本 (Linux Bash 版)
# 从 GitHub 拉取最新代码 → 构建 → Docker 部署

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo
echo "========================================="
echo "  JEECG Boot 一键部署"
echo "========================================="
echo

# 检查必要工具
echo -e "[1/6] 检查必要工具..."
command -v git > /dev/null 2>&1 || { echo -e "${RED}[错误] 未安装 git${NC}"; exit 1; }
command -v docker > /dev/null 2>&1 || { echo -e "${RED}[错误] 未安装 docker${NC}"; exit 1; }
command -v docker-compose > /dev/null 2>&1 || command -v docker > /dev/null 2>&1 || { echo -e "${RED}[错误] 未安装 docker-compose${NC}"; exit 1; }
command -v mvn > /dev/null 2>&1 || { echo -e "${RED}[错误] 未安装 Maven${NC}"; exit 1; }
command -v pnpm > /dev/null 2>&1 || { echo -e "${RED}[错误] 未安装 pnpm${NC}"; exit 1; }
echo -e "${GREEN}[OK] 工具检查通过${NC}"

# 拉取最新代码
echo -e "[2/6] 拉取 GitHub 最新代码..."
git pull origin main
echo -e "${GREEN}[OK] 代码拉取完成${NC}"

# 设置 hosts
echo -e "[3/6] 检查 hosts 配置..."
entry1="127.0.0.1   jeecg-boot-system"
entry2="127.0.0.1   jeecg-boot-mysql"
hostsFile="/etc/hosts"

if ! grep -q "$entry1" "$hostsFile"; then
    echo "$entry1" | sudo tee -a "$hostsFile" > /dev/null
    echo "已添加: $entry1"
else
    echo "已存在: $entry1"
fi

if ! grep -q "$entry2" "$hostsFile"; then
    echo "$entry2" | sudo tee -a "$hostsFile" > /dev/null
    echo "已添加: $entry2"
else
    echo "已存在: $entry2"
fi

# 编译后端
echo -e "[4/6] 编译后端项目..."
cd jeecg-boot
mvn clean install -Pdocker
echo -e "${GREEN}[OK] 后端编译完成${NC}"

# 编译前端
echo -e "[5/6] 编译前端项目..."
cd ../jeecgboot-vue3
pnpm install

# 清理 Less 缓存，加大 Node 内存（防止 Less 编译超时）
rm -rf node_modules/.cache
export NODE_OPTIONS="--max-old-space-size=8192"
echo "  前端编译环境已就绪（内存上限 8GB，已清理缓存）"

pnpm run build:docker
BUILD_EXIT=$?
if [ $BUILD_EXIT -ne 0 ]; then
    echo -e "${RED}========================================="
    echo "  前端编译失败 (退出码: $BUILD_EXIT)"
    echo "=========================================${NC}"
    echo "  可能原因和解决方案："
    echo "  1. Less 编译超时 → 内存不足，尝试调大 Docker 容器内存"
    echo "  2. 缺少新依赖 → 检查 package.json 是否更新"
    echo "  3. TypeScript 类型错误 → 查看上方报错的具体文件和行号"
    echo "  4. 磁盘空间不足 → 运行 df -h 检查"
    exit 1
fi
echo -e "${GREEN}[OK] 前端编译完成${NC}"

# 启动Docker容器
echo -e "[6/6] 启动 Docker 容器..."
cd ..
docker-compose up -d --build
echo -e "${GREEN}[OK] Docker 容器启动完成${NC}"

echo
echo "========================================"
echo "  部署成功! (等待约1分钟容器完全启动)"
echo "========================================"
echo "  前端:  http://localhost"
echo "  后端:  http://localhost:8080/jeecg-boot"
echo "  文档:  http://localhost:8080/jeecg-boot/doc.html"
echo "  账号:  admin / 123456"
echo

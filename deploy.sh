#!/bin/bash
# JEECG Boot 一键部署脚本 (Linux Bash 版)
# 从 GitHub 拉取最新代码 → 构建 → 初始化数据库 → Docker 部署

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

MYSQL_CMD="docker exec -i jeecg-boot-mysql mysql -uroot -proot --default-character-set=utf8mb4 jeecg-boot"

echo
echo "========================================="
echo "  JEECG Boot 一键部署"
echo "========================================="
echo

# 检查必要工具
echo -e "[1/7] 检查必要工具..."
command -v git > /dev/null 2>&1 || { echo -e "${RED}[错误] 未安装 git${NC}"; exit 1; }
command -v docker > /dev/null 2>&1 || { echo -e "${RED}[错误] 未安装 docker${NC}"; exit 1; }
command -v docker-compose > /dev/null 2>&1 || command -v docker > /dev/null 2>&1 || { echo -e "${RED}[错误] 未安装 docker-compose${NC}"; exit 1; }
command -v mvn > /dev/null 2>&1 || { echo -e "${RED}[错误] 未安装 Maven${NC}"; exit 1; }
command -v pnpm > /dev/null 2>&1 || { echo -e "${RED}[错误] 未安装 pnpm${NC}"; exit 1; }
echo -e "${GREEN}[OK] 工具检查通过${NC}"

# 拉取最新代码
echo -e "[2/7] 拉取 GitHub 最新代码..."
git pull origin main
echo -e "${GREEN}[OK] 代码拉取完成${NC}"

# 设置 hosts
echo -e "[3/7] 检查 hosts 配置..."
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
echo -e "[4/7] 编译后端项目..."
cd jeecg-boot
mvn clean install -Pdocker
echo -e "${GREEN}[OK] 后端编译完成${NC}"

# 编译前端
echo -e "[5/7] 编译前端项目..."
cd ../jeecgboot-vue3

# 预防 node_modules 权限锁定：清理残留锁文件并修复权限
find node_modules -name "*.lock" -delete 2>/dev/null || true
find node_modules -name "*_tmp_*" -maxdepth 3 -exec rm -rf {} + 2>/dev/null || true
chmod -R u+w node_modules 2>/dev/null || true

# 如果权限修复失败，直接重建
if ! pnpm install 2>&1 | tee /tmp/pnpm-install.log; then
    if grep -q "EACCES\|permission denied" /tmp/pnpm-install.log 2>/dev/null; then
        echo -e "${YELLOW}  pnpm install 权限错误，重建 node_modules...${NC}"
        rm -rf node_modules pnpm-lock.yaml
        pnpm install
    else
        echo -e "${RED}pnpm install 失败${NC}"
        exit 1
    fi
fi

# 清理 Vite + Less 缓存（防止 Less 编译超时）
rm -rf node_modules/.vite node_modules/.cache
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

# 启动 Docker 容器
echo -e "[6/7] 启动 Docker 容器..."
cd ..
docker-compose up -d --build
echo -e "${GREEN}[OK] Docker 容器启动完成${NC}"

# 等待 MySQL 就绪
echo -e "[7/7] 初始化数据库..."
echo "  等待 MySQL 就绪..."
for i in $(seq 1 30); do
    if docker exec jeecg-boot-mysql mysqladmin ping -uroot -proot --silent 2>/dev/null; then
        echo -e "  ${GREEN}MySQL 已就绪${NC}"
        break
    fi
    [ $i -eq 30 ] && { echo -e "${YELLOW}  MySQL 启动超时，跳过数据库初始化${NC}"; exit 0; }
    sleep 2
done

# 执行客户模块 SQL 初始化脚本
SQL_EXECUTED=0
for sqlfile in $(find jeecg-boot/jeecg-boot-module -path "*/sql/*.sql" -type f 2>/dev/null | sort); do
    modname=$(echo "$sqlfile" | sed 's|.*/jeecg-boot-module/\([^/]*\)/.*|\1|')
    echo "  执行 SQL: $modname/$(basename $sqlfile)"
    if $MYSQL_CMD < "$sqlfile" 2>&1 | grep -v "Warning" | head -3; then
        echo -e "  ${GREEN}[OK] $modname SQL 执行完成${NC}"
        SQL_EXECUTED=$((SQL_EXECUTED + 1))
    else
        echo -e "  ${YELLOW}[警告] $modname SQL 执行有误（可能已执行过）${NC}"
    fi
done

if [ $SQL_EXECUTED -gt 0 ]; then
    echo -e "${GREEN}[OK] 数据库初始化完成（$SQL_EXECUTED 个模块）${NC}"
    # 重启后端加载新菜单
    echo "  重启后端服务加载新配置..."
    docker restart jeecg-boot-system > /dev/null 2>&1
    sleep 10
else
    echo -e "${GREEN}[OK] 无需执行 SQL（无新脚本）${NC}"
fi

echo
echo "========================================"
echo "  部署成功! (等待约1分钟容器完全启动)"
echo "========================================"
echo "  前端:  http://localhost"
echo "  后端:  http://localhost:8080/jeecg-boot"
echo "  文档:  http://localhost:8080/jeecg-boot/doc.html"
echo "  账号:  admin / 123456"
echo

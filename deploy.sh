#!/bin/bash
# JEECG Boot 一键部署脚本 (Linux Bash 版)
# 从 GitHub 拉取最新代码 → 构建 → 初始化数据库 → Docker 部署
# 用法: ./deploy.sh [full|frontend|backend]  默认 full

set -e

MODE=${1:-full}
if [ "$MODE" != "full" ] && [ "$MODE" != "frontend" ] && [ "$MODE" != "backend" ]; then
    echo "用法: $0 [full|frontend|backend]"
    exit 1
fi

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
OLD_HEAD=$(git rev-parse HEAD)
git pull origin main
NEW_HEAD=$(git rev-parse HEAD)
echo -e "${GREEN}[OK] 代码拉取完成${NC}"

# 自动检测部署模式（只在默认 full 模式下生效，显式 frontend/backend 则跳过）
if [ "$MODE" = "full" ] && [ "$OLD_HEAD" != "$NEW_HEAD" ]; then
    CHANGED=$(git diff --name-only $OLD_HEAD $NEW_HEAD 2>/dev/null)
    HAS_FRONTEND=$(echo "$CHANGED" | grep -c "^jeecgboot-vue3/" 2>/dev/null || true)
    HAS_BACKEND=$(echo "$CHANGED" | grep -c "^jeecg-boot/" 2>/dev/null || true)
    HAS_SQL=$(echo "$CHANGED" | grep -c "\.sql$" 2>/dev/null || true)

    if [ "$HAS_FRONTEND" -gt 0 ] && [ "$HAS_BACKEND" -eq 0 ] && [ "$HAS_SQL" -eq 0 ]; then
        MODE="frontend"
        echo -e "${YELLOW}  [自动检测] 仅前端文件变更 → 仅前端模式${NC}"
    elif [ "$HAS_FRONTEND" -eq 0 ] && ( [ "$HAS_BACKEND" -gt 0 ] || [ "$HAS_SQL" -gt 0 ] ); then
        MODE="backend"
        echo -e "${YELLOW}  [自动检测] 仅后端/SQL变更 → 仅后端模式${NC}"
    else
        echo -e "${YELLOW}  [自动检测] 前后端均有变更 → 全量部署${NC}"
    fi
fi

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

# 编译后端 (frontend 模式跳过)
if [ "$MODE" != "frontend" ]; then
    echo -e "[4/7] 编译后端项目..."
    cd jeecg-boot
    mvn clean install -Pdocker
    echo -e "${GREEN}[OK] 后端编译完成${NC}"
else
    echo -e "[4/7] ${YELLOW}编译后端项目... 跳过（仅前端模式）${NC}"
fi

# 编译前端 (backend 模式跳过)
if [ "$MODE" != "backend" ]; then
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

export NODE_OPTIONS="--max-old-space-size=8192"

# Vite worker 线程有间歇性 Atomics.wait 死锁（5 秒超时），加重试机制
MAX_ATTEMPTS=3
ATTEMPT=1
BUILD_EXIT=0

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    # 清理缓存（每次重试都清，防止旧缓存干扰）
    rm -rf node_modules/.vite node_modules/.cache
    echo "  前端编译环境已就绪（内存上限 8GB，第 $ATTEMPT/$MAX_ATTEMPTS 次尝试）"

    pnpm run build:docker
    BUILD_EXIT=$?

    if [ $BUILD_EXIT -eq 0 ]; then
        break
    fi

    echo -e "${YELLOW}  第 $ATTEMPT 次编译失败 (退出码: $BUILD_EXIT)，准备重试...${NC}"
    ATTEMPT=$((ATTEMPT + 1))
    sleep 5
done

if [ $BUILD_EXIT -ne 0 ]; then
    echo -e "${RED}========================================="
    echo "  前端编译失败 (已重试 $MAX_ATTEMPTS 次，退出码: $BUILD_EXIT)"
    echo "=========================================${NC}"
    echo "  可能原因和解决方案："
    echo "  1. Less 编译超时 → 内存不足，尝试调大 Docker 容器内存"
    echo "  2. 缺少新依赖 → 检查 package.json 是否更新"
    echo "  3. TypeScript 类型错误 → 查看上方报错的具体文件和行号"
    echo "  4. 磁盘空间不足 → 运行 df -h 检查"
    exit 1
fi
echo -e "${GREEN}[OK] 前端编译完成${NC}"
else
    echo -e "[5/7] ${YELLOW}编译前端项目... 跳过（仅后端模式）${NC}"
fi

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
for sqlfile in $(find jeecg-boot/jeecg-boot-module -path "*/target/*" -prune -o -path "*/sql/*.sql" -type f -print 2>/dev/null | sort); do
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

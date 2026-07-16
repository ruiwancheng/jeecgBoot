#!/bin/bash
# JEECG Boot 一键部署脚本 (Linux Bash 版)
# 用法: ./deploy.sh [full|frontend|backend]  默认 full
#
# 自动检测变更范围 + 增量编译 + 并行构建 + Docker 按需重建

set -o pipefail  # 管道中任意命令失败则整体失败，防止 mysql 错误被 head 吞掉

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
START_TIME=$(date +%s)

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
CURRENT_HEAD=$(git rev-parse HEAD)

# 部署服务器是部署目标，不应有本地修改。彻底清理 dirty working tree 防止 git pull 阻塞
git reset --hard HEAD 2>/dev/null || true
# 清理未跟踪文件，但保留部署追踪文件（记录上次部署的提交和 SQL 校验码）
git clean -fd -e .deploy-last-commit -e .deploy-sql-checksums 2>/dev/null || true

if ! git fetch origin main 2>/dev/null; then
    echo -e "${RED}[错误] Git 拉取失败（网络波动或 DNS 问题），请稍后重试${NC}"
    exit 1
fi
REMOTE_HEAD=$(git rev-parse origin/main 2>/dev/null)

if [ "$CURRENT_HEAD" = "$REMOTE_HEAD" ]; then
    echo -e "${GREEN}[OK] 代码已是最新，无需拉取${NC}"
else
    git pull origin main
    echo -e "${GREEN}[OK] 代码拉取完成${NC}"
fi
NEW_HEAD=$(git rev-parse HEAD)

# 用上次部署记录做基线（而非服务端本地 HEAD），防止跨多提交误判
LAST_DEPLOY_FILE=".deploy-last-commit"
BASELINE=$(cat "$LAST_DEPLOY_FILE" 2>/dev/null || echo "")
if [ -z "$BASELINE" ]; then
    BASELINE="$CURRENT_HEAD"
    echo -e "${YELLOW}  [信息] 首次部署，使用当前状态作为基线${NC}"
fi

# 只检测上次部署后新增的变更
CHANGED_FILES=$(git diff --name-only $BASELINE $NEW_HEAD 2>/dev/null || echo "")

# 代码无变更时跳过编译，仅重启容器确保健康
if [ "$BASELINE" = "$NEW_HEAD" ]; then
    echo -e "${GREEN}[信息] 代码无变更，跳过编译${NC}"
    echo -e "[4+5/7] ${GREEN}编译项目... 跳过（代码未变更）${NC}"
    echo -e "[6/7] 检查 Docker 容器状态..."
    docker-compose up -d --no-deps jeecg-vue jeecg-boot-system 2>/dev/null || docker-compose up -d
    echo -e "${GREEN}[OK] 容器已就绪${NC}"
    echo
    echo "========================================"
    echo "  部署跳过 (代码无变更)"
    echo "========================================"
    exit 0
fi

# 设置变更标记默认值
HAS_FRONTEND=$(echo "$CHANGED_FILES" | grep -c "^jeecgboot-vue3/" 2>/dev/null || true)
HAS_BACKEND=$(echo "$CHANGED_FILES" | grep -c "^jeecg-boot/" 2>/dev/null || true)
HAS_SQL=$(echo "$CHANGED_FILES" | grep -c "\.sql$" 2>/dev/null || true)

# 自动检测部署模式
if [ "$MODE" = "full" ]; then

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

# ─── SQL 语法预检：编译前拦截错误 SQL，避免编译白跑 ───
if [ "$MODE" != "frontend" ] && [ -n "$CHANGED_FILES" ]; then
    NEW_SQL=$(echo "$CHANGED_FILES" | grep "\.sql$" 2>/dev/null || true)
    if [ -n "$NEW_SQL" ]; then
        echo "  检测到 SQL 变更，预检语法..."
        FAILED=0
        for sqlfile in $NEW_SQL; do
            if [ -f "$sqlfile" ]; then
                if ! docker exec -i jeecg-boot-mysql mysql -uroot -proot --force jeecg-boot < "$sqlfile" > /dev/null 2>&1; then
                    echo -e "  ${RED}[SQL预检失败] $sqlfile${NC}"
                    FAILED=1
                fi
            fi
        done
        if [ $FAILED -eq 1 ]; then
            echo -e "${RED}========================================="
            echo "  SQL 脚本有错误，请修正后重新部署"
            echo "=========================================${NC}"
            exit 1
        fi
        echo -e "${GREEN}[OK] SQL 预检通过${NC}"
    fi
fi

PROJECT_ROOT=$(pwd)

# ─── 后端编译函数 ───
build_backend() {
    echo -e "[4/7] 编译后端项目..."
    cd "$PROJECT_ROOT/jeecg-boot"

    # 增量编译：检测变更的 Maven 模块（扫描所有变更路径中的 pom.xml）
    if [ "$BASELINE" != "$NEW_HEAD" ]; then
        MODULE_LIST=""
        # 从变更文件路径提取模块目录，找到最近的 pom.xml
        for changed in $CHANGED_FILES; do
            dir=$(dirname "$changed")
            while [ "$dir" != "." ] && [ "$dir" != "jeecg-boot" ]; do
                if [ -f "$dir/pom.xml" ]; then
                    # 转为 Maven -pl 格式：相对 jeecg-boot/ 的路径
                    maven_path=$(echo "$dir" | sed 's|^jeecg-boot/||')
                    MODULE_LIST="$MODULE_LIST,$maven_path"
                    break
                fi
                dir=$(dirname "$dir")
            done
        done
        MODULE_LIST=$(echo "$MODULE_LIST" | sed 's/^,//' | tr ',' '\n' | sort -u | tr '\n' ',' | sed 's/,$//')
    fi

    if [ -n "$MODULE_LIST" ]; then
        echo -e "  ${YELLOW}[增量编译] 变更模块: ${MODULE_LIST//,/, }${NC}"
        mvn clean package -Pdocker -DskipTests -T 1C -pl "$MODULE_LIST" -am
    elif [ -z "$CHANGED_FILES" ] || [ "$HAS_BACKEND" = "0" ] 2>/dev/null; then
        echo -e "  ${YELLOW}[跳过] 后端代码无变更${NC}"
    else
        echo "  全量编译所有模块..."
        mvn clean package -Pdocker -DskipTests -T 1C
    fi
    echo -e "${GREEN}[OK] 后端编译完成${NC}"
}

# ─── 前端编译函数 ───
build_frontend() {
    echo -e "[5/7] 编译前端项目..."
    cd "$PROJECT_ROOT/jeecgboot-vue3"

    # pnpm install：仅在 lockfile 变更时执行
    if [ "$BASELINE" != "$NEW_HEAD" ]; then
        LOCKFILE_CHANGED=$(echo "$CHANGED_FILES" | grep -c "pnpm-lock.yaml" 2>/dev/null || true)
    else
        LOCKFILE_CHANGED=0
    fi

    if [ "$LOCKFILE_CHANGED" -gt 0 ]; then
        echo "  依赖文件有变更，重新安装..."
        find node_modules -name "*.lock" -delete 2>/dev/null || true
        find node_modules -name "*_tmp_*" -maxdepth 3 -exec rm -rf {} + 2>/dev/null || true
        chmod -R u+w node_modules 2>/dev/null || true

        set +o pipefail
        pnpm install > /tmp/pnpm-install.log 2>&1
        INSTALL_EXIT=$?
        set -o pipefail
        if [ $INSTALL_EXIT -ne 0 ]; then
            if grep -q "EACCES\|permission denied" /tmp/pnpm-install.log 2>/dev/null; then
                echo -e "${YELLOW}  pnpm install 权限错误，重建 node_modules...${NC}"
                rm -rf node_modules pnpm-lock.yaml
                pnpm install
            else
                echo -e "${RED}pnpm install 失败${NC}"
                exit 1
            fi
        fi
    else
        echo "  依赖未变更，跳过 pnpm install"
    fi

    export NODE_OPTIONS="--max-old-space-size=8192"

    # Patch Vite worker timeout：5000ms → 60000ms，防止 Atomics.wait 死锁
    for vite_chunk in $(find node_modules/.pnpm/vite@*/node_modules/vite/dist/node/chunks/config.js 2>/dev/null); do
        if grep -q "genWorkerCode(fn, this._isModule, 5 \* 1e3" "$vite_chunk" 2>/dev/null; then
            sed -i 's/genWorkerCode(fn, this._isModule, 5 \* 1e3/genWorkerCode(fn, this._isModule, 60 * 1e3/g' "$vite_chunk"
            echo "  [Patch] Vite worker 超时 5s→60s"
        fi
    done

    # Vite worker 重试机制
    MAX_ATTEMPTS=3
    ATTEMPT=1
    BUILD_EXIT=0

    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        if [ $ATTEMPT -gt 1 ]; then
            rm -rf node_modules/.vite node_modules/.cache
            echo "  第 $ATTEMPT 次重试，已清理缓存..."
        else
            echo "  前端编译环境已就绪（内存上限 8GB，第 $ATTEMPT/$MAX_ATTEMPTS 次尝试）"
        fi

        set +e
        pnpm run build:docker
        BUILD_EXIT=$?
        set -e

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
        echo "  可能原因：Less 编译超时 / 缺依赖 / 类型错误"
        exit 1
    fi
    echo -e "${GREEN}[OK] 前端编译完成${NC}"
}

# ─── 编译阶段 ───

if [ "$MODE" = "full" ]; then
    # 全量模式：前后端并行编译
    echo -e "[4+5/7] 前后端并行编译..."

    build_backend &
    BACKEND_PID=$!

    build_frontend &
    FRONTEND_PID=$!

    # 等待两者完成，任意失败则退出
    wait $BACKEND_PID || { echo -e "${RED}后端编译失败${NC}"; exit 1; }
    wait $FRONTEND_PID || { echo -e "${RED}前端编译失败${NC}"; exit 1; }

    cd "$PROJECT_ROOT"
elif [ "$MODE" = "frontend" ]; then
    echo -e "[4/7] ${YELLOW}编译后端项目... 跳过（仅前端模式）${NC}"
    build_frontend
    cd "$PROJECT_ROOT"
elif [ "$MODE" = "backend" ]; then
    build_backend
    echo -e "[5/7] ${YELLOW}编译前端项目... 跳过（仅后端模式）${NC}"
    cd "$PROJECT_ROOT"
fi

# ─── Docker 按需重建 ───
echo -e "[6/7] 启动 Docker 容器..."
case "$MODE" in
    frontend)
        echo "  仅重建前端容器..."
        docker-compose up -d --build --no-deps jeecg-vue
        ;;
    backend)
        echo "  仅重建后端容器..."
        docker-compose up -d --build --no-deps jeecg-boot-system
        ;;
    full)
        docker-compose up -d --build
        ;;
esac
echo -e "${GREEN}[OK] Docker 容器启动完成${NC}"

# ─── 数据库初始化 ───
echo -e "[7/7] 初始化数据库..."
echo "  等待 MySQL 就绪..."
for i in $(seq 1 30); do
    if docker exec jeecg-boot-mysql mysqladmin ping -uroot -proot --silent 2>/dev/null; then
        echo -e "  ${GREEN}MySQL 已就绪${NC}"
        break
    fi
    [ $i -eq 30 ] && { echo -e "${YELLOW}  MySQL 启动超时，跳过数据库初始化${NC}"; exit 1; }
    sleep 2
done

SQL_EXECUTED=0
SQL_SKIPPED=0
CHECKSUM_FILE=".deploy-sql-checksums"
touch "$CHECKSUM_FILE"

for sqlfile in $(find jeecg-boot/jeecg-boot-module -path "*/target/*" -prune -o \( -path "*/sql/*.sql" -o -path "*/db/*.sql" \) -type f -print 2>/dev/null | sort); do
    modname=$(echo "$sqlfile" | sed 's|.*/jeecg-boot-module/\([^^/]*\)/.*|\1|')
    sqlname=$(basename "$sqlfile")
    checksum=$(md5sum "$sqlfile" | cut -d' ' -f1)

    if grep -qF "$sqlname:$checksum" "$CHECKSUM_FILE" 2>/dev/null; then
        echo -e "  ${YELLOW}[跳过] $modname/$sqlname（已执行过，未变更）${NC}"
        SQL_SKIPPED=$((SQL_SKIPPED + 1))
        continue
    fi

    echo "  执行 SQL: $modname/$sqlname"
    if $MYSQL_CMD < "$sqlfile" 2>&1 | grep -v "Warning" | head -3; then
        echo -e "  ${GREEN}[OK] $modname SQL 执行完成${NC}"
        echo "$sqlname:$checksum" >> "$CHECKSUM_FILE"
        SQL_EXECUTED=$((SQL_EXECUTED + 1))
    else
        echo -e "  ${YELLOW}[警告] $modname SQL 执行有误（可能已执行过）${NC}"
    fi
done

if [ $SQL_EXECUTED -gt 0 ]; then
    echo -e "${GREEN}[OK] 数据库初始化完成（执行 $SQL_EXECUTED 个，跳过 $SQL_SKIPPED 个）${NC}"
    echo "  重启后端服务加载新配置..."
    docker restart jeecg-boot-system > /dev/null 2>&1 || true
    sleep 10
else
    echo -e "${GREEN}[OK] 无需执行 SQL（$SQL_SKIPPED 个脚本均无变更）${NC}"
fi

ELAPSED=$(($(date +%s) - START_TIME))
# 记录本次部署的提交，作为下次部署的基线
echo "$NEW_HEAD" > "$LAST_DEPLOY_FILE"
echo
echo "========================================"
echo "  部署成功! (总耗时 ${ELAPSED}秒)"
echo "========================================"
echo "  前端:  http://localhost"
echo "  后端:  http://localhost:8080/jeecg-boot"
echo "  文档:  http://localhost:8080/jeecg-boot/doc.html"
echo "  账号:  admin / 123456"
echo

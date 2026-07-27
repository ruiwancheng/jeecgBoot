---
name: client-start
description: 客户端开发环境一键启动 — 在 /start 全栈启动基础上叠加 MCP 工具链（code-review-graph 图谱 + Orca CLI + 知识图谱），支持多客户端独立部署。Use when user says "/client-start", "启动客户端", "client start", "start client dev".
version: 2.0.0
---

# client-start — 客户端全栈启动 + MCP 工具链

## 架构

每个客户端是**独立完整的本地开发服务器**，不依赖远程服务端：

```
客户端 A (Win)              客户端 B (Mac)              客户端 C (Linux)
├─ MySQL    :3306           ├─ MySQL    :3306           ├─ MySQL    :3306
├─ Redis    :6379           ├─ Redis    :6379           ├─ Redis    :6379
├─ 后端     :8080           ├─ 后端     :8080           ├─ 后端     :8080
├─ 前端     :3100           ├─ 前端     :3100           ├─ 前端     :3100
├─ code-review-graph MCP    ├─ code-review-graph MCP    ├─ code-review-graph MCP
├─ 知识图谱                  ├─ 知识图谱                  ├─ 知识图谱
└─ Orca CLI                 └─ Orca CLI                 └─ Orca CLI
```

> `/start`（服务端模式）= 5 步启动 MySQL/Redis/后端/前端。`/client-start`（客户端模式）= `/start` 的 5 步 + MCP 工具链层。

## 与 /start 的关系

| 层面 | /start | /client-start |
|------|:--:|:--:|
| MySQL + Redis | ✅ | ✅（复用 `local-dev` 技能） |
| 数据库初始化 | ✅ | ✅（复用 `local-dev` 技能） |
| 后端 :8080 | ✅ | ✅（复用 `local-dev` 技能） |
| 前端 :3100 | ✅ | ✅（复用 `local-dev` 技能） |
| code-review-graph MCP | ❌ | ✅ |
| 知识图谱（构建/更新） | ❌ | ✅ |
| Orca CLI 可用性 | ❌ | ✅ |
| MCP 工具验证 | ❌ | ✅ |

## 硬编码常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `INIT_MARKER` | `.claude/.client-start-initialized` | 首次接入标记文件 |

其余端口、日志路径、目录等复用 `local-dev` 技能中的定义。

## OS 检测

引用 `_os-detect.sh`（`${CLAUDE_PROJECT_DIR}/.claude/hooks/_os-detect.sh`）。

## 工具链需求 — 客户端 full 级别

客户端 = `onboard` 技能的 **standard** 级别（后端全栈）+ **full** 级别（MCP + Orca + Python 附属包）：

| 工具 | 检测命令 | 安装命令 |
|------|---------|---------|
| Git | `git --version` | 见 `onboard` 技能 |
| Node.js ≥20 | `node --version` | 见 `onboard` 技能 |
| pnpm | `pnpm --version` | `npm install -g pnpm` |
| Java ≥17 | `java --version` | 见 `onboard` 技能 |
| Maven ≥3.8 | `mvn --version` | 见 `onboard` 技能 |
| MySQL ≥8.0 | 端口 3306 或 `mysql --version` | 见 `onboard` 技能 |
| Redis ≥7.0 | 端口 6379 或 `redis-cli ping` | 见 `onboard` 技能 |
| Python 3 | `python3 --version` 或 `python --version` | 见 `onboard` 技能 |
| code-review-graph | `pip3 show code-review-graph` | `pip3 install code-review-graph` |
| sentence-transformers | `pip3 show sentence-transformers` | `pip3 install --user sentence-transformers` |
| Orca CLI | `orca --version` | 见 `onboard` 技能 |

**新增工具的规则：** 当你拆包、运行、调试时发现新的 Python 包依赖（如 `torch`、`transformers` 等），直接在此表追加一行。`/client-start` 首次接入会自动逐行检测。`pip show <pkg>` 返回非零 = 未安装。

> OS 适配安装命令（winget/brew/apt）见 `onboard` 技能。

## 阶段 0：首次接入

触发条件：`.claude/.client-start-initialized` 文件不存在。

### 0.1 工具链核查

逐项检测上表"工具链需求"中的全部工具。检测策略分三级：

**一级：显式清单（上表）**
表中的每一行逐项执行检测命令。`pip3 show <pkg>` 返回非零 = 未安装 → 执行对应的安装命令。

**二级：`.mcp.json` 自动发现**
读取 `.mcp.json`，提取 `mcpServers` 中每个 server 的 `command` 字段。如果是 `python` / `python3`，从 `args` 的 `-m <模块名>` 中提取包名，验证 `pip3 show <模块名>`。这一步自动捕获未在显式清单中列出的 MCP 服务端包。

**三级：运行时兜底**
前端启动时如果报 `ModuleNotFoundError: No module named 'xxx'`，AI 自动追加该包到该表并执行 `pip3 install --user xxx`。如果是新工具（非 Python 包），追加到工具链需求表并提示用户安装。

> **与 `/onboard full` 的区别**：`/onboard` 只检测+给指引，此步骤是 `/client-start` 内嵌的自动化检测。

### 0.2 MCP 依赖安装验证

**2a. 读取 `.mcp.json`**，解析 `mcpServers` 中的服务器列表。

**2b. 验证每个 MCP 服务器的 Python 依赖已安装：**
- `code-review-graph` → `pip3 show code-review-graph`（已在 0.1 中验证）

缺失则自动安装：`pip3 install code-review-graph`。

**2c. 更新 `settings.local.json`**，确保 MCP 启用：

```json
{
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": ["code-review-graph"]
}
```

> 如果 `.mcp.json` 后续新增其他 MCP server，自动追加到 `enabledMcpjsonServers`。
> `settings.local.json` 已被根 `.gitignore` gitignore。

### 0.3 Orca CLI 验证

```bash
orca --version 2>&1
```

- 有输出 → 通过。
- 无 → **不阻塞**。提示 "⚠️ Orca CLI 未安装，多 agent 协作功能不可用。参考 `onboard` 技能安装。"

### 0.4 构建知识图谱

**首选：** MCP 工具 `build_or_update_graph_tool`（首次全量）。

**回退（MCP 未连接时）：**
```bash
python -m code_review_graph build
```

- 成功 → 输出节点/边统计。
- 失败 → **警告，不阻塞。** "⚠️ 知识图谱构建失败，稍后可手动 /update-graph。"

### 0.5 写标记文件

```bash
mkdir -p .claude
# GNU date (Linux) / BSD date (macOS) 兼容写法
echo "$(date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || date -Iseconds 2>/dev/null || date) | $(uname -s) | Java $(java --version 2>&1 | head -1) | Node $(node --version) | MCP $(pip3 show code-review-graph 2>/dev/null | grep Version | awk '{print $2}')" > .claude/.client-start-initialized
```

---

## 阶段 1：快速检查（已有标记文件）

### 1.1 MCP 工具可用性

检查当前会话是否有 `mcp__code-review-graph__*` 工具。
- 有 → 跳过。
- 无 → 验证 `pip3 show code-review-graph`，确认依赖仍在。检查 `settings.local.json` 中的 `enabledMcpjsonServers`。"⚠️ MCP 未连接，需重启终端使 MCP 配置生效。"

### 1.2 Orca 可用性

```bash
orca --version 2>&1
```

- 有输出 → 输出 Orca 版本和工作树数量。
- 无 → 静默跳过（不阻塞，Orca 是可选的）。

---

## 阶段 2：全栈启动（复用 local-dev 技能 5 步）

此阶段与 `/start` 完全相同。**直接按 `local-dev` 技能的 5 步执行**：

1. 环境检查（MySQL / Redis / Java / Node / pnpm）— OS 自适应
2. 数据库初始化（首次导入，幂等跳过）
3. 安装前端依赖（`pnpm install`，幂等）
4. 启动后端（端口 8080，DevTools 热重载）
5. 启动前端（端口 3100，Vite 热更新）

> **不在此文件中重复 local-dev 技能的 bash 命令**。所有数据库/后端/前端的启动细节见 `local-dev` 技能。

### 启动方式选择

- `mvn spring-boot:run` — 命令行热重载
- IDE 调试 — 如果用户已在 IDE 中启动后端，则跳过步骤 4，仅检查端口 8080 是否已在监听

---

## 阶段 3：MCP 工具链就绪

全栈启动完成后，执行 MCP 层：

### 3.1 增量更新知识图谱

- MCP: `build_or_update_graph_tool`（无参数 = 增量）
- CLI 回退: `python -m code_review_graph build`

### 3.2 Orca 状态

```bash
orca status --json 2>/dev/null
```

- 运行中 → 输出工作树概况。
- 未运行 → 静默跳过。

---

## 最终确认输出

```
✅ 客户端开发环境就绪！

  前端：http://localhost:3100
  后端：http://localhost:8080/jeecg-boot/doc.html
  账号：admin / 123456

  MCP 工具链：
  ├─ code-review-graph MCP ✅
  ├─ 知识图谱 ✅（N 节点 / M 边）
  └─ Orca CLI ✅ / ⚠️ 未安装

  修改代码：
  • Vue 文件 → 浏览器秒级热更新
  • Java 文件 → DevTools 热重载（2-5 秒）
  • 新增 Vue 组件 → 需重启 Vite
```

---

## 降级策略

| 失败 | 动作 | 阻塞？ |
|------|------|:--:|
| Java < 17 / Node < 20 | 输出升级指引 | ✅ |
| MySQL/Redis 未运行 | 尝试自动拉起（见 `local-dev` 技能） | ⚠️ |
| 数据库初始化失败 | 输出具体 SQL 错误 | ✅ |
| 后端启动失败 | 输出日志尾部（路径见 `local-dev` 技能） | ✅ |
| 前端启动失败 | 输出日志尾部（路径见 `local-dev` 技能） | ✅ |
| pnpm install 失败 | 回退 `npx vite --host` | ❌ 降级 |
| code-review-graph 缺失 | `pip3 install code-review-graph` | ❌ 自动修复 |
| 图谱构建失败 | 警告，不阻塞 | ❌ 跳过 |
| Orca 未安装 | 静默跳过 | ❌ 跳过 |
| MCP 未连接 | 提示重启终端 | ⚠️ |

---

## 停止客户端

```bash
# 停止后端 + 前端（不停止 MySQL/Redis——低资源常驻）
# Windows
taskkill //F //IM "java.exe" 2>/dev/null
taskkill //F //IM "node.exe" 2>/dev/null

# macOS / Linux
pkill -f "spring-boot:run"
pkill -f "vite"
```

> 完整停止步骤见 `local-dev` 技能。

---

## 自愈能力

- 标记文件被删 → 阶段 0 重新全流程
- `node_modules` 被删 → `local-dev` 步骤 3 幂等重装
- `graph.db` 被删 → 阶段 0.4/3.1 重新构建
- 数据库被删 → `local-dev` 步骤 2 幂等重建
- MCP 配置被覆盖 → 阶段 0.2 自动修复

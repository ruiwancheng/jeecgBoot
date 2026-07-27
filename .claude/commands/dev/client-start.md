---
description: 自有命令 — 客户端开发环境一键启动：在 /start 全栈启动基础上叠加 MCP 工具链（code-review-graph 图谱 + Orca CLI），支持多客户端独立部署
---

# /client-start

启动**客户端全栈开发环境**。每个客户端是独立完整的本地开发服务器。

与 `/start` 的区别：`/client-start` 额外启动 MCP 工具链（code-review-graph 知识图谱 + Orca CLI）。

## 用法

```
/client-start           # 启动客户端全栈开发环境
说"启动客户端"           # 同上
说"帮我停止开发环境"     # 停止前后端（MySQL/Redis 保留）
```

## 流程

使用 `client-start` 技能获取领域知识，按 4 个阶段自动执行。

### 1. 检测运行阶段

检查标记文件 `.claude/.client-start-initialized` 是否存在：

**文件不存在 → 首次接入（阶段 0）：**
1. 工具链核查 → Java 17+ / Node 20+ / MySQL / Redis / Maven / pnpm / Python 3 / code-review-graph / Orca CLI。缺什么给什么安装命令（引用 `onboard` 技能获取 OS 适配指引）
2. MCP 依赖安装 → 读 `.mcp.json` 验证每个 MCP server 的 Python 包已安装
3. MCP 配置 → 写入 `settings.local.json` 启用所有 MCP server
4. Orca CLI 验证 → 可用性检查
5. 构建知识图谱 → 首次全量构建
6. 写标记文件

**文件存在 → 快速检查（阶段 1）：**
1. MCP 工具可用？
2. Orca 可用？

> 阶段 0 中任何需要用户操作的步骤（安装软件），AI 输出命令并等待用户确认后继续。

### 2. 全栈启动（阶段 2）

**复用 `local-dev` 技能的 5 步流程**（与 `/start` 相同）：
1. 环境检查 → MySQL/Redis/Java/Node 就绪？
2. 数据库初始化 → 首次导入表结构（幂等）
3. 安装前端依赖 → `pnpm install`
4. 启动后端 → `mvn spring-boot:run`（端口 8080，DevTools 热重载）
5. 启动前端 → `pnpm dev`（端口 3100，Vite 热更新）

> 如果用户已在 IDE 中启动后端，跳过步骤 4，仅检测端口 8080。

### 3. MCP 工具链（阶段 3）

1. 增量更新知识图谱
2. 检查 Orca 状态

### 4. 输出就绪确认

```
✅ 客户端开发环境就绪！

  前端：http://localhost:3100
  后端：http://localhost:8080/jeecg-boot/doc.html
  账号：admin / 123456

  MCP 工具链：
  ├─ code-review-graph MCP ✅
  ├─ 知识图谱 ✅
  └─ Orca CLI ✅ / ⚠️ 未安装
```

## 停止

| 命令 | 效果 |
|------|------|
| "帮我停止开发环境" | 停止前后端（MySQL/Redis 保留） |
| "全部停止" | 停止前后端 + MySQL + Redis |

## 与其他命令的关系

| 命令 | 全栈启动 | MCP 工具链 | 适用场景 |
|------|:--:|:--:|------|
| `/start` | ✅ | ❌ | 服务端/单人开发，不需要图谱/MCP |
| **`/client-start`** | ✅ | ✅ | **多客户端开发，需要代码审查/知识图谱** |
| `/onboard` | ❌ | ❌ | 仅检测工具链，给安装指引 |

## 故障自愈

- 标记文件/配置/依赖被误删 → 自动检测并重建
- 图谱构建失败 → 不阻塞启动，稍后可手动 `/update-graph`
- MCP 未连接 → 提示重启终端使配置生效

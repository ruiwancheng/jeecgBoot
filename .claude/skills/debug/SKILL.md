---
name: debug
description: 报错诊断与修复 — 根据错误日志定位问题、分析根因、最小化修复。Error diagnosis and minimal fix from error logs.
version: 1.0.0
---

# debug — 报错诊断与修复

## 黄金法则

不猜测，按步骤。同一修复失败 2 次必须停下来。

## Orca 终端集成（推荐）

debug 过程中频繁查看日志、重启服务、测试修复时，利用 Orca 终端布局标准：

| 操作 | Orca 命令 | 降级 (Bash) |
|------|-----------|-------------|
| 查看后端日志 | `orca terminal read --terminal term_backend --lines 100` | `tail -100 /tmp/jeecg-backend.log` |
| 重启后端 | `orca terminal create --worktree active --command "mvn spring-boot:run"` | `kill` + `nohup` 手动 |
| 查看终端输出 | `orca terminal read --terminal term_backend` | 手动切窗口查看 |
| 发送构建命令 | `orca terminal send --terminal term_build --text "mvn compile"` | 直接 bash 执行 |

> 降级策略：Orca 不可用时 → 使用标准 Bash 命令。

## 诊断流程

1. 完整读报错，不只看一行
2. 从栈中找项目代码文件名和行号
3. Read 上下文（前后 20 行）
4. `git diff` 查看近期改动
5. 最小修复，修一处验证一处
6. 2 次无效 → 告知用户具体情况

## JeecgBoot 常见报错速查

| 报错特征 | 根因 | 修复方向 |
|---------|------|---------|
| `Table 'xxx' doesn't exist` | Flyway 未执行或表名错误 | 检查 flyway 迁移文件 |
| `Could not autowire` | 模块未注册 Maven 依赖 | 检查 pom.xml |
| `ERR_NAME_NOT_RESOLVED` | Docker 内部主机名 | 检查容器网络配置 |
| `401/403` | Token 过期或权限不足 | 检查登录态/权限配置 |

## 图形调用链追踪（Graph Call-Chain Tracing）

诊断时使用 code-review-graph MCP 工具自动追踪调用链，替代手动 Read 上下文。

### 调用参数

| 步骤 | 工具 | 参数 | 用途 |
|------|------|------|------|
| 1. 上游追踪 | `query_graph_tool` | `pattern="callers_of"`, `target="<报错函数>"`, `detail_level="minimal"` | 查找谁调用了报错方法——调用者可能传入坏数据 |
| 2. 下游追踪 | `query_graph_tool` | `pattern="callees_of"`, `target="<报错函数>"`, `detail_level="minimal"` | 查找报错方法调用了谁——标记数据层调用链 |
| 3. 影响流 | `get_affected_flows_tool` | 使用栈中文件作为 changed_files | 列出受影响的用户可见功能 |
| 4. 测试覆盖 | `query_graph_tool` | `pattern="tests_for"`, `target="<报错函数>"`, `detail_level="minimal"` | 检查报错函数是否有测试保护 |
| 5. 波及范围 | `get_impact_radius_tool` | `max_depth=2`, 使用栈中文件 | 评估修复的波及范围，辅助判断修复策略 |

### 判定规则

| 发现 | 动作 |
|------|------|
| 上游调用者存在 | 列为"上游可能受影响"，检查传入参数 |
| 下游含数据库操作 | 标记为"数据层调用链"，重点检查 SQL/事务 |
| 无测试覆盖 | 修复后提示补充测试 |
| 影响半径 ≤1 | 局部问题，直接修复 |
| 影响半径 ≥5 | 广泛影响，建议先回滚再排查 |

### 降级策略

- MCP 服务不可用 / 超时（>10s）→ 走手动 Read 上下文（标准流程）
- 空结果 → 视为"该函数未被图谱索引"，走标准流程

## 3 次即停判定标准

- **"同一问题"定义**：同一个文件的同一个方法报同一个异常类型
- 换了文件 → 不算同一问题
- 换了方法 → 不算同一问题
- 换了异常类型 → 不算同一问题
- 3 次后停止修复，告知用户疑似架构或设计问题

## gen-tests-rules.json 字段 Schema

调试过程中发现的遗漏场景，应反哺到 gen-tests 规则库：

```json
{
  "id": "规则编号（R001, R002...）",
  "bugType": "Bug 分类（空值NPE、越权访问、数值溢出、唯一约束冲突等）",
  "trigger": "代码特征描述（gen-tests 匹配用）",
  "httpMethod": "适用的 HTTP 方法列表",
  "missingScenario": "gen-tests 漏了什么场景",
  "addCase": {
    "api": "API 测试用例描述",
    "e2e": "E2E 测试用例描述"
  },
  "source": "规则来源（内置/Bug描述）",
  "created": "创建日期（YYYY-MM-DD）"
}
```

## Bug 反哺决策矩阵

**gen-tests 能覆盖的 Bug 类型：**
- 空值 NPE — 加必填参数为空的测试用例
- 越权访问 — 加无权限用户调用的测试用例
- 边界值 — 加超长字符串/负数/零值的测试用例
- 唯一约束冲突 — 加重复提交的测试用例
- 特殊字符 — 加 SQL 注入字符的测试用例
- 并发重复提交 — 加快速双重点击的测试用例

**gen-tests 不能覆盖的：**
- 架构设计问题
- 环境配置问题
- 第三方依赖 Bug
- 性能瓶颈

**判断标准：** Bug 是否由"代码逻辑遗漏"导致，且可通过增加测试用例预防。是 → 反哺规则；否 → 记录为平台问题。

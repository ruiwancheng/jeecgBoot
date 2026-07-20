---
name: review
description: 代码审查，检查正确性/类型安全/模式合规/安全性/性能/完整性/可维护性 — Code review across 7 dimensions: correctness, type safety, pattern compliance, security, performance, completeness, maintainability
version: 1.0.0
---

# 代码审查 (Review)

## 7 类审查定义

### 正确性
逻辑错误、空值未处理、边界条件遗漏、类型转换错误、并发问题。

**检查要点：**
- `null`/`undefined` 调用前是否判空
- 数组/集合操作是否检查越界
- 数学运算是否考虑除零
- 状态流转是否覆盖所有合法路径
- 条件分支是否覆盖所有可能值

### 类型安全
类型不匹配、`any` 滥用、类型断言缺失、泛型约束遗漏。

**检查要点：**
- 前端禁止 `any`，必须用 `unknown` 或具体类型
- API 返回数据是否定义了接口类型
- 后端方法参数和返回值类型是否明确
- 隐式类型转换是否有风险

### 模式合规
命名规范、文件结构、代码约定。参见 `.claude/rules/code-style.md` 和 `.claude/rules/frontend.md`。

**检查要点：**
- Java: `update-begin`/`update-end` 标记、Controller 继承 `JeecgController`、Entity 用 `@TableId(type = IdType.ASSIGN_ID)`
- Vue: `index.vue` + `.api.ts` + `.data.ts` 三件套、组件名 kebab-case、`defHttp` 发请求
- 文件必须在允许的目录内（参见 `.claude/rules/file-scope.md`）

### 安全性
SQL 注入、XSS、密钥泄露、未授权访问、敏感数据暴露。

**检查要点：**
- SQL 必须参数化，禁止字符串拼接
- 用户输入是否校验和转义
- 密码/Token/API Key 是否硬编码
- 接口是否有权限校验（参见 `.claude/rules/data-scope.md`）
- 无 WHERE 的 DELETE/UPDATE 是否被拦截

### 性能
N+1 查询、无限循环、不必要的大数据量加载、未使用索引的查询。

**检查要点：**
- 循环内是否调用数据库
- 分页是否生效
- 是否一次性加载全表数据
- 是否有无退出条件的递归或循环

### 完整性
缺测试、缺错误处理、缺边界校验、缺注释标记。

**检查要点：**
- 异常场景是否捕获并返回有意义的消息
- 输入为空/超长/非法值时是否处理
- Controller 方法是否有对应的权限注解
- 新增文件是否在相关 pom.xml / 路由文件中注册

### 可维护性
死代码、嵌套过深（>3 层）、函数过长（>50 行）、重复逻辑、魔法数字。

**检查要点：**
- 是否有未引用的变量/方法/import
- 是否有复制粘贴的代码块
- 是否有无注释的业务常量

## 严重度判定

| 级别 | 定义 | 动作 |
|------|------|------|
| **CRITICAL** | 安全漏洞（SQL注入/XSS/密钥泄露）、数据损坏风险（无WHERE的UPDATE/DELETE）、未授权访问 | 必须立即修复，不得提交 |
| **HIGH** | 可能导致线上故障（N+1全表扫描、空指针、无限循环）、破坏现有功能 | 应该在提交前修复 |
| **MEDIUM** | 代码质量问题（缺错误处理、缺边界校验、any滥用、死代码） | 建议修复 |
| **LOW** | 风格偏好（变量命名、注释格式、import顺序） | 可选修复 |

## 架构感知严重度调整（Architecture-Aware Severity）

在 git diff 后、逐文件审查前，使用 code-review-graph MCP 工具获取架构上下文，对严重度做加权调整。

### 调用参数

| 步骤 | 工具 | 参数 |
|------|------|------|
| 1. 入口检查 | `get_minimal_context_tool` | `task="code review"` |
| 2. 变更检测 | `detect_changes_tool` | `base="HEAD~1"`, `detail_level="minimal"`, `include_source=false` |
| 3. 热点检查 | `get_hub_nodes_tool` | `top_n=10` |
| 4. 桥接检查 | `get_bridge_nodes_tool` | `top_n=10` |
| 5. 死代码检测 | `refactor_tool` | `mode="dead_code"` |

### 调整规则

| 条件 | 调整 |
|------|------|
| 变更函数在 hub_nodes（top 10）中 | **严重度 +1 级**（MEDIUM→HIGH, HIGH→CRITICAL） |
| 变更函数在 bridge_nodes（top 10）中 | **严重度 +1 级** |
| `query_graph_tool(pattern="callers_of")` 调用者 ≥10 | **严重度 +1 级** |
| 变更函数被 `refactor_tool(dead_code)` 标记为死代码 | **降为 LOW**，标注"死代码" |
| 多个条件同时命中 | 叠加生效，最高 CRITICAL |

### 降级策略

- MCP 服务不可用 / 超时（>10s）→ 使用标准平坦严重度逻辑，不调整
- 空结果（如热点列表中无变更函数）→ 不调整，保持原严重度

## 审查流程

1. 读取 git diff 获取变更文件列表
2. **（可选增强）运行架构感知严重度调整**，获取变更函数的 hub/bridge/调用者数量
3. 按 7 类逐文件审查，应用调整后的严重度
4. 标注每项问题的严重度（标注是否经过架构加权）
5. 汇总输出审查报告

## 审查报告格式

```
## 审查报告

### 问题列表

| # | 严重度 | 类别 | 文件:行号 | 描述 | 建议修复 |
|---|--------|------|-----------|------|----------|
| 1 | CRITICAL | 安全性 | XxxController.java:42 | SQL字符串拼接 | 改用MyBatis-Plus参数化查询 |
| 2 | HIGH | 正确性 | YyyService.java:58 | 未做空值判断 | 加if判空 |

### 统计
- CRITICAL: N 个
- HIGH: N 个
- MEDIUM: N 个
- LOW: N 个
```

## 审查后动作

1. 列出 MEDIUM 及以上问题
2. 询问用户："以上问题需要修复哪些？请选择序号，输入 'all' 修复全部。"
3. 用户选择后逐个修复
4. CRITICAL / HIGH 问题修复后，重跑审查确认清零

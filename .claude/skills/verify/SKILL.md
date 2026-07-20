---
name: verify
description: 变更自验证，按变更类型匹配验证方法并逐项输出证据 — Change self-verification: match verification method by change type, output evidence item by item
version: 1.0.0
---

# 变更自验证 (Verify)

## 变更类型到验证方法的映射

### Controller 新增/修改

**验证方法：** curl 调用接口

```bash
curl -s -X GET "http://localhost:8080/jeecg-boot/xxx/yyy" -H "X-Access-Token: <token>"
```

**验证点：**
- HTTP 状态码为 200
- 响应体 `code` 字段为 200，`success` 为 true
- `result` 字段存在且结构与预期一致
- 数据内容符合业务逻辑

### .vue 组件变更

**验证方法：** Playwright 打开页面，检查元素。

**验证点：**
- 目标元素存在（`page.locator(...).isVisible()`）
- 文本内容与预期一致
- 交互行为（点击/输入/提交）正常

### .data.ts 变更（表格列/表单字段/SearchSchema）

**验证方法：** 根据字段类型选择。

| 变更类型 | 验证方法 |
|----------|----------|
| 表格列定义 | Playwright 打开列表页 → 验证列头存在 |
| 表单字段 | Playwright 打开新增/编辑页 → 验证输入框/选择器存在 |
| SearchSchema | Playwright 打开列表页 → 验证搜索区域字段存在 |

**验证点：**
- 列头/表单标签/搜索字段名与 `.data.ts` 中配置一致
- 必填字段有 `*` 标记
- 字典类型的字段渲染为下拉选择器

### Service 方法变更

**验证方法：** curl 调用上层 Controller（Service 不直接暴露 HTTP 端点）。

**验证点：**
- 间接验证：Controller → Service 调用链正确
- 业务逻辑正确：输入 → 预期输出吻合
- 异常场景：传入非法参数，验证错误信息

### 配置文件变更（application-*.yml / pom.xml）

**验证方法：** 检查对应功能。

| 配置变更 | 验证方法 |
|----------|----------|
| 数据库连接 | curl 查询接口，验证数据返回 |
| 端口 | curl 指定端口，验证连通 |
| 日志级别 | 触发对应日志，检查输出 |
| Maven 依赖 | 编译通过 + 引用新依赖的代码运行正常 |

## 铁律

> **没有具体证据不能声称通过。**

逐项输出格式：

```
✓ 接口 GET /xxx/yyy — HTTP 200, code=200, result 含 3 条记录
✗ 接口 POST /xxx/yyy — HTTP 500, {"message": "NullPointerException at XxxService:42"}
```

每项的 `✓` 必须附具体证据（状态码 + 响应关键片段），`✗` 必须附完整报错信息。

## 图形预分析（Graph Pre-Analysis）

在 git diff 后、验证方法选择前，使用 code-review-graph MCP 工具增强分析精准度。

### 调用参数

| 步骤 | 工具 | 参数 |
|------|------|------|
| 1. 入口检查 | `get_minimal_context_tool` | `task="verify changes"` |
| 2. 变更分析 | `detect_changes_tool` | `base="HEAD~1"`, `detail_level="minimal"` |
| 3. 波及范围 | `get_impact_radius_tool` | `max_depth=1` |

### 判定规则

| 条件 | 动作 |
|------|------|
| 风险评分 `low` + 变更 ≤2 个文件 + 全为 `.vue` / `.data.ts` | 仅 Playwright 验证，跳过 curl |
| 风险评分 `high` 或 变更函数在 hub/bridge 节点中 | 追加 curl 验证所有调用者 |
| 其他情况 | 保持标准验证流程 |

### 降级策略

- MCP 服务不可用 / 超时（>10s）→ 输出 `[graph unavailable, falling back to standard verification]`，走标准 git-diff 逻辑
- 空结果 → 视为"无额外洞察"，继续标准流程

## 验证流程

### 验证环境隔离（Orca 增强，推荐）

对于涉及数据库写入、状态变更或配置修改的验证，建议使用 Orca 工作树隔离：

```bash
# 创建验证隔离工作树
orca worktree create --name eagleeye/verify-{模块名}

# 在隔离环境中执行验证，验证完成后清理：
orca worktree rm --worktree branch:eagleeye/verify-{模块名}
```

**收益：** 验证时的测试数据不污染开发数据库，临时配置修改不影响主配置。

> 降级策略：Orca 不可用时 → 直接在开发目录验证（标准行为）。

### Orca 终端集成（推荐）

验证过程中如需查看后端日志或重启服务：

| 操作 | Orca 命令 | 降级 (Bash) |
|------|-----------|-------------|
| 查看后端日志 | `orca terminal read --terminal term_backend --lines 50` | `tail -50 /tmp/jeecg-backend.log` |
| 重启后端 | `orca terminal send` + `create` + `wait` | `kill` + `nohup mvn spring-boot:run` |
| 构建前端 | `orca terminal send --text "pnpm build"` | 直接 bash 执行 |

> 降级策略：Orca 不可用时 → 使用标准 Bash 命令。

## 验证流程

1. 读取 git diff，识别变更文件和变更类型
2. **（可选增强）运行图形预分析**，按判定规则调整验证深度和优先级
3. 按映射表确定每个变更的验证方法
4. 逐项执行验证
5. 汇总输出，标注通过/失败及证据
6. 如有 ✗ 项，分析根因并尝试修复（最多 2 次），修复后重验证

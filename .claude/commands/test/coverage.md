# /coverage — 测试覆盖率统计

> **业务人员命令**：查看当前测试覆盖情况，找到待补缺口。

## 命令格式

```bash
/coverage                    # 总览：覆盖率统计表
/coverage gap                # 缺口清单：所有无覆盖端点
/coverage <项目>             # 单项目：项目内详情
/coverage <项目> <模块>      # 单模块：模块内详情
```

## 输出格式

### `/coverage`（总览）

```markdown
## 测试覆盖率总览（2026-08-04）

**前端页面**：38 个 | 后端 Controller：40 个 | 总端点：~180 个

| 维度 | 已覆盖 | 总数 | 覆盖率 |
|---|---|---|---|
| 页面（E2E spec） | 36 | 38 | 95% |
| 链路（chains） | 9 | ? | ? |
| 模块（modules） | 14 | ? | ? |
| 端点（API） | ~145 | ~180 | ~80% |

### 缺口（按优先级）

🔴 P0 — 完全无覆盖：
- customerAddress（7 端点，0 调用）
- customerContact（7 端点，0 调用）
...

🟡 P1 — 部分覆盖：
- salesInvoice（写入路径覆盖不足）
- purchaseInvoice（写入路径覆盖不足）

🟢 P2 — 已基本覆盖：
- basic/material（55 次调用）
```

### `/coverage gap`（缺口清单）

按 controller 列出无覆盖端点：

```markdown
## 完全无覆盖端点

| Controller | 端点数 | 调用次数 | 建议命令 |
|---|---|---|---|
| customerAddress | 7 | 0 | /add-tests basic customerAddress |
| customerContact | 7 | 0 | /add-tests basic customerContact |
...
```

## AI 执行流程

1. 解析参数（scope = 项目/模块/全部）
2. 扫描源码：
   - `find ... -name "*Controller.java"` 列所有 controller
   - `grep -E "@(Get|Post|Put|Delete)Mapping"` 数端点数
3. 扫描测试：
   - `grep -rE "c\.api.*/<path>|/mes/<module>" harness/tests/ harness/e2e/mes/` 数调用数
4. 输出覆盖率表 + 缺口清单 + 推荐 `/add-tests` 命令

## 关联命令

- `/add-tests` — 补齐缺口
- `/test-all` — 跑全量测试
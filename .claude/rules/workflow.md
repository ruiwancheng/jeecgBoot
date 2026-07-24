---
name: workflow
description: 开发流程——需求→计划→实现→自验证→提交
glob: "**/*"
version: 4.0
---

# 开发流程

```
/brainstorm → /plan → [orca-review] → 写代码 → /verify → git commit + push → /done
```

步骤清单：

| 步骤 | 命令 | 轻量 | 标准 | 全量 |
|------|------|:---:|:---:|:---:|
| 需求澄清 | /brainstorm | ✓ | ✓ | ✓ |
| 实施计划 | /plan | ✓ | ✓ | ✓ |
| 编码实现 | - | ✓ | ✓ | ✓ |
| 自验证 | /verify | ✓ | ✓ | ✓ |
| /quality-gate | — | ✓ | ✓ |
| 提交推送 | git commit + push | ✓ | ✓ | ✓ |
| 前端静态 | /test-frontend | ✓ | ✓ | ✓ |
| 模块测试 | /test-api | - | ✓ | ✓ |
| E2E 测试 | /test-e2e | - | - | ✓ |
| 全量测试 | /test-all | - | - | ✓ |
| 完成检查 | /done | ✓ | ✓ | ✓ |

遇报错用 /debug，部署质量门控详见 `deploy-quality-gate.md`。

## 分级测试规则

写代码后按变更影响面选择测试级别：

| 级别 | 触发条件 | 执行内容 |
|:--:|------|------|
| 轻量 | 文案/样式/注释 | /verify |
| 标准 | Controller/Service/Vue（≤3文件） | /verify + /test-api |
| 全量 | Entity/Mapper/SQL/≥5文件 | /verify + /test-api + /test-e2e + /test-all |

不变更不测试。

## PRD 阅读规则

**PRD 核心逻辑和操作演示必须同时阅读，不可只看其一。** 操作演示里的交互动词决定数据结构：

| 操作演示动词 | 数据结构含义 |
|-------------|-------------|
| "选择/关联 XX" | 外键引用（如 deliveryNoteId） |
| "系统自动带出产品、数量" | 明细行 + 关联查询（主子表） |
| "输入/填写实际数量" | 明细行独立字段（如 actualQty） |
| "多行/明细/逐行" | 主子表而非单表 |

> **来源模块：** 销售出库。单看核心逻辑判断为单表，补读操作演示后发现应是主子表，多花一倍工作量。

## 开发前依赖查证

新模块开发前确认以下依赖链可用：

| # | 检查项 | 验证方法 |
|---|--------|---------|
| 1 | Shiro 权限链 | 确认菜单+权限码在 `MesMenuRegistry` 注册 |
| 2 | SQL 兼容性 | 新 SQL 文件不含 `IF EXISTS`、`sys_dict_item` 不含 `del_flag` |
| 3 | 前端组件 | 表字典用 `JSearchSelect`（合写 `dict: 'table,text,code'`） |
| 4 | 字典存在 | 需要的 `sys_dict` + `sys_dict_item` 已在 SQL 中注册 |
| 5 | 父菜单存在 | 新模块的 `parentId` 指向的菜单已注册 |

## 推送前检查

| 检查项 | 阻塞？ | 说明 |
|--------|:--:|------|
| boot-module 声明的模块目录存在 | 是 | 缺目录 → 编译失败 |
| system-start 有对应依赖声明 | 是 | 缺依赖 → 运行时找不到类 |
| 模块代码已 git 跟踪 | 是 | 漏提交 → CI 编译失败 |

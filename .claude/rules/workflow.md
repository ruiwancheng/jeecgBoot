---
name: workflow
description: 开发流程——需求→计划→实现→自验证→智能分级测试→提交
glob: "**/*"
version: 2.0
---

# 开发流程

```
/brainstorm → /plan → 用户确认 → 写代码 → /verify → 分级测试 → /done → 人工验收
```

## 分级测试规则（AI 自动判定）

写代码后 AI 分析 `git diff`，按变更影响面自动选择测试级别：

### 轻量级（微小改动，几十 tokens）
| 判定条件 |
|---------|
| 只改了 `.vue` 模板文字/样式 |
| 只改了注释或格式化 |
| 只改了 `.data.ts` 的列宽/标签 |
| 只改了单个字段的校验规则 |

→ 只跑 `/verify`（改了什么验什么），跳过回归测试。

### 标准级（日常改动，几百 tokens）
| 判定条件 |
|---------|
| 新增/修改 Controller 方法 |
| 新增/修改 `.vue` 组件逻辑 |
| 修改 Service 方法 |
| 修改 `.data.ts` 的表单/搜索 Schema |
| 修改 3 个以内文件 |

→ `/verify` + `/test-api <模块>`（只测受影响的模块）

### 全量级（高风险改动，几千 tokens）
| 判定条件 |
|---------|
| 新增/修改 Entity 字段 |
| 新增/删除 Controller |
| 修改 Mapper/XML |
| 修改菜单/权限 SQL |
| 修改 5 个以上文件 |
| 修改 pom.xml 依赖 |

→ `/verify` + `/test-api` + `/test-e2e` + `/test-all`

### 不变更不测试
如果没有 `git diff`（刚 /setup 完，没改代码）→ 全部跳过。

## 步骤清单

| 步骤 | 命令 | 轻量 | 标准 | 全量 |
|------|------|:---:|:---:|:---:|
| 需求澄清 | /brainstorm | ✓ | ✓ | ✓ |
| 实施计划 | /plan | ✓ | ✓ | ✓ |
| 编码实现 | - | ✓ | ✓ | ✓ |
| 自验证 | /verify | ✓ | ✓ | ✓ |
| 前端静态 | /test-frontend | ✓ | ✓ | ✓ |
| 模块测试 | /test-api | - | ✓ | ✓ |
| E2E 测试 | /test-e2e | - | - | ✓ |
| 全量测试 | /test-all | - | - | ✓ |
| 完成检查 | /done | ✓ | ✓ | ✓ |

遇报错用 /debug，修复后自动调 /verify。

# Orca Review — 采购申请 searchFormSchema 新增"申请部门"字段

**评审日期**: 2026-07-24
**评审类型**: plan 阶段外部评审
**评审对象**: 在 `apply.data.ts` 的 `searchFormSchema` 中新增 `{ field: "applicationDept", label: "申请部门", component: "Input", colProps: { span: 6 } }`

---

## 1. 文件路径

✅ **正确**。`jeecgboot-vue3/src/views/project/mes/purchase/apply/apply.data.ts` 是采购申请页面的数据配置文件，`searchFormSchema` 位于该文件第 15-19 行，是搜索表单的正确定义位置。

---

## 2. 字段配置一致性检查

### 2.1 结构格式

✅ **一致**。提案 `{ field, label, component, colProps }` 四字段结构与现有 3 个搜索字段完全一致。`span: 6` 与现有字段统一（搜索区 4 字段一行）。

### 2.2 字段名 — 🔴 P0 错误

**`field: "applicationDept"` 应改为 `field: "deptId"`。**

证据链：

| 位置 | 使用的字段名 | 行号 |
|------|-------------|------|
| 后端 Entity `MesPurchaseApply.java` | `private String deptId;` | 第 37 行 |
| 前端 columns 列定义 | `dataIndex: 'deptId'` | 第 6 行 |
| 前端 formSchema 编辑表单 | `field: 'deptId'` | 第 24 行 |
| **提案 searchFormSchema** | `field: "applicationDept"` ❌ | — |

JeecgBoot 的 `QueryGenerator` 通过 HTTP 请求参数名与 Entity 字段名匹配来构建查询条件。如果前端传 `applicationDept`，后端 Entity 没有对应字段，搜索条件会被静默忽略——**搜索框输入任何内容都不会生效，零报错、零结果**。

### 2.3 标签文本

✅ `label: "申请部门"` 与 columns 标题（第 6 行）和 formSchema 标签（第 24 行）完全一致。

### 2.4 组件类型

✅ `component: "Input"` 合理。`deptId` 在后端是 `String` 类型，目前 columns 和 formSchema 中均以纯文本展示，搜索用 Input 是最简选择。若未来需要下拉选择部门，可升级为 `JSearchSelect`。

### 2.5 缺少 componentProps

⚠️ **建议补充**。现有搜索字段中 `code` 有 `componentProps: { maxlength: 50 }`，`applicantId` 没有。考虑到 `deptId` 是 String 类型，建议加上 `maxlength` 与 Entity 字段长度对齐，但这不属于阻断性问题。

---

## 3. 是否遗漏

| 检查项 | 结果 |
|--------|:--:|
| 后端 Entity 是否有对应字段 | ✅ 有 `deptId`（第 37 行） |
| 前端 columns 是否展示了该字段 | ✅ 有（第 6 行，标题"申请部门"） |
| 是否需要后端 Controller 改动 | ❌ 不需要 — `QueryGenerator` 自动映射 |
| 前端路由/组件是否需要改动 | ❌ 不需要 — 只改 searchFormSchema 即可 |
| 是否需要新增字典/权限 | ❌ 不需要 |

**无遗漏。** 这是一个纯前端搜索字段新增，后端完全不需要改动。

---

## 4. 评审结论

| 维度 | 判定 |
|------|:--:|
| 路径正确性 | ✅ PASS |
| 结构一致性 | ✅ PASS |
| 字段名正确性 | 🔴 **FAIL** — `applicationDept` → 应为 `deptId` |
| 组件选型 | ✅ PASS |
| 完整性 | ✅ PASS（无遗漏） |

### 修正建议

```typescript
// 正确写法
{ field: 'deptId', label: '申请部门', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } }
```

**结论：NEEDS WORK** — 字段名必须从 `applicationDept` 修正为 `deptId`，否则搜索功能静默失效。修正后即可实施。

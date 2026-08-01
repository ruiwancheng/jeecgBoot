---
description: 自有命令 — Vue 黄金模板改造：检测偏离项 + 生成 diff 让人工 review，半自动模式
---

# /vue-migrate <文件|页面> [--apply]

按黄金模板 UX 基线**检测偏离项 + 生成改造 diff**，人工 review 后应用。

## 用法

```
# 单文件（向后兼容）
/vue-migrate jeecgboot-vue3/src/views/mes/receipt/index.vue
/vue-migrate jeecgboot-vue3/src/views/mes/receipt/index.vue --apply     # 直接应用（风险高）

# 按页面（v2 新增）— 一份跨文件聚合 diff
/vue-migrate jeecgboot-vue3/src/views/project/mes/stock/other-out

# 全量页面清单（不动文件，只看哪些页面需要 migrate）
/vue-migrate --all-list
```

## 流程

### 1. 加载 vue-audit 脚本

使用 `vue-audit.sh` 获取基线检查结果。

- 单文件 → `vue-audit.sh <file> [--strict]`
- 页面 → `vue-audit.sh <page-dir> [--strict]`
- 全量 → `vue-audit.sh --all [--strict]`

### 2. 检测偏离项

跑 vue-audit.sh，提取 WARN/FAIL 项：

| 偏离项 | 自动修复策略 | 风险等级 |
|---|---|---|
| 缺 `@generated-from` 标注 | 自动追加 | 低 |
| 缺 `_dictText` 后缀 | 自动追加（按规则改） | 中 |
| 缺 `confirmLoading` | 自动追加防重复模板 | 中 |
| 缺 `popConfirm` | 自动包 popConfirm 组件 | 中 |
| 缺 `onMaterialChange` 预填 | 自动加默认值 | 高（需业务确认） |
| 缺 `JMaterialSelect` | 不自动改（提示人工选） | 高 |
| 缺 `MaterialSelectModal` | 不自动改（提示人工选） | 高 |
| 缺红标样式 | 不自动改 | 低 |
| **缺 queryXxxSelect 导出**（v2 跨文件） | 不自动改（提示补函数体） | 中 |
| **缺 queryXxxSelect 在 api.ts**（v2 跨文件） | 不自动改（提示补导出） | 高 |

### 3. 输出改造方案

#### 单文件模式

```
文件：receipt/index.vue
当前状态：PASS 3 / WARN 9 / FAIL 1
   ├─ ⚠ 缺 @generated-from → [自动] 在文件首追加注释
   ├─ ⚠ 缺 rowSelection → [人工] 业务是否需要批量操作？
   ├─ ⚠ 缺 popConfirm → [自动] 包 popConfirm 组件
   ├─ ✗ 缺 confirmLoading → [自动] 加 setDrawerProps({confirmLoading: true})
   └─ ⚠ 缺 _dictText → [半自动] grep 出 materialId 等字段，提示改法

生成 diff（人 review 后应用）：
  + // @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
  + import { Popconfirm } from 'ant-design-vue';
  + setDrawerProps({ confirmLoading: true });
  ...
```

#### 页面聚合模式（v2 新增）

```
页面：stock/other-out
当前状态（页面汇总）：PASS 17 / WARN 10 / FAIL 1

── index.vue ──
   ├─ ⚠ 搜索栏字典下拉 → [人工] 补 ApiSelect 或 JDictSelectTag
   ├─ ⚠ 缺 _dictText → [半自动] grep 出 materialId 等字段

── OtherOutDrawer.vue ──
   ├─ ⚠ 提交 loading → [自动] setDrawerProps({ loading: true })
   ├─ ⚠ 缺 _dictText → [半自动]

── otherOut.data.ts ──
   ├─ ✗ ApiSelect 引用缺失（queryWarehouseSelect）→ [人工] 在 otherOut.api.ts 补导出

── otherOut.api.ts ──
   ├─ ⚠ 缺 @generated-from → [自动] 追加

生成聚合 diff（按文件分组，人 review 后应用）：

──── index.vue ────
  + // @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
  + import { ApiSelect } from '/@/components/Form';
  ...

──── OtherOutDrawer.vue ────
  + setDrawerProps({ loading: true });
  ...

──── otherOut.api.ts ────
  + // @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
  + export async function queryWarehouseSelect(...) { ... }
  ...
```

### 4. 人工 review

显示 diff，要求用户确认：

- 输入 `y` → 应用修改（备份原文件到 `<file>.bak` 或 `<page-dir>.bak/`）
- 输入 `n` → 取消
- 输入 `edit` → 进入交互式编辑

### 5. 改造后重审

跑一次 vue-audit.sh，确认改进效果：

```
# 单文件
改造前：PASS 3 / WARN 9 / FAIL 1
改造后：PASS 8 / WARN 4 / FAIL 0   ← 合规率提升

# 页面聚合
改造前（页面汇总）：PASS 17 / WARN 10 / FAIL 1
改造后（页面汇总）：PASS 22 / WARN 5 / FAIL 0   ← 合规率提升
```

## 安全约束

1. **默认不应用**——只生成 diff，必须人工确认
2. **`--apply` 才改文件**——改前备份 `.bak`（页面模式备份整个目录到 `.bak/`）
3. **自动项限制在 5 类**（标注/confirmLoading/popConfirm/_dictText/loading 状态）——其他项只给建议
4. **高风险项不自动改**（onMaterialChange / JMaterialSelect / MaterialSelectModal / 跨文件 query*Select 缺导出）——必须人工判断
5. **页面模式备份更宽**：备份整个 `<page-dir>` 到 `<page-dir>.bak/`，避免只改一个文件后破坏其他相关文件

## 示例

```
用户：/vue-migrate jeecgboot-vue3/src/views/project/mes/stock/other-out
AI  ：
  1. 跑 vue-audit.sh：PASS 17 / WARN 10 / FAIL 1
  2. 检测 4 项可自动改造（按页面聚合）：
     ├─ index.vue 缺 rowSelection（人工）
     ├─ Drawer.vue 缺 popConfirm（自动追加）
     ├─ data.ts 引用 queryWarehouseSelect 但 api.ts 缺（人工补导出）
     └─ api.ts 缺 @generated-from（自动追加）
  3. 生成跨文件聚合 diff（按文件分组）：
     ──── index.vue ────
     + import { ApiSelect } ...
     ...
  4. 询问：应用？(y/n/edit)
```

```
用户：/vue-migrate --all-list
AI  ：
  扫描 149 个页面（含 478 个相关文件）
  ✗ FAIL 页面：22
  列出 22 个 FAIL 页面的路径与 P/W/F 数字
  提示：建议优先处理 FAIL 数 ≥ 2 的页面（5 个）
```

## 与 /vue-audit 的关系

- `/vue-audit` = 只检测，输出报告
- `/vue-migrate` = 检测 + 生成 diff + 人工 review 后应用
- 日常：`/vue-audit --all` 找问题 → `/vue-migrate <page-dir>` 改整个页面（v2 推荐）→ 或 `/vue-migrate <file>` 改单个文件（v1 兼容）
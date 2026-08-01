---
description: 自有命令 — Vue 黄金模板 UX 基线审计：单文件 / 页面 / 全量三种粒度，按 frontend.md 逐项核对
---

# /vue-audit [文件|页面|--all] [--strict]

调用 `.claude/scripts/vue-audit.sh` 按黄金模板 UX 基线审计 Vue 页面。

## 三种粒度（v2 新增按页面粒度）

| 输入 | 粒度 | 说明 |
|---|---|---|
| `<file.vue>` | 单文件 | 单个 index.vue 或 *Drawer.vue（向后兼容） |
| `<page-dir>` | 页面 | 聚合 index.vue + Drawer.vue + data.ts + api.ts 一并审计 |
| `--all` | 全量 | 按页面枚举，输出"扫描 X 页面（含 Y 文件）" |

## 用法

```
# 单文件（向后兼容，pre-commit hook 使用）
/vue-audit jeecgboot-vue3/src/views/mes/receipt/index.vue
/vue-audit jeecgboot-vue3/src/views/mes/receipt/ReceiptDrawer.vue --strict

# 按页面（v2 新增，推荐用法）
/vue-audit jeecgboot-vue3/src/views/project/mes/stock/other-out

# 全量按页面（v2 重定义口径）
/vue-audit --all
/vue-audit --all --strict          # WARN 也算 FAIL
```

## 流程

### 1. 参数解析

- 单文件：`<file.vue>`（必须是 index.vue 或 *Drawer.vue，行为与 v1 一致）
- 页面：`<dir>`（含 index.vue 的页面目录，自动聚合同目录 4 类文件）
- 全量：`--all`（扫描 `jeecgboot-vue3/src/views` 下所有含 index.vue 的目录）
- 严格模式：`--strict`（WARN 也算 FAIL）

### 2. 页面识别规则（v2 新增）

```
<page-dir>/
  ├── index.vue                # 锚点（必含）
  ├── *Drawer.vue              # 抽屉页（可选）
  ├── *.data.ts                # schema（可选）
  ├── *.api.ts                 # 接口（首个，voucher 多 api 时取第一个）
  └── *SubTable.vue 等辅助组件  # 不纳入审计
```

**4 个守卫**：
- **G1 空目录**：目录无 .vue/.ts → 提示"无 Vue/TS 文件"
- **G2 简单页面**：只有 index.vue → 只跑通用检查（@generated-from + 字典翻译）
- **G3 多 api.ts**：提示"目录含 N 个 api.ts，仅审计第一个"
- **G4 子目录**：提示"子目录不会被审计（递归未启用）"

### 3. 调 vue-audit.sh

```bash
SCRIPT_DIR="$(git rev-parse --show-toplevel)/.claude/scripts"

# 单文件
$SCRIPT_DIR/vue-audit.sh <file.vue> [--strict]

# 按页面（v2 新增）
$SCRIPT_DIR/vue-audit.sh <page-dir> [--strict]

# 全量按页面（v2 重定义）
$SCRIPT_DIR/vue-audit.sh --all [--strict]
```

### 4. 输出格式

**单文件**（与 v1 一致）：
```
Vue UX 审计：.../OtherOutDrawer.vue
类型：抽屉页 (Drawer.vue)
  ✓ PASS  模板来源标注
  ⚠ WARN  提交 loading 状态 — 未检测到
  ...
汇总：PASS 8  WARN 5  FAIL 0
```

**页面聚合**（v2 新增）：
```
Vue 页面审计：.../stock/other-out
文件数：4

── index.vue ──
  ✓ PASS  模板来源标注
  ⚠ WARN  搜索栏字典下拉 — 未找到字典下拉组件
  ...

── OtherOutDrawer.vue ──
  ...

── otherOut.data.ts ──
  ✓ PASS  结构完整性
  ✗ FAIL  ApiSelect 引用缺失 — data.ts 引用但 api.ts 缺：queryWarehouseSelect

── otherOut.api.ts ──
  ⚠ WARN  模板来源标注 — 缺失 @generated-from

页面汇总：PASS 17  WARN 10  FAIL 1
```

**全量按页面**（v2 重定义）：
```
全量汇总：扫描 149 个页面（含 478 个相关文件）
  ✓ PASS 页面：127
  ⚠ WARN 页面：0
  ✗ FAIL 页面：22

FAIL 页面清单：
  .../batch/traceability  [P11/W15/F2]
  .../finance/collection  [P2/W12/F1]
  ...
```

### 5. 后续动作

- FAIL 文件 / 页面 → 推荐 `/vue-migrate <file>` 或 `/vue-migrate <page-dir>` 自动生成改造方案
- WARN 较多 → 提示"老页面建议批量 migrate"
- 全绿 → 报告"黄金模板 UX 合规"

## 审计基线

### 单文件（index.vue / Drawer.vue）— 14 项
- 列表页 4 项（字典下拉 / rowSelection / status 显隐 / 展开行）
- 抽屉页 7 项（编码获取 / JMaterialSelect / onMaterialChange / MaterialSelectModal / confirmLoading / Alert / loading 状态）
- 状态机 2 项（popConfirm / 审核确认）
- 展示值 3 项（_dictText / 禁止裸 ID / 红标）

### data.ts 轻量化 — 3 项
- 模板来源标注（@generated-from）
- 结构完整性（BasicColumn / FormSchema）
- **跨文件：ApiSelect 引用完整**（data.ts 引用的 query*Select 函数必须在 api.ts 中存在）

### api.ts 轻量化 — 2 项
- 模板来源标注（@generated-from）
- 标准下拉函数（query*Select 导出）

### 简单页面 — 2 项
- 模板来源标注
- 字典翻译展示（_dictText）

## 示例

```
用户：/vue-audit jeecgboot-vue3/src/views/project/mes/stock/other-out
AI  ：
  Vue 页面审计：.../stock/other-out
  文件数：4
  ── index.vue ──
    ✓ PASS  模板来源标注
    ⚠ WARN  搜索栏字典下拉 — 未找到字典下拉组件
    ...
  ── OtherOutDrawer.vue ──
    ...
  ── otherOut.data.ts ──
    ✗ FAIL  ApiSelect 引用缺失 — data.ts 引用但 api.ts 缺：queryWarehouseSelect
  ── otherOut.api.ts ──
    ⚠ WARN  模板来源标注 — 缺失 @generated-from
  页面汇总：PASS 17  WARN 10  FAIL 1

用户：/vue-audit --all
AI  ：
  扫描 149 个页面（含 478 个相关文件）
  ✓ PASS 页面：127
  ✗ FAIL 页面：22
  FAIL 页面清单：
    .../batch/traceability  [P11/W15/F2]
    .../stock/other-out  [P17/W10/F1]
    ...
```

## 向后兼容

- pre-vue-audit.sh hook 传单文件路径（`<file>.vue`）行为零变化
- 旧评审报告数字"扫描 X 文件"不再适用，新口径"扫描 X 页面（含 Y 文件）"
- 文件粒度数字仍可在单页面报告里逐文件核对
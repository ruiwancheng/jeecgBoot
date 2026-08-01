---
description: 自有命令 — Vue 黄金模板 UX 基线审计：单文件或全量扫描，按 frontend.md 逐项核对
---

# /vue-audit [文件|--all] [--strict]

调用 `.claude/scripts/vue-audit.sh` 按黄金模板 UX 基线审计 Vue 文件。

## 用法

```
/vue-audit jeecgboot-vue3/src/views/mes/receipt/index.vue
/vue-audit --all
/vue-audit --all --strict          # WARN 也算 FAIL
/vue-audit jeecgboot-vue3/src/views/mes/receipt/ReceiptDrawer.vue --strict
```

## 流程

### 1. 参数解析

- 单文件：`<path>`（必须是 index.vue 或 *Drawer.vue）
- 全量：`--all`（扫描 `jeecgboot-vue3/src` 下所有目标文件）
- 严格模式：`--strict`（WARN 也算 FAIL）

### 2. 调 vue-audit.sh

```bash
SCRIPT_DIR="$(git rev-parse --show-toplevel)/.claude/scripts"

# 单文件
$SCRIPT_DIR/vue-audit.sh <path> [--strict]

# 全量
find jeecgboot-vue3/src \( -name "index.vue" -o -name "*Drawer.vue" \) | \
  xargs -I{} $SCRIPT_DIR/vue-audit.sh {} --strict
```

### 3. 输出汇总

```
单文件：直接展示 PASS/WARN/FAIL 逐项
全量：
  - 总文件数 / PASS 数 / WARN 数 / FAIL 数
  - FAIL 文件清单（路径 + 失败项）
  - 退 1 让协调者知道
```

### 4. 后续动作

- FAIL 文件 → 推荐 `/vue-migrate <file>` 自动生成改造方案
- WARN 较多 → 提示"老页面建议批量 migrate"
- 全绿 → 报告"黄金模板 UX 合规"

## 审计基线

14 项检查（详见 `frontend.md` 单据页 UX 基线）：

- 列表页 4 项（字典下拉 / rowSelection / status 显隐 / 展开行）
- 抽屉页 7 项（编码获取 / JMaterialSelect / onMaterialChange / MaterialSelectModal / confirmLoading / Alert / loading 状态）
- 状态机 2 项（popConfirm / 审核确认）
- 展示值 3 项（_dictText / 禁止裸 ID / 红标）

## 示例

```
用户：/vue-audit jeecgboot-vue3/src/views/project/mes/batch/traceability/index.vue
AI  ：
  Vue UX 审计：traceability/index.vue
  ✓ PASS  模板来源标注
  ⚠ WARN  搜索栏字典下拉 — 未找到字典下拉组件
  ⚠ WARN  复选框（rowSelection）— 未配置
  ...
  汇总：PASS 3 / WARN 7 / FAIL 0

用户：/vue-audit --all
AI  ：
  扫描 218 文件
  ❌ FAIL 文件：12（BasicDrawer.vue / customer-demo/warehouse/* 等）
  ⚠ WARN 较多：206
  建议：老页面运行 /vue-migrate 批量优化
```
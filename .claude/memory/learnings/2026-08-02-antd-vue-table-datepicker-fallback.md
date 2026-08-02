---
name: antd-vue-table-datepicker-fallback
description: a-date-picker 在 a-table 内嵌时点击无反应——3 次修复失败后改用原生 input type=date
metadata:
  type: reference
---

# antd-vue 4 表格内嵌 a-date-picker 兼容性兜底

## 现象

ReceiptDrawer.vue 的 a-date-picker（生产日期/有效期至）在 `<a-table>` 内嵌时：
- 点击无反应（即使加了 getPopupContainer + null fallback + 完全回退都无效）
- 控制台报错：`Cannot read properties of null (reading 'parentNode')`

## 根因（未完全明确）

- antd-vue 4 + a-table 内嵌场景的兼容性 bug
- `getPopupContainer` 触发 `trigger.parentNode` 抛错（trigger=null 是 antd 内部行为）
- 即便删掉 `getPopupContainer`，仍点击无反应（用户实测确认）

## 3 次修复尝试（全部失败）

| # | commit | 改动 | 结果 |
|---|---|---|---|
| 1 | 6d3ed39 | 加 `:getPopupContainer="(trigger) => trigger.parentNode"` | ❌ TypeError |
| 2 | d356bbe | 加 null fallback `trigger?.parentNode` | ❌ 仍无反应 |
| 3 | d6f56e4 | 完全删除 getPopupContainer | ❌ 仍无反应 |

## 架构兜底方案

**用原生 `<input type="date">` 替代 a-date-picker**（commit 5a142cb）：

```vue
<input
  type="date"
  :value="record.productionDate || ''"
  style="width: 100%; height: 24px; padding: 0 4px; border: 1px solid #d9d9d9; border-radius: 2px"
  @change="(e: any) => onProductionDateChange(index, e.target.value)"
/>
```

**优势**：
- 字符串值直接兼容（YYYY-MM-DD）
- 跨浏览器一致
- 零 antd-vue 依赖，避开 bug
- 视觉一致（手写 style 模拟 a-date-picker 边框）

**劣势**：
- 无快捷日期选择（今天/昨天/一周内）
- 视觉与 antd-vue 不完全一致
- 不同浏览器外观略不同

## 适用判断

- **主表 form**：用 a-date-picker（功能完整）
- **子表内嵌 a-table 单元格**：用 `<input type="date">` 兜底
- 任何 antd 控件在 `<a-table>` 内嵌点击无反应时，立即降级到原生控件

## 关联
- commit: 5a142cb（兜底修复）
- debug 流程：3 次即停 → 质疑架构 → 降级方案
- /debug 命令："同一修复 3 次还失败 → 停止，质疑架构"

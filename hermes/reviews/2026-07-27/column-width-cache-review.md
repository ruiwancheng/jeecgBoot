# 列宽缓存持久化 — 草案评审

**评审日期**：2026-07-27  
**评审人**：Claude Opus 4.8（派发任务 task_3e925cbdac36）  
**涉及文件**（草案路径）：  
- `jeecgboot-vue3/src/components/Table/src/hooks/useColumnsCache.ts`（修改）  
- `jeecgboot-vue3/src/components/Table/src/BasicTable.vue`（修改）

---

## 总体评估

草案方向正确，可行性高。现有 `useColumnsCache` + `createLocalStorage` 基础设施已完备，列宽缓存的工程量小（估约 40-60 行净增）。

1 个阻塞问题（#1 宽度恢复被跳过），2 个重要问题（#2 身份标识不一致，#3 cacheKey 可达性），其余为小问题。全部可修，无架构风险。

---

## 评审问题逐项回答

### Q1：是否有遗漏（JVxeTable 等）？

**结论：JVxeTable 不需要。** JVxeTable（`src/components/jeecg/JVxeTable/`）使用 vxe-table，有自己独立的列拖动机制，不消费 `@resizeColumn` 事件，也不使用 `useColumnsCache`。该组件搜索无 `handleResizeColumn`/`resizeColumn`/column width cache 相关代码。

但需注意：如果将来 JVxeTable 也需要列宽记忆，需在 `JVxeTable` 组件内独立实现，不能复用 `useColumnsCache`（不同缓存 key 体系）。

**columns 的 flag vs dataIndex 区分**：现有 `useColumns.ts` 中 `canColDrag` 逻辑已排除 `flag` 列（`!(item.flag)` 才设 `resizable=true`），所以 INDEX/ACTION/CHECKBOX/RADIO 列根本不会触发 `resizeColumn` 事件。宽度缓存键只需用 `column.key || column.dataIndex` 即可，无需考虑 flag。

### Q2：宽度缓存与现有列显隐缓存的耦合是否合理？

**合理，但有注意事项。**

复用同一个 `cacheKey`（`columnCache:` + route path）和同一个 localStorage 对象是正确的——宽度和显隐/排序/固定都是"此路由下此表格的列配置"，本就是一体。

**但需注意两件事**：

1. **读写粒度不同**：显隐/排序是用户点"保存"才持久化；宽度如果每次拖动都写 localStorage，频率高得多。不过 `handleResizeColumn` 是拖动完成时触发（非拖动中），频率可控，不会造成性能问题。

2. **写入竞争**：`saveSetting()`（用户点保存）和 `handleResizeColumn` 中的自动保存都会写同一个 cacheKey。由于 JS 单线程，不会出现竞态，但两者保存的 `columnWidths` 数据源必须一致——都从 `getColumns()` 的当前 `width` 快照来。如果 `saveTableColumnWidths` 只写 `columnWidths` 字段（做 read-modify-write），而 `saveSetting()` 写整个对象，后者可能覆盖前者刚写入的宽度。**建议**：`handleResizeColumn` 中的自动保存应当只更新缓存中的 `columnWidths` 字段（读取现有缓存 → 更新 `columnWidths` → 写回），而不是覆盖整个缓存。

### Q3：边界情况

已识别以下边界，逐条给出处理建议：

| 边界 | 风险 | 处理 |
|------|:--:|------|
| **缓存有 `columnWidths` 但无 `checkedList`**（用户只拖过列但从未保存过配置） | 🔴 **阻塞** — `init()` 第一行就 `if (columnCache && columnCache.checkedList)` 跳过了所有恢复逻辑，宽度无法恢复 | 将宽度恢复移到 `checkedList` 判断之外，或在 `init()` 末尾加独立分支 |
| **列定义无 `width`，用户拖动后才生成宽度** | 🟡 低 — `handleResizeColumn` 里已经 `findItem.width = w`，auto-save 后缓存有此宽度。下次加载时从缓存恢复即可，不依赖列定义 | 无需特殊处理 |
| **列定义有默认 `width`，用户未拖动过** | 🟢 无 — 缓存中无此列宽度记录，使用列定义默认值。正确 | 无需特殊处理 |
| **开发者在版本间新增/删除列，旧缓存残留无关宽度** | 🟢 无 — 恢复时遍历 columns 逐个匹配 dataIndex，缓存中的孤儿条目自然被忽略 | 无需特殊处理 |
| **`saveSetting()` 全量写入时覆盖了 `handleResizeColumn` 刚 auto-save 的宽度** | 🟡 中 — 只要两者的数据源（`getColumns()` 当前 width）一致，写入的值就一致。不一致的唯一场景是 `saveTableColumnWidths` 只写单个列但 `saveSetting` 写全量时该列还未更新 | `saveSetting()` 中的 `columnWidths` 也从 `getColumns()` 快照取；`handleResizeColumn` 中 `setColumns(columns)` 后再 auto-save |
| **加密 localStorage 对列宽的适用性** | 🟢 无 — `createLocalStorage` 内置 AES 加密，列宽数据量极小（几十 KB），无性能问题 | 无需特殊处理 |

---

## 阻塞问题（需先解决再动手）

### 🔴 P0 #1：`init()` 宽度恢复被跳过

**现状**：
```typescript
async function init() {
  if (isInit) return;
  isInit = true;
  let columnCache = $ls.get(cacheKey.value);
  if (columnCache && columnCache.checkedList) {   // ← 门控条件
    // 恢复 checkedList, sortedList, fixedColumns...
  }
  // 如果 checkedList 为空 → 整段跳过 → 宽度也丢了
}
```

**场景**：用户打开表格 → 拖动某列宽度（auto-save 写入 `{ columnWidths: { xx: 200 } }`）→ 关闭页面 → 重新打开。此时缓存有 `columnWidths` 但没有 `checkedList`（用户从未打开列配置面板点保存），`init()` 的 `if (columnCache && columnCache.checkedList)` 为 false → 宽度不恢复。

**修复方向**（二选一）：

- **方案 A（推荐）**：在 `init()` 末尾加独立分支：
  ```typescript
  // 恢复列宽（独立于 checkedList，因为可能仅拖动过列从未保存过配置）
  if (columnCache?.columnWidths) {
    const columns = table.getColumns();
    for (const col of columns) {
      const key = col.key || col.dataIndex;
      if (key && columnCache.columnWidths[key] != null) {
        col.width = columnCache.columnWidths[key];
      }
    }
    table.setColumns(columns);
  }
  ```

- **方案 B**：首次 auto-save 时同时写入 `columnWidths` + `checkedList` 默认值（更复杂，不推荐）。

**建议用方案 A**。原因：宽度恢复和显隐恢复是正交操作，不应互相依赖。

---

### 🟡 P1 #2：列身份标识不一致

**现状对比**：

| 位置 | 列身份标识 |
|------|----------|
| `getFixedColumns()` | `column.key \|\| column.dataIndex` |
| `setColumnFixed()` | `fc.key` 匹配 `column.key \|\| column.dataIndex` |
| `handleResizeColumn` | `item['dataIndex']` → 失败时才 fallback `item['flag']` |
| 草案 `columnWidths` | `dataIndex` 作为 key |

**问题**：`handleResizeColumn` 中 col 对象来自 ant-design-vue 内部，其 `dataIndex` 可能已被 `useColumns.ts` 中 `handleItem` 处理过（`item.key = dataIndex` 当 key 为空时）。而某些自定义列可能 `key !== dataIndex`（如 `CUS_SEL_COLUMN_KEY`）。草案只用 `dataIndex` 作为缓存键与现有 `handleResizeColumn` 的匹配逻辑不一致。

**修复**：宽度缓存的 key 统一用 `column.key || column.dataIndex`，与 `getFixedColumns`/`setColumnFixed` 保持一致：
```typescript
const widthKey = col.key || col.dataIndex;
```

---

### 🟡 P1 #3：`cacheKey` 在 `BasicTable.vue` 中不可达

**问题**：草案要求在 `handleResizeColumn` 中调用 `saveTableColumnWidths(cacheKey, columns)`，但 `cacheKey` 是在 `useColumnsCache` 内部通过 `computed(() => {...})` 生成的，`BasicTable.vue` 的 `setup()` 中拿不到这个值。

**三个解决方案**：

| 方案 | 做法 | 优点 | 缺点 |
|------|------|------|------|
| A | 把 `cacheKey` 计算逻辑抽成独立工具函数，在 `useColumnsCache.ts` 中 export，`BasicTable.vue` 中导入使用 | 最小改动，不破坏现有结构 | `BasicTable.vue` 需访问 `route.path`（已可用）和 `table.getBindValues`（需通过 context） |
| B | 让 `useColumnsCache` 返回一个新方法 `saveColumnWidth(columns)`，内部自动用 cacheKey | 封装好，调用方不关心 key | 需要把 `useColumnsCache` 的返回值传到 `BasicTable.vue` setup——但当前 `useColumnsCache` 只在 `ColumnSetting.vue` 中被调用 |
| C | 扩展 `tableAction` 增加 `saveColumnWidth` 方法，通过 `createTableContext` provide | 最大封装 | 跨层传递重 |

**推荐方案 A（抽工具函数）**：

```typescript
// useColumnsCache.ts 顶部导出
import { createLocalStorage } from '/@/utils/cache';

export function computeColumnCacheKey(routePath: string, cacheKeySuffix?: string): string {
  let key = routePath.replace(/[\/\\]/g, '_');
  if (cacheKeySuffix) {
    key += ':' + cacheKeySuffix;
  }
  return 'columnCache:' + key;
}

export function saveTableColumnWidths(
  cacheKey: string,
  columns: Array<{ key?: string; dataIndex?: string; flag?: string; width?: number }>
) {
  const $ls = createLocalStorage();
  const cache = $ls.get(cacheKey) || {};
  const columnWidths: Record<string, number> = { ...(cache.columnWidths || {}) };
  for (const col of columns) {
    if (col.flag) continue; // 跳过 INDEX/ACTION 等标记列
    const key = col.key || col.dataIndex;
    if (key && col.width != null) {
      columnWidths[key] = col.width;
    }
  }
  cache.columnWidths = columnWidths;
  $ls.set(cacheKey, cache);
}
```

然后在 `BasicTable.vue` 的 `handleResizeColumn` 中：

```typescript
import { computeColumnCacheKey, saveTableColumnWidths } from './hooks/useColumnsCache';
import { useRoute } from 'vue-router';

// 在 setup 中
const route = useRoute();

handleResizeColumn: (w, col) => {
  const columns = getColumns();
  const findItem = columns.find((item) => {
    if (item['dataIndex'] != null) return item['dataIndex'] === col['dataIndex'];
    else if (item['flag'] != null) return item['flag'] === col['flag'];
    return false;
  });
  if (findItem) {
    findItem.width = w;
    setColumns(columns);
  }
  col.width = w;
  // ★ 新增：自动保存列宽
  const cacheKey = computeColumnCacheKey(
    route.path,
    table.getBindValues.value.tableSetting?.cacheKey
  );
  saveTableColumnWidths(cacheKey, columns);
},
```

---

### 🟢 P2 #4：`saveSetting()` / `resetSetting()` 中的宽度集成

现有 `saveSetting()`：
```typescript
$ls.set(cacheKey.value, {
  checkedList,
  sortedList,
  checkIndex: unref(opt.checkIndex),
  sortableOrder: unref(opt.sortableOrder),
  fixedColumns: getFixedColumns(),
});
```

**建议修改**：增加 `columnWidths` 字段（参考 `getFixedColumns()` 的模式）：

```typescript
function getColumnWidths() {
  const widths: Record<string, number> = {};
  const columns = opt.plainOptions.value;
  for (const column of columns) {
    if (column.flag) continue;
    const key = column.key || column.dataIndex;
    if (key && column.width != null) {
      widths[key] = column.width;
    }
  }
  return widths;
}
```

然后在 `$ls.set()` 中加入：
```typescript
columnWidths: getColumnWidths(),
```

**`resetSetting()`**：已执行 `$ls.remove(cacheKey.value)`，会自动清除宽度。无需额外工作。但需确认：reset 时宽度是否也应重置到列定义的默认值？如果需要，`resetSetting()` 还应遍历 columns 把 `width` 重置为 `cacheColumns` 的原始 width。不过这属于增强特性，当前草案不要求。（草案中说"resetSetting 中清除宽度"，`$ls.remove` 已满足。）

---

### 🟢 P2 #5：init() 中宽度恢复的时机

**时机必须在 `setColumns()` 之后**。当前 `init()` 流程：

```
读缓存 → setColumns(checkedList) → setColumnFixed → 结束
```

宽度恢复应在 `setColumns` + `setColumnFixed` 之后（甚至可以在 `setColumnFixed` 之前，因为宽度与固定无关），但**不能在 `setColumns` 之前**（那时 columns 可能还未就绪）。

建议在 `init()` 末尾（`setColumnFixed` 调用之后）加宽度恢复分支。

---

## 数据结构设计（终稿建议）

```typescript
// localStorage key: 'columnCache:' + routePath (+ ':customSuffix')

interface ColumnCacheData {
  // 已有字段
  checkedList: string[];
  sortedList: string[];
  sortableOrder: string[];
  checkIndex: boolean;
  fixedColumns: { key: string; fixed: 'left' | 'right' | boolean }[];
  
  // 新增字段
  columnWidths: Record<string, number>;  // key = column.key || column.dataIndex, value = px
}
```

---

## 变更影响面

| 文件 | 改动性质 | 影响范围 |
|------|---------|---------|
| `useColumnsCache.ts` | 新增 2 个导出函数 + `saveSetting`/`init` 内嵌宽度逻辑 | 仅影响使用 `useColumnsCache` 的 `ColumnSetting.vue` |
| `BasicTable.vue` | `handleResizeColumn` 追加 1 次函数调用 | 仅影响拖动列宽的用户操作 |

两个文件的改动都是增量、向后兼容的。不影响现有显隐/排序/固定缓存功能。

---

## 不改的范围（明确 Exclude）

- **JVxeTable**：使用 vxe-table，无 `@resizeColumn` 事件，列宽记忆需独立实现（如需）
- **`columnCache` 的过期策略**：沿用 `createLocalStorage` 的 7 天过期（`DEFAULT_CACHE_TIME = 60*60*24*7`），不改
- **加密**：沿用 `createLocalStorage` 的 AES 加密，不改
- **宽度重置到列定义默认值**（reset 时）：属增强特性，本次不要求

---

## 实现顺序建议

1. **useColumnsCache.ts**：抽 `computeColumnCacheKey` 工具函数 + 实现 `saveTableColumnWidths`
2. **useColumnsCache.ts**：`saveSetting()` 增加 `columnWidths` 写入
3. **useColumnsCache.ts**：`init()` 末尾增加宽度恢复（独立分支，不依赖 `checkedList`）
4. **BasicTable.vue**：`handleResizeColumn` 末尾调用 `saveTableColumnWidths`
5. **验证**：调列宽 → 刷新 → 确认宽度保持；不保存配置 → 刷新 → 确认宽度仍保持（验证 #1 修复）
6. **验证**：点"重置" → 确认宽度被清除，列回到列定义默认宽度

---

*评审完成。5 个问题全部识别，其中 1 个阻塞、2 个重要、2 个轻微。建议先修 #1-#3 再动手写码。*

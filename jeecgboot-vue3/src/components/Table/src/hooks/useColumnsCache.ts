import { computed, nextTick, unref, watchEffect } from 'vue';
import { router } from '/@/router';
import { useRoute } from 'vue-router';
import { createLocalStorage } from '/@/utils/cache';
import { useTableContext } from './useTableContext';
import { useMessage } from '/@/hooks/web/useMessage';

// update-begin---author:ruiwancheng ---date:2026-07-27  for：列宽拖动记忆—工具函数
/**
 * 计算列配置缓存 key
 */
export function computeColumnCacheKey(routePath: string, cacheKeySuffix?: string): string {
  let key = routePath.replace(/[\/\\]/g, '_');
  if (cacheKeySuffix) {
    key += ':' + cacheKeySuffix;
  }
  return 'columnCache:' + key;
}

/**
 * 保存列宽到缓存
 */
export function saveTableColumnWidths(
  cacheKey: string,
  columns: Array<{ key?: string; dataIndex?: string; flag?: string; width?: number }>
) {
  const $ls = createLocalStorage();
  const cache = $ls.get(cacheKey) || {};
  const columnWidths: Record<string, number> = { ...(cache.columnWidths || {}) };
  for (const col of columns) {
    if (col.flag) continue;
    const key = col.key || col.dataIndex;
    if (key && col.width != null) {
      columnWidths[key] = col.width;
    }
  }
  cache.columnWidths = columnWidths;
  $ls.set(cacheKey, cache);
}

/**
 * 读取列宽缓存
 */
export function getTableColumnWidths(cacheKey: string): Record<string, number> | null {
  const $ls = createLocalStorage();
  const cache = $ls.get(cacheKey);
  return cache?.columnWidths || null;
}
// update-end---author:ruiwancheng ---date:2026-07-27  for：列宽拖动记忆—工具函数

/**
 * 列表配置缓存
 */
export function useColumnsCache(opt, setColumns, handleColumnFixed) {
  let isInit = false;
  const table = useTableContext();
  const $ls = createLocalStorage();
  const { createMessage: $message } = useMessage();
  const route = useRoute();
  // 列表配置缓存key
  const cacheKey = computed(() => {
    // 代码逻辑说明: 【QQYUN-8367】online报表配置列展示保存，影响到其他页面的table字段的显示隐藏（开发环境热更新会有此问题，生产环境无问题）
    const path = route.path;
    let key = path.replace(/[\/\\]/g, '_');
    let cacheKey = table.getBindValues.value.tableSetting?.cacheKey;
    if (cacheKey) {
      key += ':' + cacheKey;
    }
    return 'columnCache:' + key;
  });

  watchEffect(() => {
    const columns = table.getColumns();
    if (columns.length) {
      init();
    }
  });

  async function init() {
    if (isInit) {
      return;
    }
    isInit = true;
    let columnCache = $ls.get(cacheKey.value);
    if (columnCache && columnCache.checkedList) {
      const { checkedList, sortedList, sortableOrder, checkIndex } = columnCache;
      await nextTick();
      // checkbox的排序缓存
      opt.sortableOrder.value = sortableOrder;
      // checkbox的选中缓存
      opt.state.checkedList = checkedList;
      // tableColumn的排序缓存
      opt.plainSortOptions.value.sort((prev, next) => {
        return sortedList.indexOf(prev.value) - sortedList.indexOf(next.value);
      });
      // 重新排序tableColumn
      checkedList.sort((prev, next) => sortedList.indexOf(prev) - sortedList.indexOf(next));
      // 是否显示行号列
      if (checkIndex) {
        table.setProps({ showIndexColumn: true });
      }
      setColumns(checkedList);
      // 设置固定列
      setColumnFixed(columnCache);
    }
    // update-begin---author:ruiwancheng ---date:2026-07-27  for：列宽拖动记忆—init恢复宽度（独立于checkedList，仅拖动过列宽也会恢复）
    if (columnCache?.columnWidths) {
      await nextTick();
      const columns = table.getColumns();
      for (const col of columns) {
        if (col.flag) continue;
        const key = col.key || col.dataIndex;
        if (key && columnCache.columnWidths[key] != null) {
          col.width = columnCache.columnWidths[key];
        }
      }
      table.setColumns(columns);
    }
    // update-end---author:ruiwancheng ---date:2026-07-27  for：列宽拖动记忆—init恢复宽度（独立于checkedList，仅拖动过列宽也会恢复）
  }

  /** 设置被固定的列 */
  async function setColumnFixed(columnCache) {
    const { fixedColumns } = columnCache;
    const columns = opt.plainOptions.value;
    for (const column of columns) {
      let fixedCol = fixedColumns.find((fc) => fc.key === (column.key || column.dataIndex));
      if (fixedCol) {
        await nextTick();
        handleColumnFixed(column, fixedCol.fixed);
      }
    }
  }

  // 判断列固定状态
  const fixedReg = /^(true|left|right)$/;

  /** 获取被固定的列 */
  function getFixedColumns() {
    let fixedColumns: any[] = [];
    const columns = opt.plainOptions.value;
    for (const column of columns) {
      if (fixedReg.test((column.fixed ?? '').toString())) {
        fixedColumns.push({
          key: column.key || column.dataIndex,
          fixed: column.fixed === true ? 'left' : column.fixed,
        });
      }
    }
    return fixedColumns;
  }

  // update-begin---author:ruiwancheng ---date:2026-07-27  for：列宽拖动记忆—saveSetting中追加宽度字段
  /** 获取列宽映射 */
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
  // update-end---author:ruiwancheng ---date:2026-07-27  for：列宽拖动记忆—saveSetting中追加宽度字段

  /** 保存列配置 */
  function saveSetting() {
    const { checkedList } = opt.state;
    // 代码逻辑说明: 【TV360X-105】列展示设置问题[重置之后保存的顺序还是上次的]
    let sortedList = [];
    if (opt.restAfterOptions.value) {
      sortedList = opt.restAfterOptions.value.map((item) => item.value);
    } else {
      sortedList = unref(opt.plainSortOptions).map((item) => item.value);
    }
    // update-begin---author:ruiwancheng ---date:2026-07-27  for：列宽拖动记忆—追加columnWidths到缓存
    $ls.set(cacheKey.value, {
      // 保存的列
      checkedList,
      // 排序后的列
      sortedList,
      // 是否显示行号列
      checkIndex: unref(opt.checkIndex),
      // checkbox原始排序
      sortableOrder: unref(opt.sortableOrder),
      // 固定列
      fixedColumns: getFixedColumns(),
      // 列宽
      columnWidths: getColumnWidths(),
    });
    // update-end---author:ruiwancheng ---date:2026-07-27  for：列宽拖动记忆—追加columnWidths到缓存
    $message.success('保存成功');
    // 保存之后直接关闭
    opt.popoverVisible.value = false;
  }

  /** 重置（删除）列配置 */
  async function resetSetting() {
    // 重置固定列
    await resetFixedColumn();
    $ls.remove(cacheKey.value);
    $message.success('重置成功');
  }

  async function resetFixedColumn() {
    const columns = opt.plainOptions.value;
    for (const column of columns) {
      column.fixed;
      if (fixedReg.test((column.fixed ?? '').toString())) {
        await nextTick();
        handleColumnFixed(column, null);
      }
    }
  }

  return {
    saveSetting,
    resetSetting,
    getCache: () => $ls.get(cacheKey.value),
  };
}

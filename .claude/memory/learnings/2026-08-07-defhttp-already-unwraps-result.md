# defHttp 已剥响应包装（不要再 .result 二次解包）(2026-08-07)

## 现象

Drawer / 列表组件拿到 API 响应后做 `resp.result.records` / `resp.result` 取值，结果全部 `undefined`，UI 显示空但网络请求 200 + 完整数据。

## 根因

`jeecgboot-vue3/src/utils/http/axios/index.ts:64` 的 `transformRequestHook`：

```ts
if (hasSuccess) {
  return result;  // ← 关键：剥掉外层 {success, code, result, message}，只返回 result 内容
}
```

所以 `defHttp.get({ url: '/xxx/list' })`：
- 后端响应：`{success:true, code:200, result:{records:[...], total:1, ...}}`
- defHttp 返回：`{records:[...], total:1, ...}` ← **已经是 result 内容了**

调用方若再 `.result` 一次 → undefined。

## 触发条件

任何使用 `defHttp.get/post/put/delete` 的代码 + 响应包含 `result` 字段（JeecgBoot 标准 list 端点）。

## 错误 vs 正确写法

| 端点 | 响应 | 错误 | 正确 |
|------|------|------|------|
| `GET /list` | `{result: {records: [...]}}` | `resp.result.records` | `resp.records` |
| `GET /listByBatchId` | `{result: [...]}` | `resp.result` | `resp` |

## 复现实例（2026-08-07 批次追溯 Drawer bug）

```ts
// 旧代码（错）：
const batchResp = await queryBatchList({ id, pageSize: 1 });
if (batchResp?.result?.records?.length) { ... }       // batchResp.result = undefined
const ledgerResp = await listLedgerByBatchId({ batchId });
ledgerItems.value = ledgerResp?.result || [];          // ledgerResp.result = undefined → []
// 现象：title="批次追溯："（无 batchNo）+ 列表"暂无流水"，但 API 正常返回

// 修复后：
if (batchResp?.records?.length) { ... }
ledgerItems.value = Array.isArray(ledgerResp) ? ledgerResp : [];
```

## 检测方法

1. Playwright `page.on('response')` 看响应 body，确认 API 返回完整数据
2. 浏览器 console.log 看响应对象的 keys，确认没有 `result` 外层
3. `resp && 'result' in resp` → 大概率是漏了 defHttp 剥包装认知

## 影响面

JeecgBoot Vue3 所有自定义 Drawer / 详情 / 跨模块取值。**优先级高**，因为这种 bug 在 Network 监控看不到（200 OK），只在 UI 表现出来，易漏检。

## 关联修复

commit `cd91062` — `fix(batch-traceability): Drawer 解析 defHttp 已剥包装的响应`
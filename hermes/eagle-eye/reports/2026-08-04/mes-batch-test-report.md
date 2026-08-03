# MES Batch 模块回归测试报告

**日期**：2026-08-04
**模块**：batch（批次管理）
**Controller 数**：4
**测试类型**：API + E2E + 前端类型

## 一、测试概况

| 指标 | 数值 |
|---|---:|
| API 测试用例（traceability + manual-e2e + global-switch）| 51 |
| 通过 | 51 |
| 失败 | 0（+ global-switch 数据缺失 1）|
| E2E 测试（traceabilityBatch + materialBatch）| 8 |
| 通过 | 4 |
| 失败 | 4 |
| 前端 TS 错误 | 2（BatchMasterDrawer）|

## 二、API 测试详情

| 测试 | 结果 | 备注 |
|---|---|:-:|
| traceability-batch-level.test.js | 42/42 ✅ | V10.0.3 批次级列表，R002/R003/R005 全覆盖 |
| batch-manual-e2e.test.js | 9/9 ✅ | 手工批次号创建 |
| batch-global-switch.test.js | 0/1 ⚠️ | 数据缺失（找不到 status=4 采购订单）|

## 三、E2E 失败明细

### P2 — UI 异常

| # | 测试 | 错误 |
|---|---|---|
| 1 | materialBatch.spec.ts | 总开关开启时物料表单 batchEnabled 可编辑测试失败 |
| 2 | traceabilityBatch.spec.ts #4 | drawer 显示"暂无流水"（V10.0.3 已知问题）|

**traceability #4 详情**（之前 /test-all 已识别）：
- 抽屉标题 = "批次追溯："（batchNo 为空）
- 流水表区域显示"暂无数据 / 该批次暂无流水"
- 后端 API `listByBatchId` 实际返回 1 条流水（PR20260802-0006）
- **疑点**：TraceabilityDrawer.vue 的 `queryBatchList` 调用导致 `batch=null`，主档不渲染 + `listLedgerByBatchId` 可能也未成功赋值

## 四、前端 TS 错误（2 个 — P1）

### BatchMasterDrawer.vue

```
error TS2353: Object literal may only specify known properties, and 'onValuesChange' does not exist in type 'Partial<DynamicProps<FormProps>>'
error TS2554: Expected 1 arguments, but got 2
```

**位置**：
- `BatchMasterDrawer.vue:52` — `onValuesChange` 字段
- `BatchMasterDrawer.vue:132` — `useForm` 调用参数

**影响**：批次主档抽屉（新增/编辑批次时使用）

## 五、明早优先排查

1. **🟡 P2-1**: materialBatch E2E — 看截图判断
2. **🟡 P2-2**: traceability 抽屉问题（V10.0.3 遗留）
3. **🟠 P1-前端**: BatchMasterDrawer 类型修复

## 六、原始日志

`hermes/eagle-eye/state/api-logs/traceability-batch-level.log`
`hermes/eagle-eye/state/api-logs/batch-manual-e2e.log`
`hermes/eagle-eye/state/api-logs/batch-global-switch.log`
`hermes/eagle-eye/state/e2e-20260804.log`（grep batch/materialBatch/traceabilityBatch）
`hermes/eagle-eye/state/typecheck-20260804.log`（grep BatchMasterDrawer）
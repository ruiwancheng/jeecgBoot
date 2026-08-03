# MES 前端检查报告

**日期**：2026-08-04
**类型**：TypeScript 类型检查 + Vite 构建

## 一、测试概况

| 检查项 | 结果 |
|---|---|
| vue-tsc --noEmit | ❌ **742 个错误** |
| pnpm build | ✅ **成功**（dist/ 已生成） |

**结论**：Vite build 跳过类型检查直接编译，所以即使 vue-tsc 报错，build 仍能成功。但**类型错误是真实存在的代码问题**，应当修复。

## 二、TS 错误分布

| 模块 | 错误数 | 说明 |
|---|---:|---|
| src/views/super/ | 141 | 超管/RAG（基座代码）|
| src/views/demo/ | 102 | 示例代码（基座）|
| src/views/system/ | 34 | 用户/用户组/租户 |
| **src/views/project/** | **30** | **MES 项目** |
| src/views/monitor/ | 26 | 监控 |
| src/views/sys/ | 16 | 系统 |
| src/views/dashboard/ | 13 | 仪表盘 |
| src/views/openapi/ | 5 | 接口 |
| src/views/report/ | 2 | 报表 |
| tests/eagle-eye/mocks/ | 多 | 测试 mock |

## 三、MES 项目（30 个错误）按文件分布

| 文件 | 错误数 | 主要错误 |
|---|---:|---|
| `src/views/project/mes/finance/collection/collection.data.ts` | 2 | dictTable/dictCode 类型不支持 |
| `src/views/project/mes/finance/invoice/invoice.data.ts` | 3 | 同上 |
| `src/views/project/mes/finance/payable/payable.data.ts` | 2 | 同上 |
| `src/views/project/mes/finance/payment/payment.data.ts` | 2 | 同上 |
| `src/views/project/mes/finance/purchaseInvoice/purchaseInvoice.data.ts` | 3 | 同上 |
| `src/views/project/mes/finance/receivable/receivable.data.ts` | 2 | 同上 |
| `src/views/project/mes/finance/subject/subject.data.ts` | 2 | 同上 |
| `src/views/project/mes/basic/location/location.data.ts` | 1 | FormSchema 不支持 'help' 属性 |
| `src/views/project/mes/basic/material/MaterialSelectModal.vue` | 1 | TableRowSelection 导入错误 |
| `src/views/project/mes/batch/master/BatchMasterDrawer.vue` | 2 | onValuesChange 类型 + 参数个数 |

## 四、P1 — 优先修复

### P1-1: finance 8 个 `.data.ts` 反模式

**问题**：8 个文件都用了 `dictTable` / `dictCode` 字段，但 `BasicColumn` 类型不支持。
**示例**（collection.data.ts）：
```typescript
{ title: '客户', dataIndex: 'customerId', width: 120, dictTable: '...', dictCode: '...' }
```
**TS 报错**：
```
error TS2561: Object literal may only specify known properties, but 'dictTable' does not exist in type 'BasicColumn'
error TS2353: Object literal may only specify known properties, and 'dictCode' does not exist in type 'BasicColumn'
```
**修复方向**：
- 选项 A：把这些字段移除（如果运行时不需要），或改用 `customRender`
- 选项 B：扩展 `BasicColumn` 类型定义添加这两个字段
- 选项 C：检查是否旧版 vxe-table / jeecg 模板有这种用法，新版已被废弃

### P1-2: BatchMasterDrawer 类型错误

**问题**：
```
error TS2353: Object literal may only specify known properties, and 'onValuesChange' does not exist in type 'Partial<DynamicProps<FormProps>>'
error TS2554: Expected 1 arguments, but got 2
```
**修复方向**：
- 检查 ant-design-vue 的 `FormProps` 是否在新版移除了 `onValuesChange`
- 调用点（132行）参数个数需要重新适配

## 五、P3 — 测试 mock 错误

`tests/eagle-eye/mocks/handlers/warehouse.ts` — WarehouseRecord 类型缺失字段（code/name/status）。这是测试 mock，不影响生产。

## 六、明早修复顺序

1. **先确认** BasicColumn 是否支持 dictCode/dictTable（新基座可能废弃）
2. **批量修改** finance 8 个文件
3. **修复** BatchMasterDrawer（影响批次主档抽屉）
4. **再跑** vue-tsc 验证降至 0 错误

## 七、原始日志

`hermes/eagle-eye/state/typecheck-20260804.log` (742 错误完整列表)
`hermes/eagle-eye/state/build-20260804.log` (build 成功详情)
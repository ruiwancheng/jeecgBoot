# MES 基础模块必须补全标准 `queryXxxSelect` 下拉函数

**场景**：新建基础模块（如 `material.api.ts`），只补全 CRUD 函数（query/list/add/edit/delete），没补标准下拉函数 `queryXxxSelect`。结果下游业务模块（如 `master.data.ts`、`inventory.data.ts`）用 `ApiSelect` 引用物料下拉时，控制台报错 `SyntaxError: The requested module '...material.api.ts' does not provide an export named 'queryMaterialSelect'`。批次主档菜单打不开。

**根因**：
- 整个 MES 项目都遵循 `async function queryXxxSelect(params?: any)` 命名模式（替代平台字典 `c_mes_xxx`，给 `ApiSelect` 组件专用）
- customer/warehouse/supplier/subject **都有** `queryXxxSelect` 函数（详见 `customer.api.ts:73`、`warehouse.api.ts:32`、`finance/subject/subject.api.ts:15`、`purchase/apply/apply.api.ts:31`）
- 唯独 material **漏了**——但下游 `master.data.ts` 和 `inventory.data.ts` 已经按惯例引用，导致前端编译失败
- 推测原因：material api.ts 创建时只关注了 CRUD，**没有按"customer 标准模板"完整复制**

**正确处理**：

```typescript
// 在 xxx.api.ts 中（selectMaterialPage 之后）追加：
/** 下拉选择（ApiSelect专用，替代平台字典 c_mes_xxx） */
export async function queryXxxSelect(params?: any) {
  const res = await defHttp.get({ url: Api.selectPage, params });
  return res || [];
}
```

**关键点**：
- 函数名必须 `queryXxxSelect`（Xxx 是实体名 PascalCase，如 `Material`、`Customer`、`Warehouse`）
- 必须 `async function`（箭头函数不行——其他模块都是 `async function` 声明）
- 参数 `params?: any`（可选，ApiSelect 会传 `keyword`/`pageNo`/`pageSize`）
- 必须 `return res || []`（兜底空数组，避免 ApiSelect 拿到 undefined 报错）
- 调用 `Api.selectPage`（已在 enum 中定义：`selectPage = '/mes/basic/xxx/selectPage'`）
- 后端必须有对应的 `@GetMapping("/selectPage")` 接口（参考 `MesMaterialController.selectPage`）

**完整对照表**（必须保持一致）：

| 实体 | 函数名 | 后端接口 | 前端导出位置 |
|------|--------|---------|------------|
| 客户 | `queryCustomerSelect` | `/mes/customer/selectPage` | `basic/customer/customer.api.ts:73` |
| 仓库 | `queryWarehouseSelect` | `/mes/basic/warehouse/selectPage` | `basic/warehouse/warehouse.api.ts:32` |
| 供应商 | `querySupplierSelect` | （purchase/apply 提供） | `purchase/apply/apply.api.ts:31` |
| 科目 | `querySubjectSelect` | （finance 提供） | `finance/subject/subject.api.ts:15` |
| **物料** | **`queryMaterialSelect`** | **`/mes/basic/material/selectPage`** | **`basic/material/material.api.ts`** ✅ 已补 |

**避免**：
- 新建 `xxx.api.ts` 时只补 CRUD，遗漏 `queryXxxSelect`（**这是 manual gap 错误**）
- 用箭头函数 `const queryXxxSelect = async (...) => {...}`（与现有风格不一致）
- 调用其他接口（如 `queryAll`/`list`）替代 `selectPage`（性能差，不分页）
- 不写 `return res || []` 兜底（ApiSelect 拿到 undefined 会报错）

**实证**：2026-07-31 批次主档打开报错根因。`material.api.ts` 补全 `queryMaterialSelect` 函数后，`master.data.ts` 和 `inventory.data.ts` 都能正常解析。改动 +7 行（含 update-begin/end 标记）。

**判断信号**：
- 新建 `xxx.api.ts` 时 → 检查 customer.api.ts 模板，确保 `queryXxxSelect` 已包含
- 前端控制台报 `does not provide an export named 'queryXxxSelect'` → 100% 是 api.ts 漏写
- grep `queryXxxSelect` 找不到导出但找到引用 → 漏写
- 后端已有 `selectPage` 接口但前端无对应函数 → 漏写

**预防清单**（新建基础模块 api.ts 时）：
1. 复制 `customer.api.ts` 完整结构作为模板
2. 补全 CRUD（query/list/add/edit/delete）
3. **必须**补 `queryXxxSelect`（即使暂无页面引用）
4. 补 `getExportUrl` / `getImportUrl`（Excel 导入导出）
5. 补 `saveOrUpdate` / `queryByIds`（批量操作辅助）
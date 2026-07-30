# 状态机阶段颜色映射必须按模块分表，不能合并

**场景**：多模块共用状态机颜色映射（如销售订单 6 状态 / 发货单 5 状态 / 销售出库 4 状态）。若合一个 `Record<string, string>`，会出现"状态值巧合相同但含义不同"的维护陷阱。

**反例（已拒绝）**：

```typescript
// 看似简洁，但致命
const COLOR: Record<string, string> = {
  '1': 'orange', '2': 'blue', '3': 'green', '0': 'default', '6': 'default'
};
// 销售订单 '2' = 已审核（blue，流转中）
// 发货单   '2' = 待出库（blue，流转中）—— 巧合同色，但后续调整时易改错
// 出库     '2' = 待审核（blue，流转中）—— 同样巧合
```

**正例（采纳）**：

```typescript
// src/views/project/mes/sales/shared/statusColor.ts
export type StatusModule = 'order' | 'delivery' | 'outbound';

const STATUS_COLOR_MAP: Record<StatusModule, Record<string, string>> = {
  order:    { '1': 'orange', '2': 'blue', '3': 'blue', '4': 'green', '5': 'green', '6': 'default' },
  delivery: { '0': 'default', '1': 'orange', '2': 'blue', '3': 'green', '4': 'green' },
  outbound: { '0': 'default', '1': 'orange', '2': 'blue', '3': 'green' },
};

export function getStatusColor(module: StatusModule, status: string): string {
  return STATUS_COLOR_MAP[module]?.[status] || 'default';
}
```

**判断信号**：
- 3 个以上模块共用状态机 → 必须分模块映射
- 字典值含义重叠（如不同模块都有 '2'） → 强信号
- 后续要扩展新模块 → 分表减少耦合

**实证**：2026-07-30 销售链路对齐。Claude 评审建议采纳此方案，确认优于合并全映射。

**避免**：节省几行代码换维护性灾难。每次改一处 status 颜色都要全局搜索所有模块的 status 含义。
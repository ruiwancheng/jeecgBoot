// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
// 批次链路四模块状态机阶段颜色映射
// 四模块（master/inventory/ledger/traceability）state value 含义不同，分模块映射

export type StatusModule = 'batch' | 'origin';

const STATUS_COLOR_MAP: Record<StatusModule, Record<string, string>> = {
  // 批次主档状态：1在用/2冻结/3已耗尽/4过期
  batch: {
    '1': 'green', // 在用
    '2': 'orange', // 冻结（质检不合格等）
    '3': 'default', // 已耗尽
    '4': 'red', // 过期
  },
  // 来源类型：1采购入库/2生产完工/3手工创建
  origin: {
    '1': 'blue', // 采购入库
    '2': 'cyan', // 生产完工
    '3': 'default', // 手工创建
  },
};

export function getStatusColor(module: StatusModule, status: string): string {
  return STATUS_COLOR_MAP[module]?.[status] || 'default';
}

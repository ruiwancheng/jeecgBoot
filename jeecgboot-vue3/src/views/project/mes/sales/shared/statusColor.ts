// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
// 销售链路三模块状态机阶段颜色映射（草稿橙 / 流转中蓝 / 已完成绿 / 已取消灰）
// 三模块 state value 含义不同，必须分模块映射表，避免值巧合混淆

export type StatusModule = 'order' | 'delivery' | 'outbound';

const STATUS_COLOR_MAP: Record<StatusModule, Record<string, string>> = {
  order: {
    '1': 'orange', // 草稿
    '2': 'blue', // 已审核
    '3': 'blue', // 已下达
    '4': 'green', // 已发货
    '5': 'green', // 已关闭
    '6': 'default', // 已取消
  },
  delivery: {
    '0': 'default', // 已取消
    '1': 'orange', // 草稿
    '2': 'blue', // 待出库
    '3': 'green', // 已出库
    '4': 'green', // 已签收
  },
  outbound: {
    '0': 'default', // 已取消
    '1': 'orange', // 草稿
    '2': 'blue', // 待审核
    '3': 'green', // 已审核
  },
};

export function getStatusColor(module: StatusModule, status: string): string {
  return STATUS_COLOR_MAP[module]?.[status] || 'default';
}

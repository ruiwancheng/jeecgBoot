// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
// 制造链路四模块状态机阶段颜色映射（草稿橙 / 流转中蓝 / 已完成绿 / 已关闭灰 / 执行中青）
// 四模块 state value 含义不同，必须分模块映射表

export type StatusModule = 'bom' | 'order' | 'picking' | 'completion';

const STATUS_COLOR_MAP: Record<StatusModule, Record<string, string>> = {
  bom: {
    '1': 'orange', // 草稿
    '2': 'green', // 生效
    '3': 'default', // 失效
  },
  order: {
    '1': 'orange', // 草稿
    '2': 'blue', // 已审核
    '3': 'blue', // 已下达
    '4': 'cyan', // 执行中（独立颜色，进行中过渡态）
    '5': 'green', // 已完工
    '6': 'default', // 已关闭
    '7': 'default', // 已取消
  },
  picking: {
    '1': 'orange', // 草稿
    '2': 'green', // 已审核
  },
  completion: {
    '1': 'orange', // 草稿
    '2': 'green', // 已入库
  },
};

export function getStatusColor(module: StatusModule, status: string): string {
  return STATUS_COLOR_MAP[module]?.[status] || 'default';
}

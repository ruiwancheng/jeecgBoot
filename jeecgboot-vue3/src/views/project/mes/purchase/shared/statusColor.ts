// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
// 采购链路三模块状态机阶段颜色映射（草稿橙 / 流转中蓝 / 已完成绿 / 已驳回灰 / 部分到货青）
// 三模块 state value 含义不同，必须分模块映射表

export type StatusModule = 'apply' | 'order' | 'receipt';

const STATUS_COLOR_MAP: Record<StatusModule, Record<string, string>> = {
  apply: {
    '1': 'orange', // 草稿
    '2': 'blue', // 已提交
    '3': 'green', // 已通过
    '4': 'default', // 已驳回
  },
  order: {
    '1': 'orange', // 草稿
    '2': 'blue', // 待确认
    '3': 'green', // 已确认
    '4': 'cyan', // 部分到货（独立颜色，进行中过渡态）
    '5': 'green', // 已到货
    '6': 'green', // 已关闭（正常业务终态，与销售订单已关闭同色）
  },
  receipt: {
    '1': 'orange', // 草稿
    '2': 'green', // 已入库
  },
};

export function getStatusColor(module: StatusModule, status: string): string {
  return STATUS_COLOR_MAP[module]?.[status] || 'default';
}

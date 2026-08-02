//update-begin---author:ruiwancheng---date:20260803---for: V10.0.3 批次追溯-API拆分（master 重导出移除 + 新增 traceability 端点）-----------
import { defHttp } from '/@/utils/http/axios';

// 批次追溯：batch 级聚合列表（V10.0.3 新增）
export function queryTraceabilityList(params: any) {
  return defHttp.get({ url: '/mes/batch/traceability/list', params });
}

// 批次追溯：batch 级导出（V10.0.3 新增）
export function getTraceabilityExportUrl() {
  return '/mes/batch/traceability/exportXls';
}

// 抽屉用：批次主档 list（按 batchId 查单条用于抽屉主档展示）
export { queryBatchList } from '../master/master.api';

// 抽屉用：批次流水 listByBatchId（按 batchId 查流水用于抽屉流水表）
export function listLedgerByBatchId(params: any) {
  return defHttp.get({ url: '/mes/batch/ledger/listByBatchId', params });
}
//update-end---author:ruiwancheng---date:20260803---for: V10.0.3 批次追溯-API拆分（master 重导出移除 + 新增 traceability 端点）-----------

import { defHttp } from '/@/utils/http/axios';

// 批次追溯：复用 ledger 的 listByBatchId 端点
export function listLedgerByBatchId(params: any) {
  return defHttp.get({ url: `/mes/batch/ledger/listByBatchId`, params });
}

// 批次主档
import { queryBatchList } from '../master/master.api';
export { queryBatchList };

//update-begin---author:ruiwancheng---date:2026-07-31---for: P0-4 铁拳团-批次追溯导出函数（复用主档端点）-----------
export function getExportUrl() {
  return '/mes/batch/master/exportXls';
}
//update-end---author:ruiwancheng---date:2026-07-31---for: P0-4 铁拳团-批次追溯导出函数-----------

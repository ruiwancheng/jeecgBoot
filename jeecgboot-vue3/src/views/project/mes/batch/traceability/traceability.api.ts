import { defHttp } from '/@/utils/http/axios';

// 批次追溯：复用 ledger 的 listByBatchId 端点
export function listLedgerByBatchId(params: any) {
  return defHttp.get({ url: `/mes/batch/ledger/listByBatchId`, params });
}

// 批次主档
import { queryBatchList } from '../master/master.api';
export { queryBatchList };

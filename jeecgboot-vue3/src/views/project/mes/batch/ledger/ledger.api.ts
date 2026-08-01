import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/batch/ledger';

export function queryLedgerList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

//update-begin---author:ruiwancheng---date:2026-07-31---for: P0-4 铁拳团-批次流水导出函数-----------
export function getExportUrl() {
  return '/mes/batch/ledger/exportXls';
}
//update-end---author:ruiwancheng---date:2026-07-31---for: P0-4 铁拳团-批次流水导出函数-----------

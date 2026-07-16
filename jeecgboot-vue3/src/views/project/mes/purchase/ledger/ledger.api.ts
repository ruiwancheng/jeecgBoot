import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/warehouse/ledger';

export function queryLedgerList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

export function getExportUrl() {
  return `${BASE}/exportXls`;
}

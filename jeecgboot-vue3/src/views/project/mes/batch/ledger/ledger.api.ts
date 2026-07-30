import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/batch/ledger';

export function queryLedgerList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

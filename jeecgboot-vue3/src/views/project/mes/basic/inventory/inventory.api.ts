import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/warehouse/inventory';

export function queryInventoryList(params: Recordable) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

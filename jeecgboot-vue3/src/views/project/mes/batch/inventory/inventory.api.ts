import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/batch/inventory';

export function queryInventoryList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

export function queryInventoryById(params: any) {
  return defHttp.get({ url: `${BASE}/queryById`, params });
}

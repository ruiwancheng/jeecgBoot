import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/batch/master';

export function queryBatchList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

export function queryBatchById(params: any) {
  return defHttp.get({ url: `${BASE}/queryById`, params });
}

export function addBatch(data: any) {
  return defHttp.post({ url: `${BASE}/add`, data });
}

export function editBatch(data: any) {
  return defHttp.put({ url: `${BASE}/edit`, data });
}

export function deleteBatch(params: any) {
  return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true });
}

export function freezeBatch(params: any) {
  return defHttp.put({ url: `${BASE}/freeze`, params }, { joinParamsToUrl: true });
}

export function unfreezeBatch(params: any) {
  return defHttp.put({ url: `${BASE}/unfreeze`, params }, { joinParamsToUrl: true });
}

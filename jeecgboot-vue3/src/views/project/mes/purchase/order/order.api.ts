import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/purchase/order';

export function queryOrderList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

export function queryOrderById(params: any) {
  return defHttp.get({ url: `${BASE}/queryById`, params });
}

export function saveOrUpdateOrder(data: any, isUpdate: boolean) {
  return isUpdate
    ? defHttp.put({ url: `${BASE}/edit`, data })
    : defHttp.post({ url: `${BASE}/add`, data });
}

export function deleteOrder(params: any) {
  return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true });
}

export function deleteBatchOrder(params: any) {
  return defHttp.delete({ url: `${BASE}/deleteBatch`, params }, { joinParamsToUrl: true });
}

export function auditOrder(params: any) {
  return defHttp.put({ url: `${BASE}/audit`, params });
}

export function getExportUrl() {
  return `${BASE}/exportXls`;
}

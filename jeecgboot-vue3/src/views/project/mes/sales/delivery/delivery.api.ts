import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/sales/delivery';

export function queryDeliveryList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

export function queryDeliveryById(params: any) {
  return defHttp.get({ url: `${BASE}/queryById`, params });
}

export function saveOrUpdateDelivery(data: any, isUpdate: boolean) {
  return isUpdate
    ? defHttp.put({ url: `${BASE}/edit`, data })
    : defHttp.post({ url: `${BASE}/add`, data });
}

export function deleteDelivery(params: any) {
  return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true });
}

export function deleteBatchDelivery(params: any) {
  return defHttp.delete({ url: `${BASE}/deleteBatch`, params }, { joinParamsToUrl: true });
}

export function getExportUrl() {
  return `${BASE}/exportXls`;
}

//update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-----------
export function submitDelivery(params: any) {
  return defHttp.put({ url: `${BASE}/submit`, params }, { joinParamsToUrl: true });
}
export function signDelivery(params: any) {
  return defHttp.put({ url: `${BASE}/sign`, params }, { joinParamsToUrl: true });
}
export function cancelDelivery(params: any) {
  return defHttp.put({ url: `${BASE}/cancel`, params }, { joinParamsToUrl: true });
}
//update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-----------

import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/sales/order';

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

export function getExportUrl() {
  return `${BASE}/exportXls`;
}

//update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-----------
export function auditOrder(params: any) {
  return defHttp.put({ url: `${BASE}/audit`, params }, { joinParamsToUrl: true });
}
export function releaseOrder(params: any) {
  return defHttp.put({ url: `${BASE}/release`, params }, { joinParamsToUrl: true });
}
export function closeOrder(params: any) {
  return defHttp.put({ url: `${BASE}/close`, params }, { joinParamsToUrl: true });
}
export function cancelOrder(params: any) {
  return defHttp.put({ url: `${BASE}/cancel`, params }, { joinParamsToUrl: true });
}
//update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-----------

/** 下拉选择（ApiSelect专用，替代平台字典 c_mes_sales/order） */
export async function querySalesOrderSelect(params?: any) {
  const res = await defHttp.get({ url: '/mes/sales/order/selectPage', params });
  return res || [];
}

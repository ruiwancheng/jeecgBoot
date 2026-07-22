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
  return defHttp.put({ url: `${BASE}/audit`, params }, { joinParamsToUrl: true });
}

export function getExportUrl() {
  return `${BASE}/exportXls`;
}

/** 供应商下拉（ApiSelect专用，调用MES供应商selectPage替代平台字典） */
export async function querySupplierSelect(params?: any) {
  const res = await defHttp.get({ url: '/mes/basic/supplier/selectPage', params });
  return res || [];
}

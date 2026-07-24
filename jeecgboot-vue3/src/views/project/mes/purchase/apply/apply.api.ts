import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/purchase/apply';

export function queryApplyList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

export function queryApplyById(params: any) {
  return defHttp.get({ url: `${BASE}/queryById`, params });
}

export function saveOrUpdateApply(data: any, isUpdate: boolean) {
  return isUpdate
    ? defHttp.put({ url: `${BASE}/edit`, data })
    : defHttp.post({ url: `${BASE}/add`, data });
}

export function deleteApply(params: any) {
  return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true });
}

export function deleteBatchApply(params: any) {
  return defHttp.delete({ url: `${BASE}/deleteBatch`, params }, { joinParamsToUrl: true });
}

export function auditApply(params: any) {
  return defHttp.put({ url: `${BASE}/audit`, params }, { joinParamsToUrl: true });
}

export async function querySupplierSelect(params?: any) {
  const res = await defHttp.get({ url: '/mes/basic/supplier/selectPage', params });
  return res || [];
}

export function getExportUrl() {
  return `${BASE}/exportXls`;
}

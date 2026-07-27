import { defHttp } from '/@/utils/http/axios';
const BASE = '/mes/stock/otherIn';

export function queryOtherInList(params: any) { return defHttp.get({ url: `${BASE}/list`, params }); }
export function queryOtherInById(params: any) { return defHttp.get({ url: `${BASE}/queryById`, params }); }
export function saveOrUpdateOtherIn(data: any, isUpdate: boolean) { return isUpdate ? defHttp.put({ url: `${BASE}/edit`, data }) : defHttp.post({ url: `${BASE}/add`, data }); }
export function deleteOtherIn(params: any) { return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true }); }
export function auditOtherIn(params: any) { return defHttp.put({ url: `${BASE}/audit`, params }, { joinParamsToUrl: true }); }
export function unauditOtherIn(params: any) { return defHttp.put({ url: `${BASE}/unaudit`, params }, { joinParamsToUrl: true }); }
export function getExportUrl() { return `${BASE}/exportXls`; }

/** 库位下拉（ApiSelect专用，替代平台字典 c_mes_location，可按仓库过滤） */
export async function queryLocationSelect(params?: any) {
  const res = await defHttp.get({ url: '/mes/basic/location/selectPage', params });
  return res || [];
}

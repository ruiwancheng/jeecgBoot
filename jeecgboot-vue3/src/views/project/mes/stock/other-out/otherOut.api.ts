import { defHttp } from '/@/utils/http/axios';
const BASE = '/mes/stock/otherOut';

export function queryOtherOutList(params: any) { return defHttp.get({ url: `${BASE}/list`, params }); }
export function queryOtherOutById(params: any) { return defHttp.get({ url: `${BASE}/queryById`, params }); }
export function saveOrUpdateOtherOut(data: any, isUpdate: boolean) { return isUpdate ? defHttp.put({ url: `${BASE}/edit`, data }) : defHttp.post({ url: `${BASE}/add`, data }); }
export function deleteOtherOut(params: any) { return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true }); }
export function auditOtherOut(params: any) { return defHttp.put({ url: `${BASE}/audit`, params }, { joinParamsToUrl: true }); }
export function unauditOtherOut(params: any) { return defHttp.put({ url: `${BASE}/unaudit`, params }, { joinParamsToUrl: true }); }
export function getExportUrl() { return `${BASE}/exportXls`; }

import { defHttp } from '/@/utils/http/axios';
const BASE = '/mes/sales/outbound';

export function queryOutboundList(params: any) { return defHttp.get({ url: `${BASE}/list`, params }); }
export function queryOutboundById(params: any) { return defHttp.get({ url: `${BASE}/queryById`, params }); }
export function saveOrUpdateOutbound(data: any, isUpdate: boolean) { return isUpdate ? defHttp.put({ url: `${BASE}/edit`, data }) : defHttp.post({ url: `${BASE}/add`, data }); }
export function deleteOutbound(params: any) { return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true }); }
export function auditOutbound(params: any) { return defHttp.put({ url: `${BASE}/audit`, params }, { joinParamsToUrl: true }); }
export function cancelOutbound(params: any) { return defHttp.put({ url: `${BASE}/cancel`, params }, { joinParamsToUrl: true }); }
export function getExportUrl() { return `${BASE}/exportXls`; }

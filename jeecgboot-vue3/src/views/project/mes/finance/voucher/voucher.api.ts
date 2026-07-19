import { defHttp } from '/@/utils/http/axios';
const BASE = '/mes/finance/voucher';
export function queryVoucherList(params: any) { return defHttp.get({ url: `${BASE}/list`, params }); }
export function queryVoucherById(params: any) { return defHttp.get({ url: `${BASE}/queryById`, params }); }
export function saveOrUpdateVoucher(data: any, isUpdate: boolean) { return isUpdate ? defHttp.put({ url: `${BASE}/edit`, data }) : defHttp.post({ url: `${BASE}/add`, data }); }
export function deleteVoucher(params: any) { return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true }); }
export function auditVoucher(params: any) { return defHttp.put({ url: `${BASE}/audit`, params }, { joinParamsToUrl: true }); }
export function getExportUrl() { return `${BASE}/exportXls`; }

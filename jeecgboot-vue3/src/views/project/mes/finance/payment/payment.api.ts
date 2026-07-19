import { defHttp } from '/@/utils/http/axios';
const BASE = '/mes/finance/payment';
export function queryPaymentList(params: any) { return defHttp.get({ url: `${BASE}/list`, params }); }
export function queryPaymentById(params: any) { return defHttp.get({ url: `${BASE}/queryById`, params }); }
export function addPayment(data: any) { return defHttp.post({ url: `${BASE}/add`, data }); }
export function getExportUrl() { return `${BASE}/exportXls`; }

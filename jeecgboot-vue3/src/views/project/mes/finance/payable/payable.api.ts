import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/finance/payable';

export function queryPayableList(params: any) { return defHttp.get({ url: `${BASE}/list`, params }); }
export function queryPayableById(params: any) { return defHttp.get({ url: `${BASE}/queryById`, params }); }
export function getExportUrl() { return `${BASE}/exportXls`; }

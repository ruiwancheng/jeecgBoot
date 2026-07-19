import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/finance/receivable';

export function queryReceivableList(params: any) { return defHttp.get({ url: `${BASE}/list`, params }); }
export function queryReceivableById(params: any) { return defHttp.get({ url: `${BASE}/queryById`, params }); }
export function getExportUrl() { return `${BASE}/exportXls`; }

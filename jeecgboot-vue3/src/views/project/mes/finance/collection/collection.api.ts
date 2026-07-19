import { defHttp } from '/@/utils/http/axios';
const BASE = '/mes/finance/collection';
export function queryCollectionList(params: any) { return defHttp.get({ url: `${BASE}/list`, params }); }
export function queryCollectionById(params: any) { return defHttp.get({ url: `${BASE}/queryById`, params }); }
export function addCollection(data: any) { return defHttp.post({ url: `${BASE}/add`, data }); }
export function getExportUrl() { return `${BASE}/exportXls`; }

import { defHttp } from '/@/utils/http/axios';
const BASE = '/mes/stock/stocktake';

export function queryStocktakeList(params: any) { return defHttp.get({ url: `${BASE}/list`, params }); }
export function queryStocktakeById(params: any) { return defHttp.get({ url: `${BASE}/queryById`, params }); }
export function saveOrUpdateStocktake(data: any, isUpdate: boolean) { return isUpdate ? defHttp.put({ url: `${BASE}/edit`, data }) : defHttp.post({ url: `${BASE}/add`, data }); }
export function deleteStocktake(params: any) { return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true }); }
export function auditStocktake(params: any) { return defHttp.put({ url: `${BASE}/audit`, params }, { joinParamsToUrl: true }); }

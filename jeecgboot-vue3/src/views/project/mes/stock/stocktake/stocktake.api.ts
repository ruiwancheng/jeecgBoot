import { defHttp } from '/@/utils/http/axios';
const BASE = '/mes/stock/stocktake';

export function queryStocktakeList(params: any) { return defHttp.get({ url: `${BASE}/list`, params }); }
export function queryStocktakeById(params: any) { return defHttp.get({ url: `${BASE}/queryById`, params }); }
export function saveOrUpdateStocktake(data: any, isUpdate: boolean) { return isUpdate ? defHttp.put({ url: `${BASE}/edit`, data }) : defHttp.post({ url: `${BASE}/add`, data }); }
export function deleteStocktake(params: any) { return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true }); }
// /debug 修复：审核返回的长文本会被 defHttp 拦截器自动弹顶部横幅（向右滚动）
// → successMessageMode:'none' 关闭拦截器横幅，只走页面自定义 Modal
export function auditStocktake(params: any) { return defHttp.put({ url: `${BASE}/audit`, params }, { joinParamsToUrl: true, successMessageMode: 'none' }); }
export function batchAuditStocktake(ids: string[]) { return defHttp.post({ url: `${BASE}/batchAudit`, data: { ids } }, { successMessageMode: 'none' }); }
export function refreshStocktakeItems(params: any) { return defHttp.post({ url: `${BASE}/refreshItems`, params }, { joinParamsToUrl: true }); }

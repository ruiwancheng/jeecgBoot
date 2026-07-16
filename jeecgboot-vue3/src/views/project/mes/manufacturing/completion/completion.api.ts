import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/manufacturing/completion';

export function queryCompletionList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

export function queryCompletionById(params: any) {
  return defHttp.get({ url: `${BASE}/queryById`, params });
}

export function saveOrUpdateCompletion(data: any, isUpdate: boolean) {
  return isUpdate
    ? defHttp.put({ url: `${BASE}/edit`, data })
    : defHttp.post({ url: `${BASE}/add`, data });
}

export function deleteCompletion(params: any) {
  return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true });
}

export function deleteBatchCompletion(params: any) {
  return defHttp.delete({ url: `${BASE}/deleteBatch`, params }, { joinParamsToUrl: true });
}

export function getExportUrl() {
  return `${BASE}/exportXls`;
}

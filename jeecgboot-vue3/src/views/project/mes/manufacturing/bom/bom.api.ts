import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/manufacturing/bom';

export function queryBomList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

export function queryBomById(params: any) {
  return defHttp.get({ url: `${BASE}/queryById`, params });
}

export function saveOrUpdateBom(data: any, isUpdate: boolean) {
  return isUpdate
    ? defHttp.put({ url: `${BASE}/edit`, data })
    : defHttp.post({ url: `${BASE}/add`, data });
}

export function deleteBom(params: any) {
  return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true });
}

export function deleteBatchBom(params: any) {
  return defHttp.delete({ url: `${BASE}/deleteBatch`, params }, { joinParamsToUrl: true });
}

export function getExportUrl() {
  return `${BASE}/exportXls`;
}

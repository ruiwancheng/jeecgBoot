import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/manufacturing/picking';

export function queryPickingList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

export function queryPickingById(params: any) {
  return defHttp.get({ url: `${BASE}/queryById`, params });
}

export function saveOrUpdatePicking(data: any, isUpdate: boolean) {
  return isUpdate
    ? defHttp.put({ url: `${BASE}/edit`, data })
    : defHttp.post({ url: `${BASE}/add`, data });
}

export function deletePicking(params: any) {
  return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true });
}

export function deleteBatchPicking(params: any) {
  return defHttp.delete({ url: `${BASE}/deleteBatch`, params }, { joinParamsToUrl: true });
}

//update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】领料补领端点（按订单生成补领单）-----------
export function generatePickingByOrder(params: any) {
  return defHttp.post({ url: `${BASE}/generateByOrder`, params }, { joinParamsToUrl: true });
}
//update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】领料补领端点-----------

export function getExportUrl() {
  return `${BASE}/exportXls`;
}

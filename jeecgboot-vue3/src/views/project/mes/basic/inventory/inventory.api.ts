import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/warehouse/inventory';

// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0

export function queryInventoryList(params: Recordable) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】单删 API（DELETE + query）-----------
export function deleteOrphanInventory(params: { id: string }) {
  return defHttp.delete({ url: `${BASE}/deleteOrphan`, params }, { joinParamsToUrl: true });
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】单删 API-----------

//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】批量删 API（POST + body，防 HTTP 414）-----------
export function batchDeleteOrphanInventory(params: { ids: string[] }) {
  return defHttp.post({ url: `${BASE}/batchDeleteOrphan`, params });
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】批量删 API-----------

//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】导出 URL + 孤儿行总数接口-----------
export function getOrphanExportUrl() {
  return `${BASE}/exportOrphanXls`;
}

export function queryOrphanCount() {
  return defHttp.get({ url: `${BASE}/orphanCount` });
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】导出 URL + 孤儿行总数接口-----------

// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
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

//update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】BOM状态机端点（生效/失效）-----------
export function approveBom(params: any) {
  return defHttp.put({ url: `${BASE}/approve`, params }, { joinParamsToUrl: true });
}

export function disableBom(params: any) {
  return defHttp.put({ url: `${BASE}/disable`, params }, { joinParamsToUrl: true });
}
//update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】BOM状态机端点-----------

export function getExportUrl() {
  return `${BASE}/exportXls`;
}

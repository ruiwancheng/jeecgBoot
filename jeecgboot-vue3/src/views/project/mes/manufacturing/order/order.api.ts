import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/manufacturing/order';

export function queryOrderList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

export function queryOrderById(params: any) {
  return defHttp.get({ url: `${BASE}/queryById`, params });
}

export function saveOrUpdateOrder(data: any, isUpdate: boolean) {
  return isUpdate
    ? defHttp.put({ url: `${BASE}/edit`, data })
    : defHttp.post({ url: `${BASE}/add`, data });
}

export function deleteOrder(params: any) {
  return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true });
}

export function deleteBatchOrder(params: any) {
  return defHttp.delete({ url: `${BASE}/deleteBatch`, params }, { joinParamsToUrl: true });
}

//update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】订单状态机端点（5个）-----------
export function auditOrder(params: any) {
  return defHttp.put({ url: `${BASE}/audit`, params }, { joinParamsToUrl: true });
}

export function releaseOrder(params: any) {
  return defHttp.put({ url: `${BASE}/release`, params }, { joinParamsToUrl: true });
}

export function completeOrder(params: any) {
  return defHttp.put({ url: `${BASE}/complete`, params }, { joinParamsToUrl: true });
}

export function closeOrder(params: any) {
  return defHttp.put({ url: `${BASE}/close`, params }, { joinParamsToUrl: true });
}

export function cancelOrder(params: any) {
  return defHttp.put({ url: `${BASE}/cancel`, params }, { joinParamsToUrl: true });
}

export function generatePicking(data: any) {
  return defHttp.post({ url: `${BASE}/generatePicking`, data });
}
//update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】订单状态机端点-----------

export function getExportUrl() {
  return `${BASE}/exportXls`;
}

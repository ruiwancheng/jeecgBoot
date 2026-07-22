import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/purchase/receipt';

export function queryReceiptList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

export function queryReceiptById(params: any) {
  return defHttp.get({ url: `${BASE}/queryById`, params });
}

export function saveOrUpdateReceipt(data: any, isUpdate: boolean) {
  return isUpdate
    ? defHttp.put({ url: `${BASE}/edit`, data })
    : defHttp.post({ url: `${BASE}/add`, data });
}

export function deleteReceipt(params: any) {
  return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true });
}

export function deleteBatchReceipt(params: any) {
  return defHttp.delete({ url: `${BASE}/deleteBatch`, params }, { joinParamsToUrl: true });
}

/** 根据采购订单ID加载可入库明细行 */
export function loadOrderItemsForReceipt(orderId: string) {
  return defHttp.get({ url: `${BASE}/loadOrderItemsForReceipt`, params: { orderId } });
}

export function getExportUrl() {
  return `${BASE}/exportXls`;
}

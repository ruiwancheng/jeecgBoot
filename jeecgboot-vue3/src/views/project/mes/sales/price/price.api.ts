import { defHttp } from '/@/utils/http/axios';

enum Api {
  list = '/mes/sales/price/list',
  add = '/mes/sales/price/add',
  edit = '/mes/sales/price/edit',
  delete = '/mes/sales/price/delete',
  deleteBatch = '/mes/sales/price/deleteBatch',
  queryById = '/mes/sales/price/queryById',
  queryAll = '/mes/sales/price/queryAll',
  exportXls = '/mes/sales/price/exportXls',
  importExcel = '/mes/sales/price/importExcel',
}

export const getExportUrl = Api.exportXls;
export const getImportUrl = Api.importExcel;

export const queryPriceList = (params: Recordable) => defHttp.get({ url: Api.list, params });
export const addPrice = (params: Recordable) => defHttp.post({ url: Api.add, params });
export const editPrice = (params: Recordable) => defHttp.put({ url: Api.edit, params });
export const deletePrice = (params: Recordable) => defHttp.delete({ url: Api.delete, params }, { joinParamsToUrl: true });
export const deleteBatchPrice = (params: Recordable) => defHttp.delete({ url: Api.deleteBatch, params }, { joinParamsToUrl: true });
export const queryPriceById = (params: Recordable) => defHttp.get({ url: Api.queryById, params });
export const queryAllPrice = () => defHttp.get({ url: Api.queryAll });
export const saveOrUpdatePrice = (params: Recordable, isUpdate: boolean) =>
  isUpdate ? editPrice(params) : addPrice(params);

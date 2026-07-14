import { defHttp } from '/@/utils/http/axios';

enum Api {
  list = '/mes/basic/supplier/list',
  add = '/mes/basic/supplier/add',
  edit = '/mes/basic/supplier/edit',
  delete = '/mes/basic/supplier/delete',
  deleteBatch = '/mes/basic/supplier/deleteBatch',
  queryAll = '/mes/basic/supplier/queryAll',
  exportXls = '/mes/basic/supplier/exportXls',
  importExcel = '/mes/basic/supplier/importExcel',
}

export const getExportUrl = Api.exportXls;
export const getImportUrl = Api.importExcel;

export const querySupplierList = (params: Recordable) => defHttp.get({ url: Api.list, params });
export const addSupplier = (params: Recordable) => defHttp.post({ url: Api.add, params });
export const editSupplier = (params: Recordable) => defHttp.put({ url: Api.edit, params });
export const deleteSupplier = (params: Recordable) => defHttp.delete({ url: Api.delete, params }, { joinParamsToUrl: true });
export const deleteBatchSupplier = (params: Recordable) => defHttp.delete({ url: Api.deleteBatch, params }, { joinParamsToUrl: true });
export const queryAllSupplier = () => defHttp.get({ url: Api.queryAll });
export const saveOrUpdateSupplier = (params: Recordable, isUpdate: boolean) =>
  isUpdate ? editSupplier(params) : addSupplier(params);

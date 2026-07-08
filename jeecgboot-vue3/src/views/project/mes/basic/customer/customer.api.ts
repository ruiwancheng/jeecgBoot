import { defHttp } from '/@/utils/http/axios';

enum Api {
  list = '/mes/basic/customer/list',
  add = '/mes/basic/customer/add',
  edit = '/mes/basic/customer/edit',
  delete = '/mes/basic/customer/delete',
  deleteBatch = '/mes/basic/customer/deleteBatch',
  queryAll = '/mes/basic/customer/queryAll',
  exportXls = '/mes/basic/customer/exportXls',
  importExcel = '/mes/basic/customer/importExcel',
}

export const getExportUrl = Api.exportXls;
export const getImportUrl = Api.importExcel;

export const queryCustomerList = (params: Recordable) => defHttp.get({ url: Api.list, params });
export const addCustomer = (params: Recordable) => defHttp.post({ url: Api.add, params });
export const editCustomer = (params: Recordable) => defHttp.put({ url: Api.edit, params });
export const deleteCustomer = (params: Recordable) => defHttp.delete({ url: Api.delete, params }, { joinParamsToUrl: true });
export const deleteBatchCustomer = (params: Recordable) => defHttp.delete({ url: Api.deleteBatch, params }, { joinParamsToUrl: true });
export const queryAllCustomer = () => defHttp.get({ url: Api.queryAll });
export const saveOrUpdateCustomer = (params: Recordable, isUpdate: boolean) => {
  return isUpdate ? editCustomer(params) : addCustomer(params);
};

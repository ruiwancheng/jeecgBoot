import { defHttp } from '/@/utils/http/axios';

enum Api {
  // 客户主表
  list = '/mes/basic/customer/list',
  add = '/mes/basic/customer/add',
  edit = '/mes/basic/customer/edit',
  delete = '/mes/basic/customer/delete',
  deleteBatch = '/mes/basic/customer/deleteBatch',
  queryAll = '/mes/basic/customer/queryAll',
  exportXls = '/mes/basic/customer/exportXls',
  importExcel = '/mes/basic/customer/importExcel',
  // 联系人
  contactList = '/mes/basic/customer/contact/list',
  contactAdd = '/mes/basic/customer/contact/add',
  contactEdit = '/mes/basic/customer/contact/edit',
  contactDelete = '/mes/basic/customer/contact/delete',
  // 地址
  addressList = '/mes/basic/customer/address/list',
  addressAdd = '/mes/basic/customer/address/add',
  addressEdit = '/mes/basic/customer/address/edit',
  addressDelete = '/mes/basic/customer/address/delete',
  // 跟进记录
  followUpList = '/mes/basic/customer/followUp/list',
  followUpAdd = '/mes/basic/customer/followUp/add',
  followUpEdit = '/mes/basic/customer/followUp/edit',
  followUpDelete = '/mes/basic/customer/followUp/delete',
  // 价格表
  priceList = '/mes/basic/customer/price/list',
  priceAdd = '/mes/basic/customer/price/add',
  priceEdit = '/mes/basic/customer/price/edit',
  priceDelete = '/mes/basic/customer/price/delete',
}

export const getExportUrl = Api.exportXls;
export const getImportUrl = Api.importExcel;

// 客户主表
export const queryCustomerList = (params: Recordable) => defHttp.get({ url: Api.list, params });
export const addCustomer = (params: Recordable) => defHttp.post({ url: Api.add, params });
export const editCustomer = (params: Recordable) => defHttp.put({ url: Api.edit, params });
export const deleteCustomer = (params: Recordable) => defHttp.delete({ url: Api.delete, params }, { joinParamsToUrl: true });
export const deleteBatchCustomer = (params: Recordable) => defHttp.delete({ url: Api.deleteBatch, params }, { joinParamsToUrl: true });
export const queryAllCustomer = () => defHttp.get({ url: Api.queryAll });
export const saveOrUpdateCustomer = (params: Recordable, isUpdate: boolean) =>
  isUpdate ? editCustomer(params) : addCustomer(params);

// 联系人
export const queryContactList = (params: Recordable) => defHttp.get({ url: Api.contactList, params });
export const addContact = (params: Recordable) => defHttp.post({ url: Api.contactAdd, params });
export const editContact = (params: Recordable) => defHttp.put({ url: Api.contactEdit, params });
export const deleteContact = (params: Recordable) => defHttp.delete({ url: Api.contactDelete, params }, { joinParamsToUrl: true });

// 地址
export const queryAddressList = (params: Recordable) => defHttp.get({ url: Api.addressList, params });
export const addAddress = (params: Recordable) => defHttp.post({ url: Api.addressAdd, params });
export const editAddress = (params: Recordable) => defHttp.put({ url: Api.addressEdit, params });
export const deleteAddress = (params: Recordable) => defHttp.delete({ url: Api.addressDelete, params }, { joinParamsToUrl: true });

// 跟进记录
export const queryFollowUpList = (params: Recordable) => defHttp.get({ url: Api.followUpList, params });
export const addFollowUp = (params: Recordable) => defHttp.post({ url: Api.followUpAdd, params });
export const editFollowUp = (params: Recordable) => defHttp.put({ url: Api.followUpEdit, params });
export const deleteFollowUp = (params: Recordable) => defHttp.delete({ url: Api.followUpDelete, params }, { joinParamsToUrl: true });

// 价格表
export const queryPriceList = (params: Recordable) => defHttp.get({ url: Api.priceList, params });
export const addPrice = (params: Recordable) => defHttp.post({ url: Api.priceAdd, params });
export const editPrice = (params: Recordable) => defHttp.put({ url: Api.priceEdit, params });
export const deletePrice = (params: Recordable) => defHttp.delete({ url: Api.priceDelete, params }, { joinParamsToUrl: true });

import { defHttp } from '/@/utils/http/axios';
export enum Api {
  list = '/customer/demo/warehouse/list',
  add = '/customer/demo/warehouse/add',
  edit = '/customer/demo/warehouse/edit',
  delete = '/customer/demo/warehouse/delete',
  deleteBatch = '/customer/demo/warehouse/deleteBatch',
}
export const list = (params) => defHttp.get({ url: Api.list, params });
export const add = (params) => defHttp.post({ url: Api.add, params });
export const edit = (params) => defHttp.put({ url: Api.edit, params });
export const del = (params) => defHttp.delete({ url: Api.delete, params });
export const deleteBatch = (params) => defHttp.delete({ url: Api.deleteBatch, params }, { joinParamsToUrl: true });

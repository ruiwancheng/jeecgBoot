import { defHttp } from '/@/utils/http/axios';
export enum Api {
  list = '/customer/demo/warehouseLocation/list',
  add = '/customer/demo/warehouseLocation/add',
  edit = '/customer/demo/warehouseLocation/edit',
  delete = '/customer/demo/warehouseLocation/delete',
  deleteBatch = '/customer/demo/warehouseLocation/deleteBatch',
  generate = '/customer/demo/warehouseLocation/generate',
}
export const list = (params) => defHttp.get({ url: Api.list, params });
export const add = (params) => defHttp.post({ url: Api.add, params });
export const edit = (params) => defHttp.put({ url: Api.edit, params });
export const del = (params) => defHttp.delete({ url: Api.delete, params });
export const deleteBatch = (params) => defHttp.delete({ url: Api.deleteBatch, params }, { joinParamsToUrl: true });
export const generate = (params) => defHttp.post({ url: Api.generate, params });

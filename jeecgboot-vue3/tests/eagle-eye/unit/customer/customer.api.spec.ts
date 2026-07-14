import { describe, it, expect, vi } from 'vitest';

// 模拟 defHttp，避免真实请求
vi.mock('/@/utils/http/axios', () => ({
  defHttp: {
    get: vi.fn((config: any) => Promise.resolve({ success: true, result: { records: [] } })),
    post: vi.fn((config: any) => Promise.resolve({ success: true, result: 'ok' })),
    put: vi.fn((config: any) => Promise.resolve({ success: true, result: 'ok' })),
    delete: vi.fn((config: any) => Promise.resolve({ success: true, result: 'ok' })),
  },
}));

import {
  queryCustomerList,
  addCustomer,
  editCustomer,
  deleteCustomer,
  deleteBatchCustomer,
  queryAllCustomer,
  saveOrUpdateCustomer,
  getExportUrl,
  getImportUrl,
  queryContactList,
  addContact,
  editContact,
  deleteContact,
  queryAddressList,
  addAddress,
  editAddress,
  deleteAddress,
  queryFollowUpList,
  addFollowUp,
  editFollowUp,
  deleteFollowUp,
  queryPriceList,
  addPrice,
  editPrice,
  deletePrice,
} from '@/views/project/mes/basic/customer/customer.api';
import { defHttp } from '/@/utils/http/axios';

const mockedGet = defHttp.get as any;
const mockedPost = defHttp.post as any;
const mockedPut = defHttp.put as any;
const mockedDelete = defHttp.delete as any;

function clearMocks() {
  mockedGet.mockClear();
  mockedPost.mockClear();
  mockedPut.mockClear();
  mockedDelete.mockClear();
}

describe('客户模块 API 封装', () => {
  beforeEach(() => {
    clearMocks();
  });

  describe('客户主表', () => {
    it('queryCustomerList 应调用 GET /mes/basic/customer/list', async () => {
      const params = { pageNo: 1, pageSize: 10 };
      await queryCustomerList(params);
      expect(defHttp.get).toHaveBeenCalledWith({ url: '/mes/basic/customer/list', params });
    });

    it('addCustomer 应调用 POST /mes/basic/customer/add', async () => {
      const params = { code: 'C001', name: '测试客户' };
      await addCustomer(params);
      expect(defHttp.post).toHaveBeenCalledWith({ url: '/mes/basic/customer/add', params });
    });

    it('editCustomer 应调用 PUT /mes/basic/customer/edit', async () => {
      const params = { id: '123', code: 'C001', name: '测试客户' };
      await editCustomer(params);
      expect(defHttp.put).toHaveBeenCalledWith({ url: '/mes/basic/customer/edit', params });
    });

    it('deleteCustomer 应调用 DELETE /mes/basic/customer/delete，参数拼接到 URL', async () => {
      const params = { id: '123' };
      await deleteCustomer(params);
      expect(defHttp.delete).toHaveBeenCalledWith(
        { url: '/mes/basic/customer/delete', params },
        { joinParamsToUrl: true }
      );
    });

    it('deleteBatchCustomer 应调用 DELETE /mes/basic/customer/deleteBatch', async () => {
      const params = { ids: '1,2,3' };
      await deleteBatchCustomer(params);
      expect(defHttp.delete).toHaveBeenCalledWith(
        { url: '/mes/basic/customer/deleteBatch', params },
        { joinParamsToUrl: true }
      );
    });

    it('queryAllCustomer 应调用 GET /mes/basic/customer/queryAll', async () => {
      await queryAllCustomer();
      expect(defHttp.get).toHaveBeenCalledWith({ url: '/mes/basic/customer/queryAll' });
    });

    it('saveOrUpdateCustomer 新增时调用 addCustomer', async () => {
      const params = { code: 'C001', name: '测试客户' };
      await saveOrUpdateCustomer(params, false);
      expect(defHttp.post).toHaveBeenCalledWith({ url: '/mes/basic/customer/add', params });
    });

    it('saveOrUpdateCustomer 编辑时调用 editCustomer', async () => {
      const params = { id: '123', code: 'C001', name: '测试客户' };
      await saveOrUpdateCustomer(params, true);
      expect(defHttp.put).toHaveBeenCalledWith({ url: '/mes/basic/customer/edit', params });
    });

    it('导出/导入 URL 应为常量', () => {
      expect(getExportUrl).toBe('/mes/basic/customer/exportXls');
      expect(getImportUrl).toBe('/mes/basic/customer/importExcel');
    });
  });

  describe('联系人', () => {
    it('queryContactList 应调用 GET /mes/basic/customer/contact/list', async () => {
      const params = { customerId: '123' };
      await queryContactList(params);
      expect(defHttp.get).toHaveBeenCalledWith({ url: '/mes/basic/customer/contact/list', params });
    });

    it('addContact 应调用 POST /mes/basic/customer/contact/add', async () => {
      const params = { name: '张三', phone: '13800000000' };
      await addContact(params);
      expect(defHttp.post).toHaveBeenCalledWith({ url: '/mes/basic/customer/contact/add', params });
    });

    it('editContact 应调用 PUT /mes/basic/customer/contact/edit', async () => {
      const params = { id: '1', name: '张三' };
      await editContact(params);
      expect(defHttp.put).toHaveBeenCalledWith({ url: '/mes/basic/customer/contact/edit', params });
    });

    it('deleteContact 应调用 DELETE /mes/basic/customer/contact/delete', async () => {
      const params = { id: '1' };
      await deleteContact(params);
      expect(defHttp.delete).toHaveBeenCalledWith(
        { url: '/mes/basic/customer/contact/delete', params },
        { joinParamsToUrl: true }
      );
    });
  });

  describe('地址', () => {
    it('queryAddressList 应调用 GET /mes/basic/customer/address/list', async () => {
      const params = { customerId: '123' };
      await queryAddressList(params);
      expect(defHttp.get).toHaveBeenCalledWith({ url: '/mes/basic/customer/address/list', params });
    });

    it('addAddress 应调用 POST /mes/basic/customer/address/add', async () => {
      const params = { address: '北京市' };
      await addAddress(params);
      expect(defHttp.post).toHaveBeenCalledWith({ url: '/mes/basic/customer/address/add', params });
    });

    it('editAddress 应调用 PUT /mes/basic/customer/address/edit', async () => {
      const params = { id: '1', address: '上海市' };
      await editAddress(params);
      expect(defHttp.put).toHaveBeenCalledWith({ url: '/mes/basic/customer/address/edit', params });
    });

    it('deleteAddress 应调用 DELETE /mes/basic/customer/address/delete', async () => {
      const params = { id: '1' };
      await deleteAddress(params);
      expect(defHttp.delete).toHaveBeenCalledWith(
        { url: '/mes/basic/customer/address/delete', params },
        { joinParamsToUrl: true }
      );
    });
  });

  describe('跟进记录', () => {
    it('queryFollowUpList 应调用 GET /mes/basic/customer/followUp/list', async () => {
      const params = { customerId: '123' };
      await queryFollowUpList(params);
      expect(defHttp.get).toHaveBeenCalledWith({ url: '/mes/basic/customer/followUp/list', params });
    });

    it('addFollowUp 应调用 POST /mes/basic/customer/followUp/add', async () => {
      const params = { content: '电话沟通' };
      await addFollowUp(params);
      expect(defHttp.post).toHaveBeenCalledWith({ url: '/mes/basic/customer/followUp/add', params });
    });

    it('editFollowUp 应调用 PUT /mes/basic/customer/followUp/edit', async () => {
      const params = { id: '1', content: '上门拜访' };
      await editFollowUp(params);
      expect(defHttp.put).toHaveBeenCalledWith({ url: '/mes/basic/customer/followUp/edit', params });
    });

    it('deleteFollowUp 应调用 DELETE /mes/basic/customer/followUp/delete', async () => {
      const params = { id: '1' };
      await deleteFollowUp(params);
      expect(defHttp.delete).toHaveBeenCalledWith(
        { url: '/mes/basic/customer/followUp/delete', params },
        { joinParamsToUrl: true }
      );
    });
  });

  describe('价格表', () => {
    it('queryPriceList 应调用 GET /mes/basic/customer/price/list', async () => {
      const params = { customerId: '123' };
      await queryPriceList(params);
      expect(defHttp.get).toHaveBeenCalledWith({ url: '/mes/basic/customer/price/list', params });
    });

    it('addPrice 应调用 POST /mes/basic/customer/price/add', async () => {
      const params = { materialCode: 'M001', price: 100 };
      await addPrice(params);
      expect(defHttp.post).toHaveBeenCalledWith({ url: '/mes/basic/customer/price/add', params });
    });

    it('editPrice 应调用 PUT /mes/basic/customer/price/edit', async () => {
      const params = { id: '1', price: 200 };
      await editPrice(params);
      expect(defHttp.put).toHaveBeenCalledWith({ url: '/mes/basic/customer/price/edit', params });
    });

    it('deletePrice 应调用 DELETE /mes/basic/customer/price/delete', async () => {
      const params = { id: '1' };
      await deletePrice(params);
      expect(defHttp.delete).toHaveBeenCalledWith(
        { url: '/mes/basic/customer/price/delete', params },
        { joinParamsToUrl: true }
      );
    });
  });
});

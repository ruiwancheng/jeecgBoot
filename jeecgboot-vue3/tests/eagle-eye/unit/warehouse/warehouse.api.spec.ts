import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('/@/utils/http/axios', () => ({
  defHttp: {
    get: vi.fn((config: any) => Promise.resolve({ success: true, result: { records: [] } })),
    post: vi.fn((config: any) => Promise.resolve({ success: true, result: 'ok' })),
    put: vi.fn((config: any) => Promise.resolve({ success: true, result: 'ok' })),
    delete: vi.fn((config: any) => Promise.resolve({ success: true, result: 'ok' })),
  },
}))

import {
  queryWarehouseList, addWarehouse, editWarehouse, deleteWarehouse,
  deleteBatchWarehouse, queryAllWarehouse, deactivateWarehouse,
  activateWarehouse, saveOrUpdateWarehouse, getExportUrl, getImportUrl,
} from '@/views/project/mes/basic/warehouse/warehouse.api'
import { defHttp } from '/@/utils/http/axios'

const mockedGet = defHttp.get as any
const mockedPost = defHttp.post as any
const mockedPut = defHttp.put as any
const mockedDelete = defHttp.delete as any

function clearMocks() {
  mockedGet.mockClear(); mockedPost.mockClear(); mockedPut.mockClear(); mockedDelete.mockClear()
}

describe('仓库模块 API 封装', () => {
  beforeEach(() => clearMocks())

  describe('基础 CRUD', () => {
    it('queryWarehouseList 应调用 GET /mes/basic/warehouse/list', async () => {
      const params = { pageNo: 1, pageSize: 10 }
      await queryWarehouseList(params)
      expect(defHttp.get).toHaveBeenCalledWith({ url: '/mes/basic/warehouse/list', params })
    })

    it('addWarehouse 应调用 POST /mes/basic/warehouse/add', async () => {
      const params = { code: 'WH-001', name: '原料仓' }
      await addWarehouse(params)
      expect(defHttp.post).toHaveBeenCalledWith({ url: '/mes/basic/warehouse/add', params })
    })

    it('editWarehouse 应调用 PUT /mes/basic/warehouse/edit', async () => {
      const params = { id: '123', code: 'WH-001', name: '原料仓(已编辑)' }
      await editWarehouse(params)
      expect(defHttp.put).toHaveBeenCalledWith({ url: '/mes/basic/warehouse/edit', params })
    })

    it('deleteWarehouse 应调用 DELETE，参数拼接到 URL', async () => {
      const params = { id: '123' }
      await deleteWarehouse(params)
      expect(defHttp.delete).toHaveBeenCalledWith({ url: '/mes/basic/warehouse/delete', params }, { joinParamsToUrl: true })
    })

    it('deleteBatchWarehouse 应调用 DELETE /mes/basic/warehouse/deleteBatch', async () => {
      const params = { ids: '1,2,3' }
      await deleteBatchWarehouse(params)
      expect(defHttp.delete).toHaveBeenCalledWith({ url: '/mes/basic/warehouse/deleteBatch', params }, { joinParamsToUrl: true })
    })

    it('queryAllWarehouse 应调用 GET /mes/basic/warehouse/queryAll', async () => {
      await queryAllWarehouse()
      expect(defHttp.get).toHaveBeenCalledWith({ url: '/mes/basic/warehouse/queryAll' })
    })
  })

  describe('启用/停用', () => {
    it('deactivateWarehouse 应调用 PUT /mes/basic/warehouse/deactivate', async () => {
      const params = { id: '123' }
      await deactivateWarehouse(params)
      expect(defHttp.put).toHaveBeenCalledWith({ url: '/mes/basic/warehouse/deactivate', params }, { joinParamsToUrl: true })
    })

    it('activateWarehouse 应调用 PUT /mes/basic/warehouse/activate', async () => {
      const params = { id: '123' }
      await activateWarehouse(params)
      expect(defHttp.put).toHaveBeenCalledWith({ url: '/mes/basic/warehouse/activate', params }, { joinParamsToUrl: true })
    })
  })

  describe('saveOrUpdateWarehouse', () => {
    it('新增时调用 POST add', async () => {
      const params = { code: 'WH-001', name: '新仓库' }
      await saveOrUpdateWarehouse(params, false)
      expect(defHttp.post).toHaveBeenCalledWith({ url: '/mes/basic/warehouse/add', params })
    })

    it('编辑时调用 PUT edit', async () => {
      const params = { id: '123', code: 'WH-001', name: '已编辑仓库' }
      await saveOrUpdateWarehouse(params, true)
      expect(defHttp.put).toHaveBeenCalledWith({ url: '/mes/basic/warehouse/edit', params })
    })
  })

  describe('导出/导入 URL', () => {
    it('导出导入 URL 为常量路径', () => {
      expect(getExportUrl).toBe('/mes/basic/warehouse/exportXls')
      expect(getImportUrl).toBe('/mes/basic/warehouse/importExcel')
    })
  })
})

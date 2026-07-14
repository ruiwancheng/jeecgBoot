import { http, HttpResponse } from 'msw';

const BASE = '/jeecg-boot/mes/basic/warehouse';

interface WarehouseRecord {
  id: string;
  code: string;
  name: string;
  status: number;
  createBy: string;
  createTime: string;
}

let store: WarehouseRecord[] = [
  { id: '1', code: 'WH-001', name: '原料仓库', status: 1, createBy: 'admin', createTime: '2025-01-01 00:00:00' },
  { id: '2', code: 'WH-002', name: '成品仓库', status: 1, createBy: 'admin', createTime: '2025-01-02 00:00:00' },
  { id: '3', code: 'WH-003', name: '半成品仓库', status: 0, createBy: 'admin', createTime: '2025-01-03 00:00:00' },
];

export const warehouseHandlers = [
  http.get(`${BASE}/list`, ({ request }) => {
    const url = new URL(request.url);
    const code = url.searchParams.get('code') || '';
    const name = url.searchParams.get('name') || '';
    const pageNo = parseInt(url.searchParams.get('pageNo') || '1');
    const pageSize = parseInt(url.searchParams.get('pageSize') || '10');
    let filtered = [...store];
    if (code) filtered = filtered.filter((r) => r.code.includes(code));
    if (name) filtered = filtered.filter((r) => r.name.includes(name));
    const start = (pageNo - 1) * pageSize;
    return HttpResponse.json({ success: true, code: 200, result: { records: filtered.slice(start, start + pageSize), total: filtered.length } });
  }),

  http.get(`${BASE}/queryAll`, () => {
    return HttpResponse.json({ success: true, code: 200, result: store });
  }),

  http.post(`${BASE}/add`, async ({ request }) => {
    const body = (await request.json()) as Record<string, unknown>;
    const params = body.params || body;
    const exists = store.find((r) => r.code === params.code);
    if (exists) return HttpResponse.json({ success: false, code: 500, message: '仓库编码已存在' });
    const record = { id: `${Date.now()}`, ...params, createBy: 'admin', createTime: new Date().toISOString() };
    store.push(record);
    return HttpResponse.json({ success: true, code: 200, message: '添加成功', result: record });
  }),

  http.put(`${BASE}/edit`, async ({ request }) => {
    const body = (await request.json()) as Record<string, unknown>;
    const params = body.params || body;
    store = store.map((r) => (r.id === params.id ? { ...r, ...params } : r));
    return HttpResponse.json({ success: true, code: 200, message: '编辑成功' });
  }),

  http.delete(`${BASE}/delete`, ({ request }) => {
    const url = new URL(request.url);
    const id = url.searchParams.get('id') || '';
    store = store.filter((r) => r.id !== id);
    return HttpResponse.json({ success: true, code: 200, message: '删除成功' });
  }),

  http.delete(`${BASE}/deleteBatch`, ({ request }) => {
    const url = new URL(request.url);
    const ids = (url.searchParams.get('ids') || '').split(',');
    store = store.filter((r) => !ids.includes(r.id));
    return HttpResponse.json({ success: true, code: 200, message: '批量删除成功' });
  }),

  http.put(`${BASE}/deactivate`, ({ request }) => {
    const url = new URL(request.url);
    const id = url.searchParams.get('id') || '';
    store = store.map((r) => (r.id === id ? { ...r, status: 0 } : r));
    return HttpResponse.json({ success: true, code: 200, message: '停用成功' });
  }),

  http.put(`${BASE}/activate`, ({ request }) => {
    const url = new URL(request.url);
    const id = url.searchParams.get('id') || '';
    store = store.map((r) => (r.id === id ? { ...r, status: 1 } : r));
    return HttpResponse.json({ success: true, code: 200, message: '启用成功' });
  }),
];

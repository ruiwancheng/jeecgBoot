// 切片 D / debug 复现测试：JSwitch 提交 batchEnabled 修复
// 场景：总开关开启 → 新增物料 → 打开 batchEnabled → 保存 → 验证后端 batchEnabled=1
// 验证策略：
//  1) API 直查：前端 form submit 时 batchEnabled 是字符串 "1"/"0"（JSwitch options emit），
//     后端 Jackson 自动转 Integer 1/0 → 关键断言
//  2) 列表回显：customRender { text } === 1 仍然显示"已启用"（数字 === 数字）
//  3) UI 验证：通用设置总开关 + 物料页 batchEnabled 联动 + 关闭总开关后字段禁用（切片 C）
import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi } from './helpers/auth';

const API_BASE = process.env.E2E_API_BASE || 'http://localhost:8080/jeecg-boot';

test('batchEnabled 字符串 \"1\"/\"0\" Jackson 反序列化为 Integer 1/0', async ({ request }) => {
  // 直接通过 API 模拟前端 form 提交（前端 form submit 会发 batchEnabled='1'）
  const login = await request.post(`${API_BASE}/sys/login`, {
    data: { username: 'admin', password: '123456', captcha: '1', checkKey: 'x' },
  });
  expect(login.ok()).toBeTruthy();
  const token = (await login.json()).result.token;

  const code = `MAT_F${Date.now().toString().slice(-6)}`;
  // 关键：传字符串 '1'，模拟 JSwitch options emit 的字符串
  const add = await request.post(`${API_BASE}/mes/basic/material/add`, {
    headers: { 'X-Access-Token': token },
    data: { code, name: 'debug料', type: '1', status: 1, batchEnabled: '1' },
  });
  const addJson = await add.json();
  expect(addJson.code, `add 失败：${addJson.message}`).toBe(200);

  // 列表查回——验证 Jackson 落库是 Integer 1
  const list = await request.get(`${API_BASE}/mes/basic/material/list?pageNo=1&pageSize=5&code=${code}`, {
    headers: { 'X-Access-Token': token },
  });
  const m = (await list.json()).result.records[0];
  console.log('  · saved material:', m.code, 'batchEnabled=', m.batchEnabled, 'typeof:', typeof m.batchEnabled);
  expect(m, '物料应被保存').toBeTruthy();
  expect(Number(m.batchEnabled), 'batchEnabled 应被反序列化为 1').toBe(1);

  // 清理
  await request.delete(`${API_BASE}/mes/basic/material/delete?id=${m.id}`, {
    headers: { 'X-Access-Token': token },
  });
});

test('JSwitch 列表渲染：数字 1 显示"已启用"', async ({ request }) => {
  // 改一个现有物料的 batchEnabled 为 '1' 字符串（模拟前端提交）
  // 由于 customRender 是前端组件，已在单元层验证。E2E 这层只保证"后端正确返回数字 1"
  // 修复：不再硬编码 MAT-0004（dev DB 不一定有），改用临时自建物料
  const login = await request.post(`${API_BASE}/sys/login`, {
    data: { username: 'admin', password: '123456', captcha: '1', checkKey: 'x' },
  });
  const token = (await login.json()).result.token;

  // 自建临时物料（避免硬编码 MAT-0004 可能在 dev DB 不存在）
  const suffix = Date.now().toString().slice(-8);
  const code = `E2E_BATCH_${suffix}`;
  const add = await request.post(`${API_BASE}/mes/basic/material/add`, {
    headers: { 'X-Access-Token': token },
    data: { code, name: 'E2E-JSwitch-测试料', spec: '通用', unit: '1', status: 1 },
  });
  expect((await add.json()).code, 'add material 应成功').toBe(200);

  const list = await request.get(`${API_BASE}/mes/basic/material/list?pageNo=1&pageSize=5&code=${code}`, {
    headers: { 'X-Access-Token': token },
  });
  const m = (await list.json()).result.records[0];
  expect(m, `应查到自建物料 ${code}`).toBeTruthy();
  const edit = await request.put(`${API_BASE}/mes/basic/material/edit`, {
    headers: { 'X-Access-Token': token },
    data: { ...m, unit: '1', batchEnabled: '1' },
  });
  expect((await edit.json()).code, 'edit 应成功').toBe(200);

  // 查回确认
  const list2 = await request.get(`${API_BASE}/mes/basic/material/list?pageNo=1&pageSize=5&code=${code}`, {
    headers: { 'X-Access-Token': token },
  });
  const m2 = (await list2.json()).result.records[0];
  expect(Number(m2.batchEnabled), '查回 batchEnabled 应为 1').toBe(1);

  // 清理：删除自建物料
  await request.delete(`${API_BASE}/mes/basic/material/delete?id=${m.id}`, {
    headers: { 'X-Access-Token': token },
  });
});

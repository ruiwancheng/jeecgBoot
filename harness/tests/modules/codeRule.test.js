#!/usr/bin/env node
// MES 编码规则模块 API 测试 — 编码规则与单据绑定验证
// Usage: node harness/tests/modules/codeRule.test.mjs

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const ADMIN = { username: 'admin', password: '123456' };
let token = '';
let passed = 0, failed = 0;

function req(method, path, data) {
  let url = `${BASE}${path}`;
  if (method === 'DELETE' && data) url += '?' + new URLSearchParams(data).toString();
  const opts = { method, headers: { 'Content-Type': 'application/json', 'X-Access-Token': token } };
  if ((method === 'POST' || method === 'PUT') && data) opts.body = JSON.stringify(data);
  return fetch(url, opts).then(r => r.json()).catch(e => ({ code: -1, message: 'NETWORK_ERROR ' + e.message }));
}
const get = (p, params) => req('GET', p + (params ? '?' + new URLSearchParams(params) : ''));
const post = (p, d) => req('POST', p, d);
const put = (p, d) => req('PUT', p, d);

function check(name, cond, evidence) {
  if (cond) { passed++; console.log(`✓ ${name} — ${evidence}`); }
  else { failed++; console.log(`✗ ${name} — ${evidence}`); }
}

// 0. 登录
const login = await post('/sys/login', ADMIN);
token = login?.result?.token || '';
check('登录', !!token, token ? '获取 token 成功' : JSON.stringify(login));
if (!token) process.exit(1);

// 1. 规则列表：10 条规则 + bizType + 字典翻译
const EXPECTED = { SO: '销售订单', PO: '采购订单', MO: '生产订单', DN: '发货单', OB: '销售出库单', PR: '采购收货单', PP: '生产领料单', MC: '完工入库单', SI: '销售发票', PI: '采购发票' };
const list = await get('/mes/basic/codeRule/list', { pageNo: 1, pageSize: 50 });
const records = list?.result?.records || [];
check('规则列表总数≥10', records.length >= 10, `实际 ${records.length} 条（随业务增长，不断言精确值）`);
const missing = [], noDict = [];
for (const [rc, name] of Object.entries(EXPECTED)) {
  const r = records.find(x => x.ruleCode === rc);
  if (!r) { missing.push(rc); continue; }
  if (r.bizType !== rc || !r.bizType_dictText) noDict.push(rc);
}
check('10 条规则全部存在', missing.length === 0, missing.length ? `缺失: ${missing}` : 'SO/PO/MO/DN/OB/PR/PP/MC/SI/PI 齐全');
check('适用单据+字典翻译齐全', noDict.length === 0, noDict.length ? `异常: ${noDict}` : '每条均有 bizType 和中文翻译');

// 2. 取号：10 个规则编码格式正确
for (const rc of Object.keys(EXPECTED)) {
  const r = await get('/mes/basic/codeRule/nextCode', { ruleCode: rc });
  const code = r?.result || '';
  const ok = r?.success && new RegExp(`^${rc}\\d{8}-\\d{4}$`).test(code);
  check(`取号 ${rc}`, ok, ok ? code : JSON.stringify(r).slice(0, 120));
}

// 3. 取号-规则不存在：明确报错而非自动创建
const before = (await get('/mes/basic/codeRule/list', { pageNo: 1, pageSize: 50 }))?.result?.total;
const bad = await get('/mes/basic/codeRule/nextCode', { ruleCode: 'NOT_EXIST_XX' });
check('未知规则明确报错', bad?.success === false && /不存在/.test(bad?.message || ''), bad?.message);
const after = (await get('/mes/basic/codeRule/list', { pageNo: 1, pageSize: 50 }))?.result?.total;
check('未自动创建垃圾规则', before === after, `调用前 ${before} 条 / 调用后 ${after} 条`);

// 4. CRUD：新增→编辑→删除 临时规则（每次用独立编码，避免软删唯一索引 (rule_code,del_flag) 冲突）
const TMP = 'T' + String(Date.now()).slice(-6);
const tmp = { ruleCode: TMP, ruleName: '测试规则(自动化)', prefix: 'TST', dateFormat: 'yyyyMMdd', seqLength: 4, resetCycle: 'DAILY', bizType: 'OTHER' };
const add = await post('/mes/basic/codeRule/add', tmp);
check('新增规则', add?.success === true, add?.message);
const q = await get('/mes/basic/codeRule/list', { ruleCode: TMP });
const tmpRec = q?.result?.records?.[0];
const edit = await put('/mes/basic/codeRule/edit', { ...tmpRec, ruleName: '测试规则(已改)' });
check('编辑规则', edit?.success === true, edit?.message);
const tst = await get('/mes/basic/codeRule/nextCode', { ruleCode: TMP });
check('临时规则取号', tst?.success && /^TST\d{8}-\d{4}$/.test(tst?.result || ''), tst?.result || tst?.message);
const del = await req('DELETE', '/mes/basic/codeRule/delete', { id: tmpRec?.id });
check('删除规则', del?.success === true, del?.message);

// 5. 汇总
console.log(`\n===== 结果: ${passed} 通过 / ${failed} 失败 =====`);
process.exit(failed ? 1 : 0);

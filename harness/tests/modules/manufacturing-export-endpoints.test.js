#!/usr/bin/env node
// 生产链路 /exportXls 导出测试补齐 — slice-9
// 覆盖 4 端点：BOM、生产订单、领料单、入库单。
// 不解析 Excel 内容，仅验证状态、类型、非空响应体和文件魔数。

const { createClient } = require('../helpers/api');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const c = createClient(BASE);

const EXPORTS = [
  { index: 1, name: 'BOM', path: '/mes/manufacturing/bom/exportXls' },
  { index: 2, name: 'Order', path: '/mes/manufacturing/order/exportXls' },
  { index: 3, name: 'Picking', path: '/mes/manufacturing/picking/exportXls' },
  { index: 4, name: 'Completion', path: '/mes/manufacturing/completion/exportXls' },
];

function hasExcelMagic(buf) {
  const isXlsx = buf.length >= 4
    && buf[0] === 0x50 && buf[1] === 0x4b
    && buf[2] === 0x03 && buf[3] === 0x04;
  const isXls = buf.length >= 3
    && buf[0] === 0xd0 && buf[1] === 0xcf && buf[2] === 0x11;
  return isXlsx || isXls;
}

async function testExport({ index, name, path }) {
  console.log(`\n━━━ [${index}.1] ${name} 导出 ━━━`);
  const r = await fetch(`${BASE}${path}`, {
    headers: { 'X-Access-Token': c.token },
  });
  const contentType = r.headers.get('content-type') || '';
  const buf = Buffer.from(await r.arrayBuffer());
  const detail = `status=${r.status} type=${contentType || '(empty)'} size=${buf.length}B`;

  c.check(`[${index}.1] ${name} 导出 status=200`, r.status === 200, detail);
  c.check(`[${index}.1.类型] ${name} Content-Type 是 Excel`,
    /vnd\.ms-excel|spreadsheetml/i.test(contentType), detail);
  c.check(`[${index}.1.大小] ${name} body size > 0`, buf.length > 0, detail);
  c.check(`[${index}.1.魔数] ${name} 文件头是 xlsx/xls`, hasExcelMagic(buf),
    `${detail} magic=${buf.subarray(0, 4).toString('hex') || '(empty)'}`);
}

(async () => {
  await c.login('admin', '123456');
  console.log('✅ 登录成功');

  for (const endpoint of EXPORTS) {
    await testExport(endpoint);
  }

  const ok = c.summary('生产链路 /exportXls 4 端点');
  process.exit(ok ? 0 : 1);
})().catch((e) => {
  console.error('❌ 测试异常:', e);
  process.exit(2);
});

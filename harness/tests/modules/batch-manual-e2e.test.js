// 切片 E2 端到端测试：createBatchWithManualNo 6 个场景
const { createClient } = require('../helpers/api');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';

(async () => {
  const c = createClient(BASE);
  await c.login('admin', '123456');
  console.log('\n===== E2 端到端：createBatchWithManualNo =====\n');

  // 物料
  const matList = (await c.api('GET', '/mes/basic/material/list?pageNo=1&pageSize=2')).result.records;
  const matA = matList[0];
  const matB = matList[1];
  console.log('matA:', matA.code, 'matB:', matB.code);

  const ts = Date.now();

  // S1: 手工录入 batchNo
  const r1 = await c.api('POST', '/mes/batch/master/add', {
    materialId: matA.id, batchNo: 'TEST-A-' + ts, originType: '3', qty: 10, unitCost: 5.0,
  });
  c.check('S1 手工录入 batchNo', r1.code === 200, r1.message || 'ok');

  // S2: 同物料同 batchNo 重复 → 应报错
  const r2a = await c.api('POST', '/mes/batch/master/add', {
    materialId: matA.id, batchNo: 'DUP-' + ts, originType: '3', qty: 5,
  });
  c.check('S2a 第一次创建', r2a.code === 200, r2a.message);
  const r2b = await c.api('POST', '/mes/batch/master/add', {
    materialId: matA.id, batchNo: 'DUP-' + ts, originType: '3', qty: 5,
  });
  c.check('S2b 同物料同 batchNo 重复', r2b.code === 500 && r2b.message?.includes('已存在'), r2b.message);

  // S3: 不同物料同 batchNo → 应都成功
  const r3a = await c.api('POST', '/mes/batch/master/add', {
    materialId: matA.id, batchNo: 'SHARED-' + ts, originType: '3', qty: 5,
  });
  const r3b = await c.api('POST', '/mes/batch/master/add', {
    materialId: matB.id, batchNo: 'SHARED-' + ts, originType: '3', qty: 5,
  });
  c.check('S3a A 物料 同号', r3a.code === 200, r3a.message);
  c.check('S3b B 物料 同号(允许)', r3b.code === 200, r3b.message);

  // S4: batchNo 为空 → 走兜底自动生成
  const r4 = await c.api('POST', '/mes/batch/master/add', {
    materialId: matA.id, originType: '3', qty: 5,
  });
  c.check('S4 batchNo 为空(自动生成兜底)', r4.code === 200, r4.message);

  // S5: batchNo 超长 → 应报错
  const r5 = await c.api('POST', '/mes/batch/master/add', {
    materialId: matA.id, batchNo: 'X'.repeat(51), originType: '3', qty: 5,
  });
  c.check('S5 batchNo 超长(51字符)', r5.code === 500 && r5.message?.includes('50'), r5.message);

  // S6: batchNo 空串 → 走兜底自动生成
  const r6 = await c.api('POST', '/mes/batch/master/add', {
    materialId: matA.id, batchNo: '', originType: '3', qty: 5,
  });
  c.check('S6 batchNo 空串(自动生成兜底)', r6.code === 200, r6.message);

  // S7: list 验证
  const r7 = await c.api('GET', '/mes/batch/master/list?pageNo=1&pageSize=20');
  const all = r7.result.records || [];
  const testRecords = all.filter(r => r.batchNo && (r.batchNo.startsWith('TEST-') || r.batchNo.startsWith('DUP-') || r.batchNo.startsWith('SHARED-')));
  c.check('S7 测试批次记录可见', testRecords.length >= 3, `找到 ${testRecords.length} 条测试记录`);
  testRecords.forEach(r => {
    console.log(`  - batchNo=${r.batchNo} materialId=${r.materialId?.slice(-6)} qty=${r.qty}`);
  });

  // 清理：直接 SQL（不在 API 里——E2 是手工档 delete 权限较严）
  // 这里靠 migration V8.0.4（如果需要）或手工清

  c.summary('E2 createBatchWithManualNo');
})().catch((e) => { console.error('test err:', e); process.exit(1); });

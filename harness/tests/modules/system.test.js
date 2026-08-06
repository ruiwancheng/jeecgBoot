#!/usr/bin/env node
// MES System 模块 API 测试（gen-tests 自动生成版）
// 覆盖: MesGlobalSwitchController（全局开关 list / save / closeCheck / closeBatchSwitch）
// 关联: .claude/plans/2026-08-04-mes-regression-plan.md
// 约束: 业务代码不改；save/closeBatchSwitch 只测鉴权，不实际写入
// 规则: 内置 R001-R008 — R002(越权) R003(数值边界) R005(SQL注入) 命中

const { createClient } = require('../helpers/api');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const NO_PERM_USER = { username: 'guest', password: '123456' };
const BASE_PATH = '/mes/system/globalSwitch';

async function run() {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');

  console.log('\n===== MES System 模块 API 测试（gen-tests） =====\n');

  // 1. /list
  console.log('--- 1. /list 全局开关列表 ---');
  const r1 = await c.api('GET', `${BASE_PATH}/list`);
  c.check('1.1 list 200', r1.code === 200, `code=${r1.code}`);
  c.check('1.2 返回数组', Array.isArray(r1.result), `type=${typeof r1.result}`);
  if (Array.isArray(r1.result) && r1.result.length > 0) {
    const sw = r1.result[0];
    c.check('1.3 字段 switchKey 存在', 'switchKey' in sw, `keys=${Object.keys(sw).slice(0, 5).join(',')}`);
    // update-begin---author:pi---date:2026-08-07---for: Slice J — 测试期望对齐 API 实际字段（switchValue 而非 enabled）-----------
    c.check('1.4 字段 switchValue 存在', 'switchValue' in sw, `switchValue=${sw.switchValue}`);
    // update-end---author:pi---date:2026-08-07---for: Slice J — 测试期望对齐 API 实际字段（switchValue 而非 enabled）-----------
  } else {
    console.log('  ⚠️ 开关列表为空，跳过字段校验');
  }

  const allSwitches = Array.isArray(r1.result) ? r1.result : [];

  // 2. /closeCheck（前置检查，不执行关闭）
  console.log('\n--- 2. /closeCheck 关闭前置检查 ---');
  if (allSwitches.length > 0) {
    const swKey = allSwitches[0].switchKey;
    const r2 = await c.api('GET', `${BASE_PATH}/closeCheck?switchKey=${encodeURIComponent(swKey)}`);
    c.check('2.1 closeCheck 200', r2.code === 200, `code=${r2.code}`);
    c.check('2.2 返回结果对象', typeof r2.result === 'object' && r2.result !== null, `type=${typeof r2.result}`);
    if (r2.result) {
      // update-begin---author:pi---date:2026-08-07---for: Slice J — closeCheck 实际返回 canClose/errors 而非 hasError-----------
      c.check('2.3 含 canClose 字段', 'canClose' in r2.result, `keys=${Object.keys(r2.result).join(',')}`);
      // update-end---author:pi---date:2026-08-07---for: Slice J — closeCheck 实际返回 canClose/errors 而非 hasError-----------
    }

    const r2inv = await c.api('GET', `${BASE_PATH}/closeCheck?switchKey=non-existent-switch`);
    c.check('2.4 无效 switchKey 不崩溃', r2inv.code === 200, `code=${r2inv.code}`);
  } else {
    console.log('  ⚠️ 无开关数据，跳过 closeCheck 测试');
  }

  // 3. /save 鉴权（不真造数据）
  console.log('\n--- 3. /save 保存鉴权 ---');
  const rNoAuth = await fetch(BASE + `${BASE_PATH}/save`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}',
  });
  const rNoAuthJson = await rNoAuth.json();
  c.check('3.1 save 无 token 拒绝', rNoAuthJson.code === 401 || rNoAuthJson.code === 403, `code=${rNoAuthJson.code}`);

  const rEmpty = await c.api('POST', `${BASE_PATH}/save`, {});
  c.check('3.2 save 空 body 不崩', rEmpty.code === 200 || rEmpty.code === 500, `code=${rEmpty.code} msg=${rEmpty.message?.slice(0, 60)}`);

  // 4. /closeBatchSwitch 鉴权（高危操作 — 不实际调用）
  console.log('\n--- 4. /closeBatchSwitch 关闭生产批次总开关（仅鉴权） ---');
  const r4NoAuth = await fetch(BASE + `${BASE_PATH}/closeBatchSwitch`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
  });
  const r4NoAuthJson = await r4NoAuth.json();
  c.check('4.1 closeBatchSwitch 无 token 拒绝', r4NoAuthJson.code === 401 || r4NoAuthJson.code === 403, `code=${r4NoAuthJson.code}`);
  // 注释: closeBatchSwitch 是破坏性操作，回归测试只验证鉴权，不实际调用

  // 5. R002 无权限账号测试
  console.log('\n--- 5. R002 无权限账号 ---');
  const guest = createClient(BASE);
  try {
    await guest.login(NO_PERM_USER.username, NO_PERM_USER.password);
    const rg = await guest.api('GET', `${BASE_PATH}/list`);
    c.check('5.1 guest list 拒绝', rg.code === 401 || rg.code === 403, `code=${rg.code}`);
    const rg2 = await guest.api('GET', `${BASE_PATH}/closeCheck?switchKey=any`);
    c.check('5.2 guest closeCheck 拒绝', rg2.code === 401 || rg2.code === 403, `code=${rg2.code}`);
  } catch (e) {
    console.log(`  ⚠️ guest 账号不存在，跳过 (${e.message})`);
  }

  // 6. R005 特殊字符
  console.log('\n--- 6. R005 特殊字符 ---');
  const sqlCases = ["' OR '1'='1", '%test%', 'DROP', '<script>'];
  for (const sc of sqlCases) {
    const r = await c.api('GET', `${BASE_PATH}/list?switchKey=${encodeURIComponent(sc)}`);
    c.check(`6.${sqlCases.indexOf(sc) + 1} 特殊字符 "${sc.slice(0, 12)}..." 不崩`, r.code === 200, `code=${r.code}`);
  }

  // 总结
  const allPass = c.summary('System 模块');
  process.exit(allPass ? 0 : 1);
}

run().catch(err => { console.error('FATAL:', err); process.exit(2); });
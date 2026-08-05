// MES 仓库 activate/deactivate 状态机测试
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
let token = '';
const TS = Date.now();

async function login() {
  const r = await fetch(`${BASE}/sys/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' })
  }).then(res => res.json());
  if (r.code === 200) { token = r.result.token; console.log('✅ 登录成功'); }
  else throw new Error('登录失败: ' + r.message);
}

async function api(method, path, body) {
  const headers = { 'X-Access-Token': token };
  if (body) headers['Content-Type'] = 'application/json';
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  const r = await fetch(BASE + path, opts);
  return r.json();
}

function ass(cond, msg) {
  if (cond) console.log('✅ ' + msg);
  else { console.log('❌ ' + msg); process.exitCode = 1; }
}

async function run() {
  await login();
  console.log('\n=== 仓库 activate / deactivate ===');

  // 1. 创建一个测试仓库
  const whCode = 'WH_ACT_' + TS;
  const add = await api('POST', '/mes/basic/warehouse/add', {
    code: whCode, name: '激活测试仓', status: 1
  });
  ass(add.code === 200, '1. 创建仓库: ' + add.message);

  // 获取仓库 ID
  const list = await api('GET', '/mes/basic/warehouse/list?pageNo=1&pageSize=50');
  const wh = list.result?.records?.find(x => x.code === whCode);
  const wid = wh?.id || '';
  ass(wid !== '', '1b 获取仓库ID: ' + wid);

  if (!wid) { console.log('⚠ 创建失败，跳过'); return; }

  const initStatus = wh?.status;
  console.log('   初始状态: ' + initStatus);

  // 2. deactivate 停用
  const deact = await api('PUT', '/mes/basic/warehouse/deactivate?id=' + wid);
  ass(deact.code === 200, '2. deactivate 停用: ' + deact.message);

  // 3. 停用后状态验证
  const afterDeact = await api('GET', '/mes/basic/warehouse/queryById?id=' + wid);
  if (afterDeact.code === 200) {
    ass(afterDeact.result?.status === '0', '3. 停用后 status=0: 实际=' + afterDeact.result?.status);
  }

  // 4. activate 激活
  const act = await api('PUT', '/mes/basic/warehouse/activate?id=' + wid);
  ass(act.code === 200, '4. activate 激活: ' + act.message);

  // 5. 激活后状态验证
  const afterAct = await api('GET', '/mes/basic/warehouse/queryById?id=' + wid);
  if (afterAct.code === 200) {
    ass(afterAct.result?.status === '1', '5. 激活后 status=1: 实际=' + afterAct.result?.status);
  }

  // 6. 守卫：重复 activate 应成功（幂等）
  const act2 = await api('PUT', '/mes/basic/warehouse/activate?id=' + wid);
  ass(act2.code === 200, '6. 重复 activate 幂等: ' + act2.message);

  // 7. 守卫：重复 deactivate 应成功（幂等）
  const deact2 = await api('PUT', '/mes/basic/warehouse/deactivate?id=' + wid);
  ass(deact2.code === 200, '7. 重复 deactivate 幂等: ' + deact2.message);

  // 8. 清理
  const del = await api('DELETE', '/mes/basic/warehouse/delete?id=' + wid);
  if (del.code === 200) console.log('✅ 清理完成');
  else console.log('⚠ 清理失败: ' + del.message);

  console.log(process.exitCode ? '❌ 有失败项' : '✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });

#!/usr/bin/env node
// MES 采购链路 编排测试（按业务链路组织 v1）
// 链路: 采购申请 → 采购订单 → 采购入库 → 库存台账 → 应付生成 → 付款核销
// 角色: 编排文件（require 3 段文件 + 串联运行）
// 关联: hermes/business-chains.json 采购链路
//
// 段文件:
//   1. purchase-apply-order.chain.test.js   (申请→订单, 17 断言)
//   2. purchase-order-receipt.chain.test.js (订单→入库, 16 断言)
//   3. purchase-payment-flow.test.js        (采购→入库→付款, 跨财务)
//
// CI 调用: node chains/purchase-chain.test.js
// 触发: .github/workflows/functional-regression.yml api-test job 内 step

//update-begin---author:pi---date:2026-08-04---for:【BUG-1】编排器改为顺序 await 段文件 run()（之前 require 触发段文件 process.exit，段 2/3 从未跑过）-----------
console.log('\n━━━ 采购链路贯通测试 ━━━\n');

(async () => {
  try {
    console.log('段 1/3: 采购申请 → 采购订单');
    const ok1 = await require('./purchase-apply-order.chain.test.js').run();
    if (ok1 === false) { console.log('\n━━━ 采购链路贯通测试 失败（段 1）━━━'); process.exit(1); }

    console.log('\n段 2/3: 采购订单 → 采购入库');
    const ok2 = await require('./purchase-order-receipt.chain.test.js').run();
    if (ok2 === false) { console.log('\n━━━ 采购链路贯通测试 失败（段 2）━━━'); process.exit(1); }

    console.log('\n段 3/3: 采购→入库→付款（跨财务）');
    const ok3 = await require('./purchase-payment-flow.test.js').run();
    if (ok3 === false) { console.log('\n━━━ 采购链路贯通测试 失败（段 3）━━━'); process.exit(1); }

    console.log('\n━━━ 采购链路贯通测试 完成（3 段全绿）━━━\n');
    console.log('验收要点:');
    console.log('  - 数据 ID 跨段传递（申请 ID → 订单 ID → 入库 ID）');
    console.log('  - 状态流转（草稿→审核→已审核）');
    console.log('  - 数据一致性（库存台账 vs 应付 vs 付款）');
    console.log('  - 关键路径（参见 hermes/business-chains.json criticalPaths）');
    console.log('\n  - 链路状态: healthy');
    console.log('  - 最近验证: 2026-08-04');
    console.log('  - 验证方法: /chain-test 采购链路\n');
  } catch (e) {
    console.error('编排器异常:', e);
    process.exit(2);
  }
})();
//update-end---author:pi---date:2026-08-04---for:【BUG-1】编排器改为顺序 await 段文件 run()（之前 require 触发段文件 process.exit，段 2/3 从未跑过）-----------
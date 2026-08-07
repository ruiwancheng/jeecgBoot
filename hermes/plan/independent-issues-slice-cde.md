# 独立问题修复 Plan (Slice C / D / E / F / G)

**作者**：pi
**日期**：2026-08-07
**前置**：harness-check 第 8 轴 / Phase 1+2+3+4 全部完成。剩余 5 个独立 issue 处理。
**目标范围**：9 failed 切片 + 4 smoke specs 漏调度 + 1 前端 Bug

---

## 1. 现状（pre-existing 全部）

### Slice C：3 个 e2e-* 切片 manifest 路径错（0.2s 快速失败）
- e2e-basic / e2e-biz / e2e-purchase-sales
- 错误：`Cannot find module '.../harness/harness/scripts/run-batch.js'`
- 根因：`cwd: "harness"` + `command: "harness/scripts/run-batch.js"` → 双重路径
- 修复：改 `cwd: "harness"` → `cwd: "."`（与 module-* 一致）
- 1 commit，< 5 分钟

### Slice D：4 个 module-* 切片测试失败（~14 个测试）
- module-basic-1: 3/12 失败（basic-batchLedger, basic-customer-supplier, basic-extra）
- module-basic-2: ?/? 失败（待查）
- module-extended: ?/? 失败（待查）
- module-final: 6/9 失败（stock-otherin, stocktake-global-switch, stocktake.test, system.test, traceability-batch-level, warehouse-activate）
- 根因：测试数据缺失 / 后端 API 变化 / 测试代码 bug
- 预估 1-3 commits（需逐个排查）

### Slice E：8.2-stocktake + 8.3 切片 E2E spec 错（6 个 spec 失败）
- 8.2-stocktake: listRes.result.records[0] - listRes.result is null
- 8.3: 6 个 spec 失败（materialBatch C.2 / traceabilityBatch 3+4 / purchaseReceiptBatch 等）
- 根因：E2E spec 期望 vs 实际 API 行为不一致
- 预估 1-3 commits

### Slice F：4 个 e2e/smoke spec 漏调度
- smoke-01/02/03/04.spec.ts 存在但 manifest 无 smoke 切片
- 当前 manifest 仅有 `smoke-api` + `smoke-e2e`（脚本类，非 spec）
- 修复：新增 `e2e-smoke` 切片调度 4 个 spec
- 1 commit，< 5 分钟

### Slice G：前端 WS URL Bug
- 文件：`jeecgboot-vue3/src/layouts/default/header/components/notify/index.vue:154`
- 错误：`unref(userStore.getUserInfo).id + "_" + wsClientId` → 用户未登录时 `id` 是 undefined → URL 含 `undefined_xxx`
- 修复：用 optional chaining + 早 return 守卫
- 1 commit，< 5 分钟

---

## 2. 执行顺序

按复杂度递增排序（C/F/G 先做，5 分钟/个；D/E 深度处理）：

1. **Batch 1** (3 commits)：C + F + G
2. **Batch 2** (1-3 commits)：D（module-* 测试）
3. **Batch 3** (1-3 commits)：E（8.2-stocktake + 8.3 E2E）

每 batch 完后跑一次全量回归验证修复效果。

---

## 3. 详细改动

### Batch 1：C + F + G

#### C: e2e-* 切片 cwd 修复
```diff
{
  "id": "e2e-basic",
  "name": "E2E batch-1: basic-* (16 个 spec)",
- "cwd": "harness",
+ "cwd": ".",
  "command": [
    "node",
    "harness/scripts/run-batch.js",
    "e2e",
    "basic"
  ]
}
```

类似修 e2e-biz + e2e-purchase-sales。

#### F: 新增 e2e-smoke 切片
```json
{
  "id": "e2e-smoke",
  "name": "E2E smoke tests (4 个 spec: login/user-list/role-list/logout)",
  "kind": "e2e",
  "cwd": "harness",
  "command": [
    "npx",
    "playwright",
    "test",
    "e2e/smoke/",
    "--workers=1"
  ],
  "timeout_seconds": 300,
  "requires": ["backend", "frontend"]
}
```

#### G: WS URL 守卫
```diff
- let userId = unref(userStore.getUserInfo).id + "_" + wsClientId;
+ const userInfo = unref(userStore.getUserInfo);
+ if (!userInfo?.id) {
+   console.warn('WebSocket 跳过：用户未登录');
+   return;
+ }
+ let userId = userInfo.id + "_" + wsClientId;
```

### Batch 2：D（module-* 测试）

需先逐个查根因。可能情况：
- 测试 fixture 缺数据 → 加 `setupFixture` 
- 后端 API 改了 endpoint → 改测试或恢复 API
- 测试代码 bug → 修测试

具体 case-by-case。

### Batch 3：E（E2E spec）

8.2-stocktake: `listRes.result.records[0]` - 后端返回 null（可能 list API 改了）
8.3: 6 个 spec 期望 vs 实际差异

需逐个查根因。

---

## 4. 验证

每个 batch 后跑全量回归：
```bash
python3 harness/scripts/resilient_regression.py start \
  --manifest harness/regression/recovery-plan.json
```

期望：failed 切片从 9 → 0（理想）或 0 → 1-2（保守）

---

## 5. 风险

| 风险 | 缓解 |
|---|---|
| C 修复触发新问题 | 仅改 cwd，命令不变 |
| F 新增 spec 运行慢 | 4 个 spec 各 ~10s，总 ~40s |
| G 修复影响在线用户 | 改前端行为，仅未登录用户跳过 WS |
| D 测试修复可能改后端契约 | 优先改测试；如需改后端，单独立 issue |
| E E2E 修复需前端配合 | spec 是测试期望，前端不动 |

**总体风险等级**：🟡 中（D/E 可能改后端/前端契约）

---

## 6. 验收

- [ ] Slice C: 3 个 e2e-* 切片 manifest cwd 修复，全部 passed
- [ ] Slice F: 4 smoke spec 调度切片新增，运行通过
- [ ] Slice G: WS URL bug 修复，未登录用户不再生成无效 URL
- [ ] Slice D: module-* failed 数从 ~14 → 0
- [ ] Slice E: 8.2-stocktake + 8.3 failed spec 数从 6 → 0
- [ ] 全量回归最终：22 passed / ≤ 5 failed / 1 verdict（22 / ≤ 5 / 1）

---

## 7. 不做的（Out of Scope）

- 8.3 切片中 `purchaseReceiptBatch` S1/S2 标 `-` 跳过（非 ✘）的修复
- 完整 9 failed 切片根因追溯（如涉及后端 API 改动，单独立 issue）
- 测试覆盖率提升

---

## 8. 参考

- latest run: harness/.regression-runs/20260806-224035/
- Slice C: 失败日志 harness/.regression-runs/20260806-224035/logs/e2e-*.log
- Slice D: harness/.regression-runs/20260806-224035/logs/module-*.log
- Slice E: harness/.regression-runs/20260806-224035/logs/8.*.log
- Slice G: jeecgboot-vue3/src/layouts/default/header/components/notify/index.vue:154

## 9. Plan 修订记录

| 版本 | 日期 | 修订 | 来源 |
|---|---|---|---|
| v1 | 2026-08-07 | 初版 | PI /plan |
# 集成 gen-tests / chain-test / deploy-verify 时用 recovery-plan 自动展开，不要再硬编码 1.1~8.3

**触发条件：** 修改 `harness/regression/recovery-plan.json`、要新增业务链路切片、要把 deploy-verify 思想纳入回归时。

**处理方式：**
1. **不要把 1.1 / 1.2 / 1.3 这种切片 ID 写死在 recovery-plan.json**，而是让 runner 从 `hermes/business-chains.json` 的 `chains.<name>.chainTests.segments[].file` 自动展开。
2. **加 `regression_plan.py` builder**：
   - `expand_chain_slices(chains_doc)` → 把 `chainTests.enabled` 的 segment 转成 runner slice，id = `chain.<chain_id>.<index>`，并保留 `source = {chain, segment, file}` 用于后续 filter。
   - `merge_slices(manifest, extra)` → 已有 id 不重复添加，原有切片顺序保持在前。
   - `evaluate_test_quality(tests_root)` → 扫 `harness/tests/modules/*.test.js`，统计 `c.check/expect/assert` 与"语义断言"（`.code ===/!==`、`.status ===/!==`、`.startsWith`、`.quantity`、`.toBe`、`getByText`、`locator(`、`expect.toXxx`），计算 `quality_score`。
   - `filter_slices_by_scope(slices, scope, matched_chains)` → `--scope change` 只保留 build/frontend-static/test-quality/smoke-api/smoke-e2e + 命中链路的 segment。
   - `git_diff_names(base)` → `git diff --name-only <base>..HEAD`，写入 `manifest.diff_files`。
3. **runner 接受 `manifest.diff_files` 和 `manifest.scope`**，在 `execute_run` 起始把 `scope="change"` 走一次 `filter_slices_by_scope`。
4. **变更感知规则**：`f"/{diff_file}".find(f"/{module}/") != -1 or f"/{diff_file}".find(f"/{module}.") != -1 or diff_file.endswith(f"{module}.java")`。
5. **新增 runner 子命令 `plan`**：输出 `harness/regression/recovery-plan.merged.json`，并把 `merged_at` 写入；这个文件 `.gitignore`（不要进仓）。
6. **新增切片**：`frontend-static`（`pnpm run typecheck` / `npx vue-tsc --noEmit`，`verdict_when_failed: test_design_issue`）、`test-quality`（跑 `regression_plan.py report`）、`smoke-api`、`smoke-e2e`（变更感知模式的兜底冒烟）。

**实证：** 2026-08-04 把 `recovery-plan.json` 的 1.1/1.2/1.3 与 `business-chains.json` 的 segment 重复定义后，集成 builder 一次性解决：21 个切片、3 个 chain segment 自动展开、断言质量 60%、--scope change --base HEAD~1 只跑 7 个切片。

**配套：** 跑通测试质量门槛（`harness/tests/runner/test_regression_integration.py`）后，finance.test.js 等历史浅断言文件能直接看到 quality_score，下一轮 `/gen-tests` 就能定向补 R009 语义断言。

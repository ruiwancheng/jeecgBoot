# 2026-08-04 --scope change 三层复合 bug

## 现象

`resilient_regression.py start --scope change --base HEAD~6` 表面上成功（dashboard
200、telemetry 正常），但 `state.slices` 永远保留全部 20 个切片；只有 `summary.md`
正确显示 5 个被 filter 选中的切片。dashboard / `state.json` 都把 phantom
pending 切片当作真实切片暴露给用户。

## 根因（三层叠加）

1. **clobber 覆盖** —— `start` 流程最后两步：
   ```
   create_run(manifest, run_dir)         # 这里已经过滤并写 filtered manifest
   manifest = manifest_doc                # manifest_doc 是过滤前的（带 scope/diff_files）
   atomic_write_json(run_dir/manifest.json, manifest)   # 覆盖回未过滤
   ```
   `start` 用未过滤的 `manifest_doc` 把 `create_run` 已经过滤好的
   `run_dir/manifest.json` 又覆盖回去。任何在 create_run 里做的 filter 都被这一
   步抹掉。

2. **filter 顺序倒置** —— `execute_run` 和 `create_run` 都是：
   ```
   initial_state(manifest_unfiltered)   # 先用未过滤的 manifest 落 state
   manifest["slices"] = filter_slices_by_scope(...)   # 再过滤（已晚）
   ```
   state 已经在盘上了，`read_state` 会读到 phantom pending。loop 用的是
   `manifest["slices"]`（过滤后），所以实际执行的切片是对的，但 dashboard /
   state 报告永远是错的。

3. **filter_slices_by_scope 找不到 source.chain** —— `recovery-plan.json` 原始
   chain 切片（id=`1.1` / `1.2` / ...）**没有** `source` 字段，只有合并后的
   `recovery-plan.merged.json` 才有 `source.chain`。filter 函数查找的字段不存
   在，结果对所有 chain 都返回 false → 所有 chain 都被保留。
   - `start` 必须先调 `merge_slices(manifest, expand_chain_slices(load_chains_doc()))`
     才能让 filter 真正生效。

## 额外的次生 bug

- `from harness.scripts.regression_plan import filter_slices_by_scope`
  在 `harness/` 没有 `__init__.py` 时静默 ImportError，被 try/except 吞掉。
  改用裸 `regression_plan`（脚本目录自动入 sys.path[0]）。

- `start` 从未把 `--base` 持久化到 manifest_doc / state，导致 `resume` 时丢
  失变更基线。

## 修复策略（commit 7822a6f）

- `start` 先做 merge，再写装饰过的 manifest 到 temp file，让 `create_run` 用
  temp 作为 source（避免后续覆盖）。
- `create_run` 和 `execute_run` 都在 `initial_state` **之前**调 filter。
- `state["base"]` / `state["scope"]` / `state["matched_chains"]` 在
  `execute_run` 入口统一持久化（resume 也受益）。
- 加 test：`test_change_scope_filters_state_and_persists_base`，覆盖合并后
  plan 的真实 slice shape（`source.chain` 存在）。

## 验证

- 15/15 单测通过（was 14）
- 生产端到端：`start --scope change --base HEAD~6` 现在 state.slices = 5
  （0-build、frontend-static、test-quality、smoke-api、smoke-e2e），matched
  chains = ['basic-data']

## 教训

- 报告路径 (`summary.md`) 用 manifest slice 时，state 必须用同一份 slice 列表，
  否则报告与 state 会出现 5 vs 20 的不一致——这种 silent mismatch 很难复现。
- `try/except ImportError: pass` 是吞 bug 的好地方，要严格评估"这个包是否真的
  是可选的"。
- 不要在 `start` 末尾再 atomic_write 一次 `run_dir/manifest.json`：那是
  `create_run` 的所有权。`start` 的职责是构造 input（manifest_doc）然后
  把它交给 `create_run`。

## 相关

- 触发 commit: `7822a6f fix(harness): --scope change actually filters state.slices and persists base`
- 分支：`fix/regression-2026-08-04`
- 看板：8765（保留），8766/8767/8768/8769/8770/8773-8777 均为本轮调试产物，已清理

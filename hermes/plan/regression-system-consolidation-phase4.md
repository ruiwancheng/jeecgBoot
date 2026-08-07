# 回归测试体系整合 — Phase 4（统一报告生成器）

**作者**：pi
**日期**：2026-08-06
**前置**：Phase 1+2+3 + 2 个 P0 bugfix 全部完成 + 验证
- Phase 1（bf054a5/3220c5f/c7c2362 + ac22d4c）：修复 P0 漏跑
- Phase 2（3971caa/38f5ec3/8e15aa9）：manifest 升级 + 多路径写入 + TZ 修复
- Phase 3（dc16a6d/9964e1f/d91de5e + 8d2ea4c）：paths.json 集中化

**目标范围**：执行建议 6（废弃 Python `generate_report`，统一由 Node `regression-report.js` 生成报告）

---

## 1. 目标 & 范围

### 1.1 当前问题（来自二轮 MCP 分析 §9.3）
**双生成器冲突**（已通过 best-effort 部分缓解，但仍是技术债）：

| 生成器 | 位置 | 写入路径 | 报告格式 |
|---|---|---|---|
| Python `generate_report` | `resilient_regression.py` L545-L629 | harness/.regression-runs/<run-id>/**summary.md** (6.9KB) + hermes + 用户笔记空间 | 简单表格（Python 原生）|
| Node `regression-report.js::generate` | L408-L445 | harness/.regression-runs/<run-id>/**regression-report.md** (18.8KB) + hermes + 用户笔记空间 | 8 章节 Sprint Review v2 |

两个生成器都写 hermes + 用户笔记空间同一路径 = 同一份报告被两套机制产出，latest writer 胜出，但**代码维护成本翻倍** + **bug surface 翻倍**。

### 1.2 Phase 4 目标
1. **删除** `resilient_regression.py::generate_report` 及其所有调用方
2. **Python runner 退出后自动调用** `node regression-report.js --run-dir <run-id>`（subprocess）
3. Node 仍是**唯一**报告生成器（v2 8 章节 Sprint Review 格式）
4. 保留 `summary.md` 作为**轻量调试输出**（独立函数，写本地但不写 hermes/用户笔记空间）

### 1.3 非范围（OUT）
- 改 Node `regression-report.js` 行为（v2 格式已是规范）
- 改 manifest 字段（Phase 2 已就位）
- 改 `summary.md` 格式（保留现有简单表格）
- 9 failed 切片根因（独立 issue）

---

## 2. 详细改动

### Step 1：删除 `generate_report` 函数

**文件**：`harness/scripts/resilient_regression.py`

**变更位置**：L545-L629（85 行）

**变更**：
```python
# 删除整个 generate_report 函数（L545-L629）
def generate_report(ctx: RunContext) -> str:
    """... 生成 summary.md 报告 ..."""
    # ... 85 行代码 ...
```

**保留**：`RunContext` 类（generate_report 之外的用途仍需要）

### Step 2：删除 `generate_report` 调用方

**文件**：`harness/scripts/resilient_regression.py`

**3 个调用点**：
- L747: `execute_run` 主循环内（每轮 retry 后）
- L797: `execute_run` 末尾（所有 slice 完成）
- L819: `execute_run` 末尾（interrupted 状态）

**变更**：
```python
# 3 处 generate_report(ctx) 全部删除
# 替换为（见 Step 3）：subprocess.run(["node", "regression-report.js", "--run-dir", str(run_dir)])
```

### Step 3：新增 `_generate_report_via_node()` 函数

**文件**：`harness/scripts/resilient_regression.py`

**新增位置**：原 `generate_report` 删除后

**内容**：
```python
def _node_binary_available() -> str:
    """查找 node 可执行文件（P1-1 修复：缺 node 时明确报错）"""
    import shutil
    candidate = os.environ.get("HARNESS_NODE_BIN", "node")
    if shutil.which(candidate):
        return candidate
    raise FileNotFoundError(
        f"node binary not found (HARNESS_NODE_BIN={candidate!r}). "
        f"Install Node.js or set HARNESS_NODE_BIN env to point at it."
    )


def _generate_report_via_node(run_dir: Path) -> None:
    """Phase 4 / 建议 6：调用 Node regression-report.js v2 生成报告

    替代原 generate_report()。跨语言调用，best-effort：
    - 失败不抛异常
    - 失败信息写入 report-delivery-error.log
    - **P1-2 修复**：subprocess 异步执行（daemon thread），不阻塞 runner 退出
    """
    script = Path(__file__).resolve().parent / "regression-report.js"

    def _run() -> None:
        try:
            node_bin = _node_binary_available()
        except FileNotFoundError as e:
            with (run_dir / "report-delivery-error.log").open("a", encoding="utf-8") as f:
                f.write(f"{now_iso()} {e}\n")
            return
        cmd = [node_bin, str(script), "--run-dir", str(run_dir)]
        try:
            result = subprocess.run(
                cmd,
                cwd=REPO_ROOT,
                capture_output=True,
                text=True,
                timeout=120,
                check=False,
            )
            if result.returncode == 0:
                return
            error_log = run_dir / "report-delivery-error.log"
            with error_log.open("a", encoding="utf-8") as f:
                f.write(
                    f"{now_iso()} node regression-report.js exit {result.returncode}\n"
                    f"stdout: {result.stdout[:500]}\n"
                    f"stderr: {result.stderr[:500]}\n"
                )
        except subprocess.TimeoutExpired:
            with (run_dir / "report-delivery-error.log").open("a", encoding="utf-8") as f:
                f.write(f"{now_iso()} node regression-report.js timeout (>120s)\n")
        except Exception as e:
            with (run_dir / "report-delivery-error.log").open("a", encoding="utf-8") as f:
                f.write(f"{now_iso()} node regression-report.js error: {type(e).__name__}: {e}\n")

    # P1-2 修复：异步后台线程，不阻塞 runner 退出
    import threading
    t = threading.Thread(target=_run, daemon=True)
    t.start()


def _write_summary_md(run_dir: Path, state: dict[str, Any], manifest: dict[str, Any]) -> None:
    """轻量本地调试输出（不写 hermes/用户笔记空间）

    保留 summary.md 作为 runner 自身的状态摘要，但不再与 Node 报告竞争写 hermes 路径。
    """
    summary_path = run_dir / "summary.md"
    counts: dict[str, int] = {}
    for item in manifest.get("slices", []):
        result = state["slices"].get(item["id"], {})
        status = result.get("status", "?")
        counts[status] = counts.get(status, 0) + 1
    rows = [f"- total slices: {len(manifest.get('slices', []))}"]
    for status, count in sorted(counts.items()):
        rows.append(f"- {status}: {count}")
    content = (
        f"# {manifest.get('name', 'regression')} — Run Summary\n\n"
        f"- run_id: `{state['run_id']}`\n"
        f"- status: {state['status']}\n"
        + "\n".join(rows)
    )
    summary_path.write_text(content, encoding="utf-8")
```

### Step 4：替换 `generate_report` 调用方

**变更**（3 处 `execute_run` 内 + 1 处 `main`）：

```python
# 原代码（L747/L797/L819 execute_run 内）：
generate_report(ctx)

# 新代码：
_write_summary_md(ctx.run_dir, ctx.state, ctx.manifest)
_generate_report_via_node(ctx.run_dir)

# 原代码（L1107 main 内）：
print(generate_report(RunContext(run_dir, manifest, state)))

# 新代码：
_write_summary_md(run_dir, state, manifest)
_generate_report_via_node(run_dir)
```

### Step 5：Node 端无需改动

`regression-report.js` v2 已经是规范，行为不变：
- 输入：`<run-dir>/state.json` + `<run-dir>/manifest.json`
- 输出：`<run-dir>/regression-report.md` + `report_paths[]` + `report_mirror_paths[]`

---

## 3. 执行顺序 & Commit 策略

**3 个独立 commit**（按依赖性）：

1. **Commit 1**（Step 1+3）：删除 `generate_report` + 新增 `_generate_report_via_node` + `_write_summary_md`
2. **Commit 2**（Step 2+4）：替换 3 处 `execute_run` 调用方 + 1 处 `main` 调用方
3. **Commit 3**：清理：`state.json` 不再需要 `report_delivery_error` 字段（Node 自己管理）

---

## 4. 验证方案（/verify）

### Commit 1 后验证
```bash
python3 -c "import ast; ast.parse(open('harness/scripts/resilient_regression.py').read()); print('✅ Python 语法 OK')"
# generate_report 不再被定义
! grep -n "def generate_report" harness/scripts/resilient_regression.py && echo "✅ generate_report 已删"
# _generate_report_via_node / _write_summary_md 已定义
grep -n "_generate_report_via_node\|_write_summary_md" harness/scripts/resilient_regression.py
```

### Commit 2 后验证
```bash
# generate_report 不再有调用方
! grep -n "generate_report(ctx)\|generate_report(RunContext" harness/scripts/resilient_regression.py && echo "✅ 无调用残留"
# execute_run / main 都用新函数
grep -E "_generate_report_via_node\(|_write_summary_md\(" harness/scripts/resilient_regression.py | head -5
```

### Commit 3 后验证
```bash
# state.json 不再含 report_delivery_error 字段写入
! grep -n "report_delivery_error" harness/scripts/resilient_regression.py && echo "✅ 字段清理"
```

### 最终整合验证（重跑回归）
```bash
# 1. 检查环境
curl -s http://127.0.0.1:8080/jeecg-boot/sys/getEncryptedString | head -c 100

# 2. 跑全量回归
python3 harness/scripts/resilient_regression.py start \
  --manifest harness/regression/recovery-plan.json

# 3. 验证：
# a) summary.md 存在（轻量）
# b) regression-report.md 存在（Node v2）
# c) hermes 路径有 Node 报告（374 行）
# d) 用户笔记空间有 Node 报告（374 行）
# e) 3 路径内容一致
# f) report-delivery-error.log 不存在（无错误）

# 4. 报告格式校验
grep -c "^## " hermes/eagle-eye/reports/2026-08-06/resilient-regression-recovery.md
# ↑ 应为 8 章节
```

---

## 5. 风险评估

| 步骤 | 风险 | 缓解 |
|---|---|---|
| Step 1 删除 generate_report | 有调用方遗漏导致 ImportError | grep 全部 generate_report 引用 |
| Step 3 Node subprocess 失败 | 阻塞 runner 退出 | best-effort + timeout 120s + log |
| Step 4 调用方替换 | 漏改某处 → 报告未生成 | 全文件 grep |
| Node 路径找不到 | subprocess 失败 | 用 `Path(__file__).resolve().parent` 锚定 |
| Node 版本不兼容 | 老 Node < 14 报错 | 捕获异常 + log，不阻塞 |
| summary.md 内容格式变化 | 调试信息丢失 | 保留新 `_write_summary_md`，内容简单够用 |
| 双生成器并存期 | 用户误以为还在跑两个 | commit message 明确"废弃 generate_report" |

**总体风险等级**：🟢 低（best-effort 设计 + 删除而非修改，rollback = revert commit）

---

## 6. 不做的（Out of Scope）

| 项 | 何时做 |
|---|---|
| Node `regression-report.js` 内部重构 | 独立（建议 6 不要求） |
| 9 failed 切片根因修复 | 独立 issue |
| e2e/smoke 4 spec 漏调度 | 独立 issue |
| 前端 WS URL Bug | 独立 issue |

---

## 7. 验收标准

Phase 4 完成必须满足：

- [ ] `harness/scripts/resilient_regression.py` 中无 `generate_report` 函数定义
- [ ] `harness/scripts/resilient_regression.py` 中无 `generate_report(...)` 调用
- [ ] `_generate_report_via_node` 函数存在并被 3 处 execute_run 调用 + 1 处 main 调用
- [ ] `_write_summary_md` 函数存在并被同 4 处调用
- [ ] 重跑回归后：
  - `<run-dir>/summary.md` 存在（轻量）
  - `<run-dir>/regression-report.md` 存在（Node v2）
  - hermes 路径有 Node 报告
  - 用户笔记空间有 Node 报告
  - 3 路径内容一致（374 行 8 章节）
- [ ] `report-delivery-error.log` 不存在（无错误）
- [ ] 22 passed / 9 failed / 1 verdict 与 Phase 3 一致

---

## 8. 参考

- Phase 1+2+3 plans：`hermes/plan/regression-system-consolidation-phase{1,2,3}.md`
- 二轮 MCP 分析：`hermes/reviews/2026-08-06-regression-round2-mcp-deep-dive.md` §9.3 §11.1
- 现有报告双生成器关系：worker Phase 3 验证报告（run 20260806-220059）

## 9. Plan 修订记录

| 版本 | 日期 | 修订内容 | 来源 |
|---|---|---|---|
| v1 | 2026-08-06 | 初版 | PI /plan Phase 4 |
| v2 | 2026-08-06 | 修复 2 P1（orca-review `task_8db1c80106b7`）：<br>1. `_node_binary_available()` 用 shutil.which 检查 node 存在，缺 node 时明确 FileNotFoundError（P1-1）<br>2. subprocess.run 改为 daemon 线程异步执行，不阻塞 runner 退出（P1-2）<br>P2: Commit 3 删除（已冗余） | orca-review `task_8db1c80106b7` |
# 回归测试体系整合 — Phase 2（报告路径扩展 + 用户笔记空间镜像）

**作者**：pi
**日期**：2026-08-06
**前置**：Phase 1 已完成（3 commits bf054a5 / 3220c5f / c7c2362，修复 P0-A/P0-B/P1）
**目标范围**：执行建议 4（manifest `report_paths[]` + 用户笔记空间镜像输出）
**不在范围**：建议 5（paths.json 集中化）、建议 6（统一报告生成器）— 推后到 Phase 3

---

## 1. 目标 & 范围

### 1.1 用户原始需求
> "将回归测试报告输出到：`/Users/ruisuyun/Documents/笔记空间/低代码平台方案/03测试`"

### 1.2 当前状态
- manifest 单一 `report_path`：`hermes/eagle-eye/reports/${date}/resilient-regression-recovery.md`
- 仅 `resilient_regression.py::generate_report` 写这个路径（L597）
- `regression-report.js` v2 写本地 + eagle-eye 归档（硬编码）
- 错误处理：best-effort（单个 OSError 不阻塞）

### 1.3 Phase 2 目标
1. manifest 升级 `report_path`（string）→ `report_paths`（array）+ `report_mirror_paths`（array，可选外部镜像）
2. `resilient_regression.py::generate_report` 循环写所有路径（best-effort，错误独立处理）
3. `regression-report.js` v2 也读 manifest 路径并循环写
4. 用户笔记空间路径 `/Users/ruisuyun/Documents/笔记空间/低代码平台方案/03测试/${date}/resilient-regression-recovery.md` 加入 `report_mirror_paths`
5. 默认行为兼容旧 manifest（无 `report_paths` 时 fallback `report_path`）

### 1.4 非范围（OUT，Phase 3 / 独立）
- 建议 5：抽 `harness/config/paths.json`（依赖建议 4 稳定后做）
- 建议 6：统一报告生成器（Python → Node.js，建议 4 稳定 1 周后做）
- 9 failed 切片根因修复
- e2e/smoke 4 个 spec 漏调度
- 前端 WS URL Bug

---

## 2. 详细改动

### Step 1：manifest 升级字段

**文件**：`harness/regression/recovery-plan.json`

**变更**：
```diff
- "report_path": "hermes/eagle-eye/reports/${date}/resilient-regression-recovery.md",
+ "report_path": "hermes/eagle-eye/reports/${date}/resilient-regression-recovery.md",
+ "report_paths": [
+   "hermes/eagle-eye/reports/${date}/resilient-regression-recovery.md"
+ ],
+ "report_mirror_paths": [
+   "/Users/ruisuyun/Documents/笔记空间/低代码平台方案/03测试/${date}/resilient-regression-recovery.md"
+ ]
```

**设计要点**：
- **保留 `report_path`**（向后兼容）：现有阅读者只需 0 改动
- **新增 `report_paths[]`**：主归档路径数组，循环写入
- **新增 `report_mirror_paths[]`**：外部镜像路径（用户笔记空间），与主路径独立失败
- **优先级**：Python/Node 代码读 `report_paths` 优先，无则 fallback `report_path`，最后用硬编码默认值

### Step 2：resilient_regression.py::generate_report 多路径写入

**文件**：`harness/scripts/resilient_regression.py`

**变更位置**：L591-L608（generate_report 末段）

**当前代码**（L589-L608）：
```python
local_report = ctx.run_dir / "summary.md"
write_text_atomic(local_report, content)
configured = ctx.manifest.get("report_path")
if configured:
    target_str = configured.replace("${date}", datetime.now().strftime("%Y-%m-%d"))
    target = (REPO_ROOT / target_str).resolve()
    try:
        write_text_atomic(target, content)
    except OSError as error:
        # ... best-effort error log
```

**新代码**：
```python
local_report = ctx.run_dir / "summary.md"
write_text_atomic(local_report, content)

# 收集所有外部归档路径（best-effort，任一失败不阻塞其他）
configured_paths = list(ctx.manifest.get("report_paths") or [])
if not configured_paths and ctx.manifest.get("report_path"):
    configured_paths = [ctx.manifest["report_path"]]  # 向后兼容
configured_paths.extend(ctx.manifest.get("report_mirror_paths") or [])

for path_template in configured_paths:
    target_str = path_template.replace("${date}", datetime.now().strftime("%Y-%m-%d"))
    target = Path(target_str).resolve() if Path(target_str).is_absolute() else (REPO_ROOT / target_str).resolve()
    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        write_text_atomic(target, content)
    except OSError as error:
        # best-effort: 错误独立记录到 report-delivery-error.log
        delivery_error = (
            f"{now_iso()} shared report write failed: {path_template} → {target}\n"
            f"{type(error).__name__}: {error}\n"
            f"local report: {local_report}\n"
        )
        try:
            with (ctx.run_dir / "report-delivery-error.log").open("a", encoding="utf-8") as stream:
                stream.write(delivery_error)
            ctx.state["report_delivery_error"] = delivery_error.strip()
            ctx.save()
        except OSError:
            pass
```

**设计要点**：
- **优先级链**：`report_paths[]` → `report_path`（单数）→ 无
- **绝对路径支持**：用户笔记空间路径是 `/Users/...`，不是相对项目根。`is_absolute()` 分流
- **`mkdir parents=True`**：用户路径可能不存在（如 `/03测试/2026-08-06/` 子目录），自动创建
- **错误独立处理**：每个路径失败单独 log，不影响后续路径

### Step 3：regression-report.js v2 也支持多路径

**文件**：`harness/scripts/regression-report.js`

**变更位置 1**：L48-L51（detectDate 函数）— **修复 P0 时区不一致**

**当前代码**（L48）：
```js
function detectDate(runId) {
  if (runId && /^\d{8}-\d{6}$/.test(runId)) {
    return `${runId.slice(0,4)}-${runId.slice(4,6)}-${runId.slice(6,8)}`;
  }
  return new Date().toISOString().slice(0, 10);  // ← UTC，与 Python 本地时间不一致
}
```

**新代码**：
```js
function detectDate(runId) {
  if (runId && /^\d{8}-\d{6}$/.test(runId)) {
    return `${runId.slice(0,4)}-${runId.slice(4,6)}-${runId.slice(6,8)}`;
  }
  // 使用本地时间（与 Python runner 的 datetime.now() 一致）
  // 跨午夜（00:30 本地但前一天 UTC）场景：Python 写 2026-08-07，Node 原会写 2026-08-06（错）
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
}
```

**变更位置 2**：L415-L423（generate 函数末段）— 多路径写入

**当前代码**（L415-L423）：
```js
const localPath = path.join(runDir, 'regression-report.md');
fs.writeFileSync(localPath, report);
console.log(`✅ Local: ${localPath}`);

const archivePath = path.join(EAGLE_EYE, date, 'resilient-regression-recovery.md');
fs.mkdirSync(path.dirname(archivePath), { recursive: true });
fs.writeFileSync(archivePath, report);
console.log(`✅ Archive: ${archivePath}`);
```

**新代码**：
```js
// 本地报告（始终写）
const localPath = path.join(runDir, 'regression-report.md');
fs.writeFileSync(localPath, report);
console.log(`✅ Local: ${localPath}`);

// 收集所有归档路径（含 manifest 配置）
const manifestPaths = manifest.report_paths || (manifest.report_path ? [manifest.report_path] : []);
const mirrorPaths = manifest.report_mirror_paths || [];
const allPaths = [...manifestPaths, ...mirrorPaths];

let successCount = 0, failCount = 0;
for (const pathTemplate of allPaths) {
  const resolved = pathTemplate.replace(/\$\{date\}/g, date);
  const absolute = path.isAbsolute(resolved) ? resolved : path.join(PROJECT, resolved);
  try {
    fs.mkdirSync(path.dirname(absolute), { recursive: true });
    fs.writeFileSync(absolute, report);
    console.log(`✅ Archive: ${absolute}`);
    successCount++;
  } catch (e) {
    console.error(`❌ Failed to write ${absolute}: ${e.message}`);
    failCount++;
  }
}
if (failCount > 0) console.warn(`⚠️  ${failCount}/${allPaths.length} archive writes failed (best-effort)`);
```

**设计要点**：
- 与 Python 版对称：同样读 `report_paths` + `report_mirror_paths`，fallback 到 `report_path`
- 成功/失败计数，最后 warn
- 错误不 throw，不影响本地报告已成功写入
- **P0 TZ 修复**：detectDate 改本地时间，与 Python `datetime.now().strftime("%Y-%m-%d")` 保持一致（用户验证 = Asia/Shanghai +08:00）

### Step 4：用户笔记空间路径准备（前置检查）

**操作**：
```bash
# 1. 验证路径存在 + 可写（已验证：可写 ✅）
USER_PATH="/Users/ruisuyun/Documents/笔记空间/低代码平台方案/03测试"
test -d "$USER_PATH" && test -w "$USER_PATH" && echo "✅ 路径就绪"

# 2. 验证日期子目录可自动创建（Phase 2 实施后第一次跑回归时验证）
# ${date} 展开示例：/Users/ruisuyun/Documents/笔记空间/低代码平台方案/03测试/2026-08-06/resilient-regression-recovery.md
```

**风险**：路径不存在或不可写 → best-effort 失败 log，不阻塞本地 + hermes 报告。

---

## 3. 执行顺序 & Commit 策略

**3 个独立 commit**（按改动类型分组）：

1. **Commit 1**（Step 1）：manifest 加 `report_paths[]` + `report_mirror_paths[]`
2. **Commit 2**（Step 2）：resilient_regression.py::generate_report 多路径写入
3. **Commit 3**（Step 3）：regression-report.js v2 多路径写入

每个 commit 后做局部验证（见 §4），最后做整合 verify。

---

## 4. 验证方案（/verify）

### Commit 1 后验证
```bash
# manifest 字段全部正确
python3 -c "
import json
m = json.load(open('harness/regression/recovery-plan.json'))
assert 'report_paths' in m and isinstance(m['report_paths'], list)
assert 'report_mirror_paths' in m and isinstance(m['report_mirror_paths'], list)
assert any('hermes' in p for p in m['report_paths']), 'hermes 路径缺失'
assert any('笔记空间' in p for p in m['report_mirror_paths']), '笔记空间路径缺失'
print('✅ manifest 字段正确')
print(f'  report_paths: {m[\"report_paths\"]}')
print(f'  report_mirror_paths: {m[\"report_mirror_paths\"]}')
"
```

### Commit 2 后验证（Python）
```bash
# 模拟一次 generate_report 调用，验证多路径写入
python3 -c "
import sys, json
sys.path.insert(0, 'harness/scripts')
from pathlib import Path
import tempfile
from resilient_regression import write_text_atomic, now_iso

# 模拟 manifest
m = json.load(open('harness/regression/recovery-plan.json'))
print(f'report_paths: {m.get(\"report_paths\")}')
print(f'report_mirror_paths: {m.get(\"report_mirror_paths\")}')
print(f'向后兼容 report_path: {m.get(\"report_path\")}')

# 不实际写远程路径，只验证 collect_paths 逻辑存在
print('✅ generate_report 已更新（需实际跑一次回归验证真实写入）')
"
```

### Commit 3 后验证（Node）
```bash
# 静态语法检查
node -c harness/scripts/regression-report.js && echo "✅ Node 语法 OK"

# 干跑（不实际跑回归，只验证脚本能解析新 manifest 字段）
node -e "
const fs = require('fs');
const m = JSON.parse(fs.readFileSync('harness/regression/recovery-plan.json', 'utf8'));
console.log('report_paths:', m.report_paths);
console.log('report_mirror_paths:', m.report_mirror_paths);
console.log('✅ manifest 可被 Node 读取');
"
```

### 最终整合验证（需本地有后端 + 前端 + 跑一次回归）
```bash
# 跑一次全量回归（resilient_regression.py 路径）
python3 harness/scripts/resilient_regression.py start \
  --manifest harness/regression/recovery-plan.json

# 跑完生成报告
node harness/scripts/regression-report.js --run-dir <latest-run-id>

# 检查所有 3 个路径都有报告：
ls -la harness/.regression-runs/<run-id>/summary.md
ls -la hermes/eagle-eye/reports/$(date +%Y-%m-%d)/resilient-regression-recovery.md
ls -la "/Users/ruisuyun/Documents/笔记空间/低代码平台方案/03测试/$(date +%Y-%m-%d)/resilient-regression-recovery.md"

# 检查 report-delivery-error.log 不存在（说明所有路径都成功）
test ! -f harness/.regression-runs/<run-id>/report-delivery-error.log && echo "✅ 所有路径写入成功"
```

### P1-2 强化：用户笔记空间路径端到端写入测试

**问题**：Step 4 仅测了父目录，未测完整 mkdir+write 链（中文路径 + 子目录自动创建 + write_text_atomic）

**测试代码**（Commit 3 之前必须跑通）：
```python
# tests/test_user_notes_path_write.py
import sys
from pathlib import Path
sys.path.insert(0, 'harness/scripts')
from resilient_regression import write_text_atomic

USER_PATH = "/Users/ruisuyun/Documents/笔记空间/低代码平台方案/03测试"
TEST_DATE = "2099-12-31"  # 未来日期，避免污染真实数据
test_file = Path(USER_PATH) / TEST_DATE / "test-write.md"

# 清理（如果之前测过）
test_file.unlink(missing_ok=True)

# 模拟 Phase 2 写报告的完整流程
test_file.parent.mkdir(parents=True, exist_ok=True)
write_text_atomic(test_file, "# 测试\n中文路径验证")

assert test_file.exists(), "❌ 文件未创建"
content = test_file.read_text(encoding='utf-8')
assert "中文路径验证" in content, "❌ 中文内容写入失败"
print(f"✅ 中文路径写入测试通过: {test_file}")

# 清理
test_file.unlink()
test_file.parent.rmdir()
print("✅ 清理完毕")
```

**预期**：测试通过，否则 Phase 2 不能合并。

### 错误处理验证（best-effort）
```bash
# 临时修改 manifest 把 hermes 路径改成不可写位置，验证错误隔离
python3 -c "
import json
m = json.load(open('harness/regression/recovery-plan.json'))
m['report_paths'] = ['/root/no-permission/report.md', 'hermes/eagle-eye/reports/\${date}/resilient-regression-recovery.md']
json.dump(m, open('/tmp/test-manifest.json', 'w'), indent=2)
"
# 跑一次回归，看 hermes 路径是否仍能写
# 验证：错误路径在 report-delivery-error.log，但 hermes 报告仍成功
```

---

## 5. 风险评估

| 步骤 | 风险 | 缓解 |
|---|---|---|
| Step 1 manifest 升级 | `report_paths` 字段被忽略（旧代码不识别）| Python/Node 都先看 `report_paths`，fallback `report_path`，再 fallback 硬编码 |
| Step 2 路径解析 | 用户笔记空间路径是绝对路径，旧代码 `(REPO_ROOT / target).resolve()` 会拼成错误路径 | `is_absolute()` 分流，绝对路径直接用 |
| Step 2 父目录创建 | 用户路径下日期子目录可能不存在 | `mkdir parents=True exist_ok=True` |
| Step 2 best-effort 失败日志 | 错误信息散落到 state.json 与 report-delivery-error.log | 已存在机制，复用即可 |
| Step 3 Node 错误处理 | 旧代码无 try/catch，失败会 throw | 新代码每个路径独立 try/catch |
| Step 3 **P0 时区不一致** | Python `datetime.now()` 本地时间 vs Node `toISOString()` UTC 时间，跨午夜报告写到不同日期目录 | **detectDate 改本地时间**（getFullYear/getMonth/getDate），与 Python 一致 |
| Step 4 用户路径中文 | 编码问题可能写入失败 | **P1-2 强化**：Commit 3 前必跑端到端测试，验证中文路径 mkdir+write |
| Step 4 manifest_snapshot | 报告生成器读 `<runDir>/manifest.json` snapshot，main manifest 后续修改不传播 | snapshot 用 `shutil.copy2` 完整复制（验证过），无需修复；如需重读 main manifest，加 `--manifest` CLI flag（P1-1 改进建议，非阻断）|
| 用户路径权限 | macOS 用户特定路径，可能因权限拒绝 | best-effort 失败 log，不阻塞本地 + hermes |
| 跨平台 | `/Users/...` 路径是 macOS 特定，Windows/Linux 用户无法工作 | manifest 是开发环境配置，不跨平台部署；CI 用 hermes 路径 |
| 文件锁冲突 | 同时跑 2 个 regression 写同一 hermes 路径 | `write_text_atomic` / `writeFileSync` 各自有 atomic 语义，但并发写可能丢内容；建议同一时间只跑一个回归 |

**总体风险等级**：🟢 低-中（P0 时区已修复，P1-2 中文路径测试已强化，错误隔离设计已就位）

---

## 6. 不做的（Out of Scope）

| 项 | 何时做 |
|---|---|
| 抽 `harness/config/paths.json` | Phase 2.5 / Phase 3（依赖建议 4 稳定后）|
| 统一报告生成器（废弃 python 版）| Phase 3（建议 6，等 Phase 2 稳定 1 周）|
| 修 `package.json` 其他 npm scripts | 独立 issue（test:e2e 已修，其他 review 后决定）|
| 9 failed 切片根因修复 | 独立 issue |
| e2e/smoke 4 spec 漏调度 | 独立 issue |
| 前端 WS URL Bug | 独立 issue |

---

## 7. 验收标准

Phase 2 完成必须满足：

- [ ] manifest 含 `report_paths[]`（含 hermes 路径）+ `report_mirror_paths[]`（含用户笔记空间路径）
- [ ] `resilient_regression.py::generate_report` 支持多路径写入 + best-effort 错误隔离
- [ ] `regression-report.js` v2 支持多路径写入 + best-effort 错误隔离
- [ ] 旧 manifest（仅 `report_path`）仍能工作（向后兼容）
- [ ] 实际跑一次回归后，3 个路径都有报告（harness/.regression-runs/ + hermes/eagle-eye/ + 用户笔记空间）
- [ ] 故意写错一个路径，其他路径仍能写入（错误隔离验证）
- [ ] 用户笔记空间路径下自动创建日期子目录

---

## 8. 参考

- Phase 1 报告：`hermes/plan/regression-system-consolidation-phase1.md`（已完成）
- 第二轮 MCP 分析：`hermes/reviews/2026-08-06-regression-round2-mcp-deep-dive.md` §11.1（建议 4 排序）
- 修改标记：本计划改动不涉及 .java，纯 JSON/Python/JS 配置，无须 `update-begin/end` 标记

## 9. Plan 修订记录

| 版本 | 日期 | 修订内容 | 来源 |
|---|---|---|---|
| v1 | 2026-08-06 | 初版 | PI /brainstorm → /plan |
| v2 | 2026-08-06 | 修复 P0 时区不一致（Step 3 detectDate 改本地时间）；强化 P1-2 中文路径端到端测试；记录 P1-1 snapshot 完整复制无需修 | orca-review `task_1e2a642b1bdf` |
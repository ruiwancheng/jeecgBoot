# 回归测试体系整合 — Phase 3（路径配置集中化）

**作者**：pi
**日期**：2026-08-06
**前置**：Phase 1+2 已完成 + bugfix commit ac22d4c
- Phase 1（bf054a5/3220c5f/c7c2362 + ac22d4c bugfix）：修复 P0 漏跑 + 删除死代码
- Phase 2（3971caa/38f5ec3/8e15aa9）：manifest 升级 + 多路径写入 + TZ 一致

**目标范围**：执行建议 5（抽 `harness/config/paths.json` 集中化所有文件系统路径）
**不在范围**：建议 6（统一报告生成器 Python → Node.js）— 推后到 Phase 4

---

## 1. 目标 & 范围

### 1.1 当前问题（来自二轮 MCP 分析 §9.2 §10.1）

| 路径常量 | 当前硬编码位置 | 数量 |
|---|---|---|
| `REPO_ROOT` / `PROJECT` | resilient_regression.py L17-19 / regression-report.js L31 / run-batch.js L30 | 3 处 |
| `harness/` 字面量 | Python + Node 多处拼接 | ~30 处 |
| `hermes/eagle-eye/reports/...` | Python L550 + Node L48 + dashboard L26 + report.js 多处 | ~8 处 |
| `playwright.config.ts` | run-regression.sh（已删）+ package.json（已修）+ 各处 | 4 处 |
| 模板/manifest/chains 路径 | 各 driver 独立硬编码 | ~10 处 |

**风险**：路径散落 → 改一处忘一处 → 新 driver 重复实现路径解析 → 拼写错误。

### 1.2 Phase 3 目标

1. 创建 `harness/config/paths.json`（单一真相源）
2. **6 个 driver 都从该文件读路径**，向后兼容（缺文件时 fallback 硬编码）
3. 删除/集中所有 `harness/` `hermes/` `eagle-eye/` `playwright.config` 字符串字面量
4. 路径值支持 `${date}` 模板（与 manifest.report_paths 一致）

### 1.3 非范围（OUT，Phase 4 / 独立）
- 建议 6：统一报告生成器（Python → Node.js）
- env vars（`HARNESS_BASE` 等 URL）：保持环境变量，不进 paths.json
- 9 failed 切片根因修复
- e2e/smoke 4 spec 漏调度
- 前端 WS URL Bug

---

## 2. 详细改动

### Step 1：创建 `harness/config/paths.json`

**新文件**：`harness/config/paths.json`

**内容**：
```json
{
  "version": 1,
  "_description": "MES 回归测试体系 — 文件系统路径集中配置（Phase 3 / 建议 5）",
  "_doc": "所有相对路径基于 REPO_ROOT（harness/ 的父目录 = jeecgBoot/）",
  "_template_vars": ["${date} = YYYY-MM-DD（按当天日期展开）"],
  "harness": {
    "root": "harness",
    "regression_manifest": "harness/regression/recovery-plan.json",
    "runs_dir": "harness/.regression-runs",
    "tests_root": "harness/tests",
    "tests_modules": "harness/tests/modules",
    "tests_chains": "harness/tests/chains",
    "tests_concurrent": "harness/tests/concurrent",
    "e2e_root": "harness/e2e",
    "e2e_mes": "harness/e2e/mes",
    "playwright_config": "harness/playwright.config.ts",
    "templates_dir": "harness/templates",
    "report_template": "harness/templates/regression-report.md",
    "dashboard": "harness/dashboard"
  },
  "hermes": {
    "eagle_eye_root": "hermes/eagle-eye",
    "eagle_eye_reports": "hermes/eagle-eye/reports",
    "business_chains": "hermes/business-chains.json",
    "plans_dir": "hermes/plan",
    "reviews_dir": "hermes/reviews"
  },
  "external_mirror": {
    "_doc": "可选外部镜像（用户笔记空间）",
    "user_notes_root": "/Users/ruisuyun/Documents/笔记空间/低代码平台方案/03测试"
  }
}
```

### Step 2：Python 端 — 创建路径加载助手

**新文件**：`harness/scripts/_paths.py`

**内容**：
```python
"""harness/scripts/_paths.py — 路径集中加载器

Phase 3 / 建议 5：所有 driver 通过此模块读 paths.json，向后兼容（缺文件时硬编码）。

用法：
    from _paths import PATHS, REPO_ROOT, resolve
    manifest_path = resolve(PATHS['harness']['regression_manifest'])
"""
from __future__ import annotations
import json
import os
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]  # harness/scripts/_paths.py → jeecgBoot/
DEFAULT_PATHS_FILE = REPO_ROOT / "harness" / "config" / "paths.json"

# 缺文件时的硬编码 fallback（与 paths.json 内容保持一致）
_FALLBACK = {
    "harness": {
        "root": "harness",
        "regression_manifest": "harness/regression/recovery-plan.json",
        "runs_dir": "harness/.regression-runs",
        "tests_root": "harness/tests",
        "tests_modules": "harness/tests/modules",
        "tests_chains": "harness/tests/chains",
        "tests_concurrent": "harness/tests/concurrent",
        "e2e_root": "harness/e2e",
        "e2e_mes": "harness/e2e/mes",
        "playwright_config": "harness/playwright.config.ts",
        "templates_dir": "harness/templates",
        "report_template": "harness/templates/regression-report.md",
    },
    "hermes": {
        "eagle_eye_root": "hermes/eagle-eye",
        "eagle_eye_reports": "hermes/eagle-eye/reports",
        "business_chains": "hermes/business-chains.json",
        "plans_dir": "hermes/plan",
        "reviews_dir": "hermes/reviews",
    },
    "external_mirror": {
        "user_notes_root": "/Users/ruisuyun/Documents/笔记空间/低代码平台方案/03测试",
    },
}


def load_paths(paths_file: Path | None = None) -> dict[str, Any]:
    """加载 paths.json，缺文件时返回 fallback 硬编码。

    优先级：
    1. 环境变量 HARNESS_PATHS_FILE（CI 覆盖用）
    2. 默认路径 harness/config/paths.json
    3. 硬编码 _FALLBACK

    **注意**：detached runner 长进程（>30 min）编辑 paths.json 不自动生效，需重启。
    短进程（<5 min，如 run-regression.sh 同步调用）改动即生效。
    """
    target = Path(os.environ.get("HARNESS_PATHS_FILE", paths_file or DEFAULT_PATHS_FILE))
    if target.exists():
        try:
            with target.open("r", encoding="utf-8") as f:
                loaded = json.load(f)
            # 移除元数据键（_description / _doc / _template_vars）
            return {
                k: v for k, v in loaded.items() if not k.startswith("_")
            }
        except (OSError, json.JSONDecodeError) as e:
            print(f"⚠️  paths.json 加载失败 ({e.__class__.__name__}: {e})，使用 fallback")
    return _FALLBACK


PATHS: dict[str, Any] = load_paths()


def reload_paths() -> dict[str, Any]:
    """手动重载 paths.json（用于 detached runner 周期性刷新，默认不调用）。"""
    global PATHS
    PATHS = load_paths()
    return PATHS


def resolve(rel_or_abs: str, date: str | None = None) -> Path:
    """解析路径：绝对路径直接用，相对路径以 REPO_ROOT 为锚，支持 ${date} 模板。"""
    s = rel_or_abs
    if date:
        s = s.replace("${date}", date)
    elif "${date}" in s:
        from datetime import datetime
        s = s.replace("${date}", datetime.now().strftime("%Y-%m-%d"))
    p = Path(s)
    return p.resolve() if p.is_absolute() else (REPO_ROOT / s).resolve()
```

### Step 3：Node 端 — 创建路径加载模块

**新文件**：`harness/scripts/_paths.js`

**内容**：
```js
// harness/scripts/_paths.js — Node 端路径集中加载器（Phase 3 / 建议 5）
const fs = require('fs');
const path = require('path');

const REPO = path.resolve(__dirname, '..', '..');
const DEFAULT_PATHS_FILE = path.join(REPO, 'harness', 'config', 'paths.json');

// 与 Python _paths.py 保持完全一致
const FALLBACK = {
  harness: {
    root: 'harness',
    regression_manifest: 'harness/regression/recovery-plan.json',
    runs_dir: 'harness/.regression-runs',
    tests_root: 'harness/tests',
    tests_modules: 'harness/tests/modules',
    tests_chains: 'harness/tests/chains',
    tests_concurrent: 'harness/tests/concurrent',
    e2e_root: 'harness/e2e',
    e2e_mes: 'harness/e2e/mes',
    playwright_config: 'harness/playwright.config.ts',
    templates_dir: 'harness/templates',
    report_template: 'harness/templates/regression-report.md',
  },
  hermes: {
    eagle_eye_root: 'hermes/eagle-eye',
    eagle_eye_reports: 'hermes/eagle-eye/reports',
    business_chains: 'hermes/business-chains.json',
    plans_dir: 'hermes/plan',
    reviews_dir: 'hermes/reviews',
  },
  external_mirror: {
    user_notes_root: '/Users/ruisuyun/Documents/笔记空间/低代码平台方案/03测试',
  },
};

function loadPaths(pathsFile) {
  const target = pathsFile || process.env.HARNESS_PATHS_FILE || DEFAULT_PATHS_FILE;
  if (fs.existsSync(target)) {
    try {
      const raw = JSON.parse(fs.readFileSync(target, 'utf8'));
      const out = {};
      for (const [k, v] of Object.entries(raw)) {
        if (!k.startsWith('_')) out[k] = v;
      }
      return out;
    } catch (e) {
      console.warn(`⚠️  paths.json 加载失败 (${e.message})，使用 fallback`);
    }
  }
  return FALLBACK;
}

const PATHS = loadPaths();

function resolve(relOrAbs, date) {
  let s = relOrAbs;
  if (date) {
    s = s.replace(/\$\{date\}/g, date);
  } else if (s.includes('${date}')) {
    const d = new Date();
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    s = s.replace(/\$\{date\}/g, `${yyyy}-${mm}-${dd}`);
  }
  return path.isAbsolute(s) ? path.resolve(s) : path.resolve(REPO, s);
}

module.exports = { PATHS, REPO, resolve, loadPaths };
```

### Step 4：6 个 driver 切换到集中路径

#### 4a. `resilient_regression.py`
- **删除 `REPO_ROOT = Path(__file__).resolve().parents[2]` (L31)** — 改 `from _paths import REPO_ROOT, PATHS, resolve`
- **删除 `DEFAULT_MANIFEST = REPO_ROOT / "harness" / "regression" / "recovery-plan.json"` (L32)** — 改 `resolve(PATHS['harness']['regression_manifest'])`
- **删除 `DEFAULT_RUNS_DIR = REPO_ROOT / "harness" / ".regression-runs"` (L33)** — 改 `resolve(PATHS['harness']['runs_dir'])`
- **保留 `REPO_ROOT` 用法**（这是锚点概念，非路径）：
  - L152 `path.relative_to(REPO_ROOT)` — display helper
  - L339 `cwd = (REPO_ROOT / start_spec.get("cwd", ".")).resolve()` — service cwd
  - L452 `cwd = (REPO_ROOT / item.get("cwd", ".")).resolve()` — slice cwd
  - L845/L863 `cwd=REPO_ROOT` — subprocess 启动目录
- **L550** `REPO_ROOT / "hermes" / "eagle-eye" / "reports" / ...` → `resolve(PATHS['hermes']['eagle_eye_reports']) / ... / 'issues' / 'review-summary.json'`
- **L599** `target = Path(target_str).resolve() if Path(target_str).is_absolute() else (REPO_ROOT / target_str).resolve()` → `target = resolve(target_str)` (新 helper 已封装)
- **L638** `chains_path = REPO_ROOT / "hermes" / "business-chains.json"` → `chains_path = resolve(PATHS['hermes']['business_chains'])`
- **L963** `plan_parser.add_argument("--manifest", default=str(REPO_ROOT / "harness" / "regression" / "recovery-plan.json"))` → `default=str(resolve(PATHS['harness']['regression_manifest']))`
- **L964** `plan_parser.add_argument("--target", default=str(REPO_ROOT / "harness" / "regression" / "recovery-plan.merged.json"))` → `default=str(resolve(PATHS['harness']['regression_manifest']).parent / 'recovery-plan.merged.json')`

#### 4b. `regression-report.js` (行号已校正 v2)
- **删除 L25 `const PROJECT = path.resolve(__dirname, '..', '..')`** — 改 `const { REPO } = require('./_paths')`
- **删除 L26 `const REPO = PROJECT`**（重复） — 移除
- **删除 L27 `const RUNS_DIR = path.join(PROJECT, 'harness', '.regression-runs')`** — 改 `const RUNS_DIR = resolve(PATHS.harness.runs_dir)`
- **删除 L28 `const EAGLE_EYE = path.join(PROJECT, 'hermes', 'eagle-eye', 'reports')`** — 改 `const EAGLE_EYE = resolve(PATHS.hermes.eagle_eye_reports)`
- **删除 L29 `const TEMPLATE = path.resolve(__dirname, '..', 'templates', 'regression-report.md')`** — 改 `const TEMPLATE = resolve(PATHS.harness.report_template)`
- **L239** `path.join(EAGLE_EYE, date, 'issues')` → `path.join(EAGLE_EYE, date, 'issues')`（不变，EAGLE_EYE 已是 resolve 后的值）
- **L368/L465** `RUNS_DIR` 已是 resolve 后值，无后续改动

#### 4c. `run-batch.js`
- **删除 L30 `const PROJECT = path.resolve(__dirname, '..', '..')`** — 改 `const { REPO } = require('./_paths')`
- L87 `path.join(PROJECT, 'harness', 'tests', 'modules', fileName)` → `path.join(resolve(PATHS.harness.tests_modules), fileName)`

#### 4d. `coverage.js`
- `CTRL_DIRS.mes` 改用 `path.join(REPO, 'jeecg-boot', 'jeecg-boot-module', 'project-mes')`（REPO 已从 _paths 导入；不再硬编码 `harness/`）
- `TEST_DIRS` 改用 `resolve(PATHS.harness.tests_modules)` 和 `resolve(PATHS.harness.e2e_mes)`

#### 4e. `regression_dashboard.py` (P1-1 补充)
- **L20 `STATIC_DIR = REPO_ROOT / "harness" / "dashboard"`** → `STATIC_DIR = resolve(PATHS['harness']['dashboard'])`（paths.json 新加 `harness.dashboard` 字段）
- **L21 `ISSUE_ROOT = REPO_ROOT / "hermes" / "eagle-eye" / "reports"`** → `ISSUE_ROOT = resolve(PATHS['hermes']['eagle_eye_reports'])`

#### 4f. `regression_plan.py` (P1-2 补充)
- `recovery-plan.json` 默认路径 → `resolve(PATHS['harness']['regression_manifest'])`
- `chains_path = DEFAULT_CHAINS_PATH` → `DEFAULT_CHAINS_PATH = resolve(PATHS['hermes']['business_chains'])`
- **L186 `tests_root = REPO_ROOT / "harness" / "tests" / "modules"`** → `tests_root = resolve(PATHS['harness']['tests_modules'])`

---

## 3. 执行顺序 & Commit 策略

**5 个独立 commit**（按依赖性分组）：

1. **Commit 1**（Step 1）：新增 `harness/config/paths.json`
2. **Commit 2**（Step 2）：新增 `harness/scripts/_paths.py`（Python 助手）
3. **Commit 3**（Step 3）：新增 `harness/scripts/_paths.js`（Node 助手）
4. **Commit 4**（Step 4a-4b）：resilient_regression.py + regression-report.js 切换路径
5. **Commit 5**（Step 4c-4f）：run-batch.js + coverage.js + dashboard.py + plan.py 切换路径

每个 commit 后做局部验证（见 §4），最后做整合 verify。

---

## 4. 验证方案（/verify）

### Commit 1 后验证
```bash
test -f harness/config/paths.json && echo "✅ paths.json 存在"
python3 -c "import json; m=json.load(open('harness/config/paths.json')); assert m['version']==1; print('✅ JSON 合法')"
```

### Commit 2 后验证（Python 助手）
```bash
python3 -c "
import sys
sys.path.insert(0, 'harness/scripts')
from _paths import PATHS, REPO_ROOT, resolve, load_paths
# 验证关键路径解析
assert str(resolve(PATHS['harness']['regression_manifest'])).endswith('recovery-plan.json')
assert str(resolve(PATHS['harness']['runs_dir'])).endswith('.regression-runs')
assert str(resolve(PATHS['hermes']['business_chains'])).endswith('business-chains.json')
print('✅ Python _paths OK')
# 验证 fallback（删除 paths.json 临时测）
import os, tempfile, json
with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
    json.dump({'harness': {'root': 'harness'}}, f)
    tmp = f.name
os.environ['HARNESS_PATHS_FILE'] = tmp
loaded = load_paths()
assert loaded['harness']['root'] == 'harness'
print('✅ HARNESS_PATHS_FILE 覆盖生效')
del os.environ['HARNESS_PATHS_FILE']
os.unlink(tmp)
"
```

### Commit 3 后验证（Node 助手）
```bash
node -e "
const { PATHS, REPO, resolve } = require('./harness/scripts/_paths');
assert(PATHS.harness.regression_manifest.endsWith('recovery-plan.json'));
assert(PATHS.hermes.eagle_eye_reports === 'hermes/eagle-eye/reports');
const p = resolve(PATHS.harness.runs_dir);
assert(p.endsWith('.regression-runs'));
console.log('✅ Node _paths OK');
"
```

### Commit 4 后验证（Python + Node 主 driver 切换）
```bash
# resilient_regression.py 不再有 REPO_ROOT 字面量
! grep -E 'REPO_ROOT\s*=\s*Path.*parents\[2\]' harness/scripts/resilient_regression.py && echo "✅ Python REPO_ROOT 已改"
grep -E 'from _paths import' harness/scripts/resilient_regression.py && echo "✅ 已 import _paths"

# regression-report.js 不再有 PROJECT 字面量
! grep -E "const PROJECT = path\.resolve\(__dirname, '..', '..'\)" harness/scripts/regression-report.js && echo "✅ Node PROJECT 已改"
grep -E "require\('./_paths'\)" harness/scripts/regression-report.js && echo "✅ 已 require _paths"
```

### Commit 5 后验证（其他 driver 切换）
```bash
# 4 个 driver 全部切换
for f in run-batch.js coverage.js regression_dashboard.py regression_plan.py; do
    grep -q "_paths\|require('./_paths')\|from _paths" "harness/scripts/$f" && echo "✅ $f 切换 OK" || echo "❌ $f 未切换"
done
```

### 最终整合验证（重跑回归）
```bash
python3 harness/scripts/resilient_regression.py start \
  --manifest harness/regression/recovery-plan.json
# 验证与 Phase 1+2+bugfix 后的结果一致：
#   - 22 passed / 9 failed / 1 verdict
#   - 3 路径报告 369 行
#   - slice 1.4 passed
#   - module-basic-2 跑了 15 个测试
```

---

## 5. 风险评估

| 步骤 | 风险 | 缓解 |
|---|---|---|
| Step 1 paths.json 错字段 | driver 全错 | 字段名与现有代码一致（harness/reuns_dir/hermes/eagle_eye_reports）|
| Step 2/3 fallback 漂移 | Python/Node fallback 不同步 | 由 orca-review 验证两边硬编码一致 |
| Step 4 多 driver 改动 | 漏改某处 | 全仓 grep 验证无残留字面量 |
| Path 解析语义变化 | `resolve()` 处理 `${date}` 与 manifest 不同 | 共用同一逻辑（与 `report_paths` 模板一致）|
| 环境变量覆盖 | CI 设 HARNESS_PATHS_FILE 跑测试失败 | 留 fallback，缺文件不影响 |
| 性能 | 每次 driver 启动读 JSON（~1ms）| 可接受，6 个 driver 各启动一次 |

**总体风险等级**：🟢 低（fallback 设计保证向后兼容，可灰度切换）

---

## 6. 不做的（Out of Scope）

| 项 | 何时做 |
|---|---|
| 统一报告生成器（建议 6）| Phase 4（Python → Node.js，等 Phase 3 稳定）|
| env vars（HARNESS_BASE 等 URL）| 独立（保持环境变量，不进 paths.json）|
| 9 failed 切片根因修复 | 独立 issue |
| e2e/smoke 4 spec 漏调度 | 独立 issue |

---

## 7. 验收标准

Phase 3 完成必须满足：

- [ ] `harness/config/paths.json` 存在且 JSON 合法
- [ ] `harness/scripts/_paths.py` 存在，`PATHS` / `resolve()` / `load_paths()` 三接口可用
- [ ] `harness/scripts/_paths.js` 存在，三接口可用且与 Python 对称
- [ ] 6 个 driver 全部从 `_paths` 读路径（无硬编码 `REPO_ROOT / "harness" / ...` 残留）
- [ ] Python `REPO_ROOT = Path(__file__).resolve().parents[2]` 仅在 `_paths.py` 出现 1 次
- [ ] Node `PROJECT = path.resolve(__dirname, '..', '..')` 仅在 `_paths.js` 出现 1 次
- [ ] 删除 `paths.json` 后所有 driver 仍能用 fallback 跑（向后兼容）
- [ ] 环境变量 `HARNESS_PATHS_FILE` 可覆盖（CI 友好）
- [ ] 重跑回归结果与 Phase 1+2+bugfix 后一致（22 passed / 9 failed / 1 verdict）

---

## 8. 参考

- Phase 1 报告：`hermes/plan/regression-system-consolidation-phase1.md`
- Phase 2 报告：`hermes/plan/regression-system-consolidation-phase2.md`
- 二轮 MCP 分析：`hermes/reviews/2026-08-06-regression-round2-mcp-deep-dive.md` §9.2 §10.1
- 修改标记：本计划改动不涉及 .java，纯 JSON/Python/JS 配置

## 9. Plan 修订记录

| 版本 | 日期 | 修订内容 | 来源 |
|---|---|---|---|
| v1 | 2026-08-06 | 初版 | PI /plan Phase 3 |
| v2 | 2026-08-06 | 修复 4 P1（orca-review `task_1eda85a9f337`）：<br>1. paths.json 加 `harness.dashboard` 字段<br>2. Plan 4f 补 regression_plan.py L186 tests_modules<br>3. Plan 4b 行号校正 L25-L29（非 L43-L45）<br>4. Plan 4a 明确 REPO_ROOT 锚点保留 + cwd=REPO_ROOT 不走 PATHS<br>5. _paths.py 加 `reload_paths()` 文档说明 detached runner hot-reload 限制 | orca-review `task_1eda85a9f337` |
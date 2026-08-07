# features.json ↔ business-chains.json 交叉验证机制

**作者**：pi
**日期**：2026-08-06
**前置**：harness-check 第 3 轴扣分（-1），features.json 与 business-chains.json 无交叉验证机制
**目标范围**：建立 2 个配置文件的**自动交叉验证机制**，确保模块 ID 一致性

---

## 1. 现状分析

### features.json（2.5KB）
- 11 个系统模块 + 2 个项目（demo, mes）
- 每个模块含：`id / name / category / backendPath / frontendPath / apiBase / entity`
- **缺**：MES 业务模块（purchase / sales / warehouse / batch / stocktake 等）
- **缺**：JSON schema 校验
- **缺**：与 business-chains.json 的关联字段

### business-chains.json（11.8KB）
- 6 条链路（chains 数组）
- 每条链路含：`id / modules / chainTests / criticalPaths`
- `modules` 字段是**模块 ID 列表**（字符串数组）
- **已有**：`$schema: "hermes/business-chains.schema.json"`
- **风险**：modules 字段的 ID 可能拼错或不存在

### 当前无交叉验证
- features.json 加新模块后，business-chains.json 不会感知
- business-chains.json 引用不存在的模块 ID，runner 启动时会报错但**报错位置远**
- 没有任何 pre-flight check 在 early 阶段发现不一致

---

## 2. 目标

1. **JSON schema**：给 features.json 加 schema（类比 business-chains.json）
2. **Pre-flight 校验脚本**：新增 `harness/scripts/cross_validate_features.py`
3. **CI/Pre-commit 集成**：在 pre-commit-check.sh 调起
4. **文档化**：在 CLAUDE.md 关键规则章节加交叉验证要求

---

## 3. 详细改动

### Step 1：features.json 加 `$comment` 说明（避免 schema 冲突）

**新增字段**（**修正 P0-2**：删除 `$schema` 引用，每个文件应有自己的 schema，避免 `#definitions/module` 路径不存在导致的 JSON 解析错）：

```json
{
  "version": "1.0",
  "project": "JeecgBoot ERP",
  "_comment": "features.json 由 harness/scripts/cross_validate_features.py 与 hermes/business-chains.json 交叉验证（pre-commit-check.sh 调起）",
  "modules": [...],
  "projects": [...]
}
```

**`$comment` 仅**：说明 cross-validation 关系。**不存储 `chainModules` 数组**（避免与 business-chains.json 双向维护漂移；改由脚本运行时从 business-chains.json 解析 derived set）。

### Step 2：新增 `harness/scripts/cross_validate_features.py`

**内容**（**P0-1 修正**：实际 business-chains.json 用 path/layer 风格 ID 如 `purchase/apply`，不存任何 chainModules 字段）：
```python
"""harness/scripts/cross_validate_features.py — features.json ↔ business-chains.json 交叉验证

Slice A of harness-check 第 3 轴扣分修复。

功能：
1. 加载 features.json 的 modules.id
2. 从 business-chains.json 运行时解析 referenced_ids（walks chains[*].modules + chains[*].sideEffects）
3. 找出 2 类错误：
   - business-chains 引用但 features 未声明的 ID（错误，exit 1）
   - features 声明但未被任何链路引用的孤立 ID（warning，不阻断）

退出码：0 = 通过 / 只有 warning；1 = 有错误
"""
from __future__ import annotations
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
FEATURES = REPO_ROOT / ".claude" / "features.json"
BUSINESS_CHAINS = REPO_ROOT / "hermes" / "business-chains.json"


def collect_referenced_ids(chains_doc: dict) -> set[str]:
    """遍历 chains[*].modules + chains[*].sideEffects 收集全部被引用模块 ID"""
    referenced: set[str] = set()
    for chain in chains_doc.get("chains", []):
        referenced.update(chain.get("modules", []))
        # 某些 chain 可能含 sideEffects 数组（修复影响面计算时也属模块）
        for effect in chain.get("sideEffects", []) or []:
            if isinstance(effect, str):
                referenced.add(effect)
            elif isinstance(effect, dict):
                referenced.add(effect.get("module", ""))
    return {r for r in referenced if r}  # 去空


def main() -> int:
    features = json.loads(FEATURES.read_text(encoding="utf-8"))
    chains = json.loads(BUSINESS_CHAINS.read_text(encoding="utf-8"))

    # features.json 声明的模块 ID（含 system + project 内的 module）
    feature_ids = {m["id"] for m in features.get("modules", [])}

    # 从 business-chains.json 运行时推导
    referenced_ids = collect_referenced_ids(chains)

    # 检查未声明但被引用（错误）
    undeclared = referenced_ids - feature_ids
    if undeclared:
        print(f"❌ business-chains.json 引用未在 features.json 声明的模块 ({len(undeclared)}):")
        for x in sorted(undeclared):
            print(f"   - {x}")
        print("   → 在 features.json modules 加这些 ID，或修正 business-chains.json 引用")
        return 1

    # 检查孤立（warning，不阻断）
    orphan = feature_ids - referenced_ids
    if orphan:
        print(f"⚠️  features.json 声明但未被任何链路引用的模块 ({len(orphan)}):")
        for x in sorted(orphan):
            print(f"   - {x}")

    print(f"✅ 交叉验证通过: {len(feature_ids)} modules declared, {len(referenced_ids)} references in chains")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

**P1-2 修正说明**：本脚本独立运行（pre-commit-check.sh 调起时用 python3 优先 + python fallback，见 Step 3）。脚本本身不需要跨平台 fallback。

### Step 3：pre-commit-check.sh 集成

**文件**：`.claude/hooks/pre-commit-check.sh`

**变更**（**P1-2 修正**：跨平台 Python fallback）：
```bash
# Slice A: features ↔ business-chains 交叉验证
PYTHON_BIN="$(command -v python3 || command -v python)"
"$PYTHON_BIN" harness/scripts/cross_validate_features.py
```

### Step 4：CLAUDE.md 文档化

**变更位置**：CLAUDE.md 关键规则表

**新增规则 7**：
| 7 | **配置交叉验证** — features.json 加新模块必须同步 business-chains.json（pre-commit-check.sh 自动验证），确保链路覆盖 |

---

## 4. 执行顺序 & Commit 策略

**3 个 commit**：

1. **Commit 1**（Step 1）：features.json 加 schema 引用 + chainModules
2. **Commit 2**（Step 2+3）：新增交叉验证脚本 + 集成到 pre-commit-check.sh
3. **Commit 3**（Step 4）：CLAUDE.md 加规则 7

每个 commit 后做局部验证。

---

## 5. 验证方案

### Commit 1 后验证
```bash
python3 -c "
import json
f = json.load(open('.claude/features.json'))
assert '\$schema' in f or 'chainModules' in f
print('✅ features.json 字段完整')
"
```

### Commit 2 后验证
```bash
# 跑脚本
python3 harness/scripts/cross_validate_features.py
echo "Exit code: $?"
echo "应输出: ✅ 交叉验证通过"
```

### Commit 3 后验证
```bash
grep -c "配置交叉验证" CLAUDE.md
# 应为 1
```

---

## 6. 风险评估

| 风险 | 缓解 |
|---|---|
| Step 1 改 features.json 触发下游脚本 | 测试 pre-commit-check.sh 不报新错 |
| Step 2 脚本误报 | 找出全部未声明模块作为已知对照 |
| 跨平台 Python3 兼容性 | 用 `from __future__` + stdlib only |
| 性能 | 启动时跑一次，< 100ms |

**总体风险等级**：🟢 低

---

## 7. 不做的（Out of Scope）

- features.json 业务模块（purchase/sales 等）的 entity/路径补全（独立 issue）
- business-chains.json schema 强化（已有 schema，但与 features 关联弱）
- Slice B：5 个超大函数拆分

---

## 8. 验收标准

- [ ] features.json 含 `chainModules` 数组列出业务模块
- [ ] `harness/scripts/cross_validate_features.py` 存在且 exit 0
- [ ] pre-commit-check.sh 末尾调起交叉验证
- [ ] CLAUDE.md 关键规则表加规则 7
- [ ] 当故意在 business-chains.json 加假模块 ID，脚本报错退出 1

---

## 9. 参考

- harness-check 第 3 轴扣分（hermes/reviews/2026-08-06-harness-check-full-8axis.md）
- 现有 schema: hermes/business-chains.schema.json

## 10. Plan 修订记录

| 版本 | 日期 | 修订 | 来源 |
|---|---|---|---|
| v1 | 2026-08-06 | 初版 | PI /plan Slice A |
| v2 | 2026-08-06 | 修复 2 P0（orca-review `task_1b579c90d1f4`）：<br>1. 删除 `$schema` 字段引用（每个文件应有自己的 schema，#definitions/module 不存在）<br>2. 删除 `chainModules` 数组（业务链模块 ID 是 path/layer 风格如 `purchase/apply`，不存预定义列表；改由脚本运行时从 business-chains.json 推导）<br>3. 修正脚本逻辑：declared_ids = feature_ids + referenced_ids<br>4. 跨平台 Python fallback（python3 || python）<br>5. 实际模块数：12 而非 11 | orca-review `task_1b579c90d1f4` |
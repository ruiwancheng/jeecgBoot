#!/usr/bin/env python3
# update-begin---author:pi---date:2026-08-06---for:【CROSS-VALIDATE】features ↔ business-chains 交叉验证---
"""harness/scripts/cross_validate_features.py — features.json ↔ business-chains.json 交叉验证

Slice A of harness-check 第 3 轴扣分修复（+1 分预期）。

功能：
1. 加载 features.json 的 modules.id
2. 从 business-chains.json 运行时解析 referenced_ids（walks chains[*].modules + chains[*].sideEffects）
3. 找出 2 类错误：
   - business-chains 引用但 features 未声明的 ID（错误，exit 1）
   - features 声明但未被任何链路引用的孤立 ID（warning，不阻断）

退出码：0 = 通过 / 只有 warning；1 = 有错误

关联：
- .claude/hooks/pre-commit-check.sh（commit 前调起）
- .claude/features.json（声明文件）
- hermes/business-chains.json（链路定义）

不修两边。只读验证 + 退出码。
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
FEATURES = REPO_ROOT / ".claude" / "features.json"
BUSINESS_CHAINS = REPO_ROOT / "hermes" / "business-chains.json"


def collect_referenced_ids(chains_doc: dict) -> set[str]:
    """遍历 chains[*].modules + chains[*].sideEffects 收集全部被引用模块 ID

    chains 在 business-chains.json 是 dict（key=中文链路名，value=链路口象），不是 list。
    模块 ID 风格示例：
      - "purchase/apply"
      - "purchase/order"
      - "sales/delivery"
      - "stock/stocktake"
    """
    referenced: set[str] = set()
    chains = chains_doc.get("chains", {})
    if isinstance(chains, dict):
        chain_values = chains.values()
    else:
        chain_values = chains
    for chain in chain_values:
        if not isinstance(chain, dict):
            continue
        referenced.update(chain.get("modules", []) or [])
        for effect in chain.get("sideEffects", []) or []:
            if isinstance(effect, str):
                referenced.add(effect)
            elif isinstance(effect, dict):
                referenced.add(effect.get("module", ""))
    return {r for r in referenced if r}


def main() -> int:
    if not FEATURES.exists():
        print(f"❌ features.json 不存在: {FEATURES}")
        return 1
    if not BUSINESS_CHAINS.exists():
        print(f"❌ business-chains.json 不存在: {BUSINESS_CHAINS}")
        return 1

    features = json.loads(FEATURES.read_text(encoding="utf-8"))
    chains = json.loads(BUSINESS_CHAINS.read_text(encoding="utf-8"))

    # features.json 声明的模块 ID
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
# update-end---author:pi---date:2026-08-06---for:【CROSS-VALIDATE】features ↔ business-chains 交叉验证---
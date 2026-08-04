# update-begin---author:pi---date:2026-08-04---for:【REGRESSION-INTEGRATION】recovery-plan 联动 business-chains + 测试质量门槛 + 变更感知---
"""Tests that wire the regression runner into the coverage-improvement stack."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
import tempfile
import unittest

REPO_ROOT = Path(__file__).resolve().parents[3]
RUNNER = REPO_ROOT / "harness" / "scripts" / "resilient_regression.py"
from harness.scripts import regression_plan as plan


SAMPLE_CHAINS = {
    "chains": {
        "采购链路": {
            "id": "purchase-chain",
            "modules": ["purchase/apply", "purchase/order", "purchase/receipt"],
            "chainTests": {
                "enabled": True,
                "segments": [
                    {"name": "申请→订单", "file": "harness/tests/chains/purchase-apply-order.chain.test.js"},
                    {"name": "订单→入库", "file": "harness/tests/chains/purchase-order-receipt.chain.test.js"},
                ],
            },
        },
        "生产链路": {
            "id": "manufacturing-chain",
            "modules": ["manufacturing/bom", "manufacturing/order"],
            "chainTests": {"enabled": False, "reason": "未编码"},
        },
    }
}


class RecoveryPlanBuilderTest(unittest.TestCase):
    def test_expands_chain_segments_into_slices(self) -> None:
        slices = plan.expand_chain_slices(SAMPLE_CHAINS)
        ids = [item["id"] for item in slices]
        self.assertIn("chain.purchase-chain.1", ids)
        self.assertIn("chain.purchase-chain.2", ids)
        self.assertEqual("harness/tests/chains/purchase-apply-order.chain.test.js", slices[0]["command"][1])

    def test_skips_chains_without_enabled_chain_tests(self) -> None:
        slices = plan.expand_chain_slices(SAMPLE_CHAINS)
        self.assertFalse(any(item["id"].startswith("chain.manufacturing") for item in slices))


class PlanMergingTest(unittest.TestCase):
    def test_merge_preserves_built_in_slices_and_appends_chains(self) -> None:
        base = {"slices": [{"id": "0-build", "name": "build", "kind": "build", "command": ["x"], "timeout_seconds": 60}]}
        chain_slices = [{"id": "chain.purchase-chain.1", "name": "申请→订单", "kind": "chain", "command": ["node", "x"], "timeout_seconds": 120}]
        merged = plan.merge_slices(base, chain_slices)
        self.assertEqual(2, len(merged["slices"]))
        self.assertEqual("0-build", merged["slices"][0]["id"])
        self.assertEqual("chain.purchase-chain.1", merged["slices"][1]["id"])

    def test_emit_writes_merged_plan_atomic(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp) / "plan.json"
            plan.emit_merged_plan({"slices": [{"id": "a"}]}, [], out)
            self.assertTrue(out.exists())
            data = json.loads(out.read_text(encoding="utf-8"))
            self.assertEqual(1, len(data["slices"]))


class TestQualityGateTest(unittest.TestCase):
    def test_counts_assertions_per_file(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "good.test.js").write_text(
                "c.check('字段值', result.code > 0);\n"
                "c.check('状态流转', record.status === '3');\n",
                encoding="utf-8",
            )
            (root / "shallow.test.js").write_text("c.check('不崩', result.code === 200);\n", encoding="utf-8")
            report = plan.evaluate_test_quality(root)
            self.assertEqual(2, report["summary"]["files"])
            self.assertEqual(3, report["summary"]["assertions"])
            self.assertTrue(report["files"]["good.test.js"]["deep_assertions"] >= 1)
            self.assertEqual(0, report["files"]["shallow.test.js"]["deep_assertions"])

    def test_missing_directory_is_safe(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            report = plan.evaluate_test_quality(Path(temp) / "missing")
            self.assertEqual(0, report["summary"]["files"])


if __name__ == "__main__":
    unittest.main()
# update-end---author:pi---date:2026-08-04---for:【REGRESSION-INTEGRATION】recovery-plan 联动 business-chains + 测试质量门槛 + 变更感知---

# update-begin---author:pi---date:2026-08-04---for:【REGRESSION-DASHBOARD】回归看板状态与日志接口测试---
"""Tests for the read-only regression dashboard seams."""

from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from harness.scripts import regression_dashboard


class RegressionDashboardTest(unittest.TestCase):
    def test_status_payload_contains_progress_and_current_slice(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            run_dir = Path(temp)
            state = {
                "run_id": "demo-run",
                "name": "demo",
                "status": "running",
                "created_at": "2026-08-04T10:00:00+08:00",
                "updated_at": "2026-08-04T10:01:00+08:00",
                "heartbeat_at": "2026-08-04T10:01:00+08:00",
                "current_slice": "2.1",
                "services": {"backend": {"status": "healthy", "pid": 1}},
                "slices": {
                    "1.1": {"id": "1.1", "name": "first", "status": "passed", "attempts": 1, "duration_seconds": 2},
                    "2.1": {"id": "2.1", "name": "second", "status": "running", "attempts": 1, "duration_seconds": None},
                    "3.1": {"id": "3.1", "name": "third", "status": "pending", "attempts": 0, "duration_seconds": None},
                },
            }
            (run_dir / "state.json").write_text(json.dumps(state), encoding="utf-8")
            (run_dir / "manifest.json").write_text(json.dumps({"slices": []}), encoding="utf-8")

            payload = regression_dashboard.build_status_payload(run_dir)

            self.assertEqual("running", payload["status"])
            self.assertEqual("2.1", payload["current_slice"])
            self.assertEqual(1, payload["progress"]["passed"])
            self.assertEqual(3, payload["progress"]["total"])
            self.assertEqual(33, payload["progress"]["percent"])
            self.assertEqual("healthy", payload["services"]["backend"]["status"])

    def test_log_path_is_limited_to_the_run_directory(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            run_dir = Path(temp)
            log_path = run_dir / "logs" / "1.1.attempt-1.log"
            log_path.parent.mkdir()
            log_path.write_text("last output", encoding="utf-8")
            state = {
                "slices": {
                    "1.1": {"id": "1.1", "status": "passed", "log_path": "logs/1.1.attempt-1.log"}
                }
            }
            (run_dir / "state.json").write_text(json.dumps(state), encoding="utf-8")

            self.assertEqual("last output", regression_dashboard.read_slice_log(run_dir, "1.1"))
            with self.assertRaises(ValueError):
                regression_dashboard.read_slice_log(run_dir, "../../outside")


if __name__ == "__main__":
    unittest.main()
# update-end---author:pi---date:2026-08-04---for:【REGRESSION-DASHBOARD】回归看板状态与日志接口测试---

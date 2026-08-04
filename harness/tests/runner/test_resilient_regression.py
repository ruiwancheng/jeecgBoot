# update-begin---author:pi---date:2026-08-04---for:【REGRESSION-CRASH-GUARD】回归任务断点续跑保底测试---
"""Public CLI tests for the resilient MES regression runner."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

from harness.scripts import resilient_regression as runner


REPO_ROOT = Path(__file__).resolve().parents[3]
RUNNER = REPO_ROOT / "harness" / "scripts" / "resilient_regression.py"


def write_manifest(path: Path, slices: list[dict], health: dict | None = None) -> None:
    path.write_text(
        json.dumps(
            {
                "version": 1,
                "name": "runner-self-test",
                "environment": {},
                "health": health or {},
                "services": [],
                "slices": slices,
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )


def python_command(source: str) -> list[str]:
    return [sys.executable, "-c", source]


def run_cli(*args: str, timeout: int = 20) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(RUNNER), *args],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
    )


def wait_for(predicate, timeout: float = 10.0) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        if predicate():
            return
        time.sleep(0.1)
    raise AssertionError("condition was not met before timeout")


class ResilientRegressionCliTest(unittest.TestCase):
    def test_resume_skips_passed_slice_and_retries_interrupted_slice(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            run_dir = root / "run"
            manifest = root / "manifest.json"
            first_marker = root / "first.txt"
            second_marker = root / "second.txt"

            write_manifest(
                manifest,
                [
                    {
                        "id": "first",
                        "name": "first passes once",
                        "kind": "test",
                        "cwd": ".",
                        "command": python_command(
                            f"from pathlib import Path; p=Path({str(first_marker)!r}); "
                            "p.write_text(p.read_text() + 'x' if p.exists() else 'x');"
                        ),
                        "timeout_seconds": 10,
                        "requires": [],
                    },
                    {
                        "id": "second",
                        "name": "second is interrupted once",
                        "kind": "test",
                        "cwd": ".",
                        "command": python_command(
                            f"from pathlib import Path; import time; p=Path({str(second_marker)!r}); "
                            "already=p.exists(); p.write_text('started'); time.sleep(30) if not already else None"
                        ),
                        "timeout_seconds": 40,
                        "requires": [],
                    },
                ],
            )

            process = subprocess.Popen(
                [
                    sys.executable,
                    str(RUNNER),
                    "run",
                    "--manifest",
                    str(manifest),
                    "--run-dir",
                    str(run_dir),
                ],
                cwd=REPO_ROOT,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )

            state_path = run_dir / "state.json"

            def second_is_running() -> bool:
                if not state_path.exists():
                    return False
                state = json.loads(state_path.read_text(encoding="utf-8"))
                return state["slices"]["second"]["status"] == "running"

            wait_for(second_is_running)
            if os.name == "nt":
                subprocess.run(
                    ["taskkill", "/PID", str(process.pid), "/T", "/F"],
                    capture_output=True,
                    check=False,
                )
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=5)
            else:
                process.terminate()
                process.wait(timeout=5)

            # The checkpoint must remain valid JSON after an abrupt process-tree kill.
            interrupted_state = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertEqual("passed", interrupted_state["slices"]["first"]["status"])
            self.assertEqual("running", interrupted_state["slices"]["second"]["status"])

            resumed = run_cli("resume", "--run-dir", str(run_dir), "--foreground", "--scope", "full")
            self.assertEqual(0, resumed.returncode, resumed.stdout + resumed.stderr)

            final_state = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertEqual("passed", final_state["slices"]["first"]["status"])
            self.assertEqual(1, final_state["slices"]["first"]["attempts"])
            self.assertEqual("passed", final_state["slices"]["second"]["status"])
            self.assertEqual(2, final_state["slices"]["second"]["attempts"])
            self.assertEqual("x", first_marker.read_text(encoding="utf-8"))

    def test_unhealthy_required_service_blocks_slice_without_running_command(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            run_dir = root / "run"
            manifest = root / "manifest.json"
            should_not_exist = root / "ran.txt"
            write_manifest(
                manifest,
                [
                    {
                        "id": "api",
                        "name": "requires backend",
                        "kind": "api",
                        "cwd": ".",
                        "command": python_command(
                            f"from pathlib import Path; Path({str(should_not_exist)!r}).write_text('bad')"
                        ),
                        "timeout_seconds": 5,
                        "requires": ["backend"],
                    }
                ],
                health={
                    "backend": {
                        "url": "http://127.0.0.1:1/unreachable",
                        "timeout_seconds": 0.2,
                        "contains": "success",
                    }
                },
            )

            result = run_cli(
                "run",
                "--manifest",
                str(manifest),
                "--run-dir",
                str(run_dir),
            )
            self.assertEqual(2, result.returncode, result.stdout + result.stderr)
            state = json.loads((run_dir / "state.json").read_text(encoding="utf-8"))
            self.assertEqual("blocked_environment", state["slices"]["api"]["status"])
            self.assertFalse(should_not_exist.exists())

    def test_state_checkpoint_falls_back_when_windows_replace_is_locked(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            run_dir = Path(temp)
            state_path = run_dir / "state.json"
            payload = {"status": "running", "checkpoint": 3}

            with (
                patch.object(runner.os, "replace", side_effect=PermissionError("locked")),
                patch.object(runner.time, "sleep", return_value=None),
            ):
                runner.atomic_write_json(state_path, payload)

            self.assertFalse(state_path.exists())
            self.assertEqual(payload, runner.read_state(run_dir))


        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            run_dir = root / "run"
            manifest = root / "manifest.json"
            write_manifest(
                manifest,
                [
                    {
                        "id": "fails",
                        "name": "returns seven",
                        "kind": "test",
                        "cwd": ".",
                        "command": python_command("raise SystemExit(7)"),
                        "timeout_seconds": 5,
                        "requires": [],
                    },
                    {
                        "id": "times-out",
                        "name": "exceeds timeout",
                        "kind": "test",
                        "cwd": ".",
                        "command": python_command("import time; time.sleep(5)"),
                        "timeout_seconds": 1,
                        "requires": [],
                    },
                ],
            )

            result = run_cli(
                "run",
                "--manifest",
                str(manifest),
                "--run-dir",
                str(run_dir),
                timeout=15,
            )
            self.assertEqual(1, result.returncode, result.stdout + result.stderr)
            state = json.loads((run_dir / "state.json").read_text(encoding="utf-8"))
            self.assertEqual("failed", state["slices"]["fails"]["status"])
            self.assertEqual(7, state["slices"]["fails"]["exit_code"])
            self.assertEqual("timeout", state["slices"]["times-out"]["status"])
            self.assertTrue(state["slices"]["times-out"]["timed_out"])


    def test_change_scope_filters_state_and_persists_base(self) -> None:
        """--scope change must apply the diff-filter to state.slices (not just manifest).

        Regression guard for the bug where ``initial_state`` was called BEFORE
        ``filter_slices_by_scope``, so state.json contained phantom ``pending``
        slices for chain ids the scope filter had removed. The dashboard and
        review payload both read state, so misleading pending entries would
        show up next to the actually-selected slices. Also asserts ``--base``
        is persisted to state/manifest for later resume/reporting.

        The chain slices must carry ``source.chain`` (only true for the merged
        plan). The runner only filters correctly when the manifest has been
        pre-merged with ``expand_chain_slices`` — exactly what ``start`` does
        in production.
        """
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            run_dir = root / "run"
            manifest = root / "manifest.json"
            write_manifest(
                manifest,
                [
                    {"id": "0-build", "name": "build", "kind": "build",
                     "cwd": ".", "command": ["python", "-c", "pass"], "timeout_seconds": 5,
                     "requires": [], "continue_on_failure": False},
                    {"id": "frontend-static", "name": "fe", "kind": "frontend-static",
                     "cwd": ".", "command": ["python", "-c", "pass"], "timeout_seconds": 5,
                     "requires": []},
                    {"id": "test-quality", "name": "qa", "kind": "quality",
                     "cwd": ".", "command": ["python", "-c", "pass"], "timeout_seconds": 5,
                     "requires": []},
                    {"id": "smoke-api", "name": "smoke api", "kind": "module",
                     "cwd": ".", "command": ["python", "-c", "pass"], "timeout_seconds": 5,
                     "requires": []},
                    {"id": "smoke-e2e", "name": "smoke e2e", "kind": "e2e",
                     "cwd": ".", "command": ["python", "-c", "pass"], "timeout_seconds": 5,
                     "requires": []},
                    {"id": "chain.basic-data.1", "name": "match", "kind": "chain",
                     "source": {"chain": "basic-data"},
                     "cwd": ".", "command": ["python", "-c", "pass"], "timeout_seconds": 5,
                     "requires": []},
                    {"id": "chain.unrelated.1", "name": "no match", "kind": "chain",
                     "source": {"chain": "unrelated"},
                     "cwd": ".", "command": ["python", "-c", "pass"], "timeout_seconds": 5,
                     "requires": []},
                ],
            )
            # Pre-decorate manifest like ``start`` does (after merging + scope/base).
            doc = json.loads(manifest.read_text(encoding="utf-8"))
            doc["scope"] = "change"
            doc["diff_files"] = ["harness/scripts/resilient_regression.py"]
            doc["base"] = "HEAD~6"
            manifest.write_text(json.dumps(doc, ensure_ascii=False), encoding="utf-8")

            # ``run`` path: patch chain_ids_for_diff (need scripts/ on sys.path
            # so ``from regression_plan import ...`` resolves the same way it
            # does in production).
            scripts_path = str(REPO_ROOT / "harness" / "scripts")
            inserted = scripts_path not in sys.path
            if inserted:
                sys.path.insert(0, scripts_path)
            try:
                with patch.object(runner, "chain_ids_for_diff", return_value={"basic-data"}):
                    rc = runner.main(
                        ["run", "--manifest", str(manifest), "--run-dir", str(run_dir)]
                    )
            finally:
                if inserted:
                    sys.path.remove(scripts_path)
            self.assertIn(rc, (0, 1))
            state = json.loads((run_dir / "state.json").read_text(encoding="utf-8"))
            manifest_doc = json.loads((run_dir / "manifest.json").read_text(encoding="utf-8"))
            self.assertEqual(
                ["0-build", "chain.basic-data.1", "frontend-static", "smoke-api", "smoke-e2e", "test-quality"],
                sorted(state["slices"].keys()),
                f"state.slices must be filtered; got {sorted(state['slices'].keys())}",
            )
            self.assertEqual(len(state["slices"]), len(manifest_doc["slices"]),
                             "state and manifest must agree on slice count")
            self.assertEqual("change", state["scope"])
            self.assertEqual("HEAD~6", state["base"])
            self.assertEqual(["basic-data"], state["matched_chains"])
            self.assertIn("chain.basic-data.1", state["slices"],
                          "basic-data matches so this chain slice must be kept")
            self.assertNotIn("chain.unrelated.1", state["slices"],
                             "unrelated chain must be filtered out")


if __name__ == "__main__":
    unittest.main()
# update-end---author:pi---date:2026-08-04---for:【REGRESSION-CRASH-GUARD】回归任务断点续跑保底测试---

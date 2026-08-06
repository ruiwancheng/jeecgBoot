# update-begin---author:pi---date:2026-08-04---for:【REGRESSION-DASHBOARD】新增只读回归测试看板服务---
"""Read-only local dashboard for a durable MES regression run."""

from __future__ import annotations

import argparse
from datetime import datetime
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import sys
from urllib.parse import parse_qs, urlparse

try:
    from resilient_regression import REPO_ROOT, read_json, read_state
except ModuleNotFoundError:
    from harness.scripts.resilient_regression import REPO_ROOT, read_json, read_state

# Phase 3 / 建议 5：路径集中加载（缺文件时硬编码 fallback）
try:
    from _paths import PATHS as _HARNESS_PATHS, resolve as _resolve_path
except ImportError:
    _HARNESS_PATHS = {}
    def _resolve_path(rel_or_abs, date=None):
        from pathlib import Path
        p = Path(rel_or_abs)
        return p.resolve() if p.is_absolute() else (REPO_ROOT / rel_or_abs).resolve()


STATIC_DIR = _resolve_path(_HARNESS_PATHS.get("harness", {}).get("dashboard", "harness/dashboard"))
ISSUE_ROOT = _resolve_path(_HARNESS_PATHS.get("hermes", {}).get("eagle_eye_reports", "hermes/eagle-eye/reports"))
MAX_LOG_BYTES = 250_000


def today_issue_dir() -> Path:
    return ISSUE_ROOT / datetime.now().strftime("%Y-%m-%d") / "issues"


def review_payload() -> dict:
    summary_path = today_issue_dir() / "review-summary.json"
    if not summary_path.exists():
        return {"counts": {}, "candidates": []}
    try:
        return read_json(summary_path)
    except (OSError, json.JSONDecodeError):
        return {"counts": {}, "candidates": [], "error": "复核汇总暂时不可读取"}


def build_status_payload(run_dir: Path) -> dict:
    state = read_state(run_dir)
    slice_values = list(state.get("slices", {}).values())
    counts: dict[str, int] = {}
    for item in slice_values:
        status = item.get("status", "unknown")
        counts[status] = counts.get(status, 0) + 1
    total = len(slice_values)
    passed = counts.get("passed", 0)
    percent = round(passed * 100 / total) if total else 0
    return {
        "run_id": state.get("run_id"),
        "name": state.get("name"),
        "status": state.get("status"),
        "created_at": state.get("created_at"),
        "updated_at": state.get("updated_at"),
        "heartbeat_at": state.get("heartbeat_at"),
        "current_slice": state.get("current_slice"),
        "services": state.get("services", {}),
        "progress": {
            "total": total,
            "passed": passed,
            "failed": counts.get("failed", 0),
            "timeout": counts.get("timeout", 0),
            "blocked_environment": counts.get("blocked_environment", 0),
            "pending": counts.get("pending", 0),
            "running": counts.get("running", 0),
            "interrupted": counts.get("interrupted", 0),
            "percent": percent,
        },
        "slices": slice_values,
        "issues": review_payload(),
        "run_dir": str(run_dir),
    }


def read_slice_log(run_dir: Path, slice_id: str) -> str:
    state = read_state(run_dir)
    slice_state = state.get("slices", {}).get(slice_id)
    if not slice_state:
        raise ValueError(f"unknown slice: {slice_id}")
    relative_log = slice_state.get("log_path")
    if not relative_log:
        return "该切片还没有日志。"
    log_path = (run_dir / relative_log).resolve()
    try:
        log_path.relative_to(run_dir.resolve())
    except ValueError as error:
        raise ValueError("log path escapes run directory") from error
    if not log_path.exists():
        return "日志文件尚未生成。"
    with log_path.open("rb") as stream:
        stream.seek(0, 2)
        size = stream.tell()
        stream.seek(max(0, size - MAX_LOG_BYTES))
        content = stream.read().decode("utf-8", errors="replace")
    return content


class DashboardHandler(BaseHTTPRequestHandler):
    run_dir: Path

    def log_message(self, format: str, *args) -> None:  # noqa: N802
        return

    def send_json(self, payload: dict, status: int = 200) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_file(self, filename: str, content_type: str) -> None:
        path = STATIC_DIR / filename
        if not path.exists():
            self.send_error(404)
            return
        body = path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        try:
            if parsed.path == "/":
                self.send_file("index.html", "text/html; charset=utf-8")
            elif parsed.path == "/dashboard.css":
                self.send_file("dashboard.css", "text/css; charset=utf-8")
            elif parsed.path == "/dashboard.js":
                self.send_file("dashboard.js", "application/javascript; charset=utf-8")
            elif parsed.path == "/api/status":
                self.send_json(build_status_payload(self.run_dir))
            elif parsed.path == "/api/issues":
                self.send_json(review_payload())
            elif parsed.path == "/api/log":
                slice_id = parse_qs(parsed.query).get("slice", [""])[0]
                self.send_json({"slice": slice_id, "content": read_slice_log(self.run_dir, slice_id)})
            elif parsed.path == "/api/report":
                report = self.run_dir / "summary.md"
                content = report.read_text(encoding="utf-8") if report.exists() else "报告尚未生成。"
                self.send_json({"content": content})
            else:
                self.send_error(404)
        except (FileNotFoundError, ValueError) as error:
            self.send_json({"error": str(error)}, 404)
        except Exception as error:  # The dashboard must show an error instead of crashing.
            self.send_json({"error": f"{type(error).__name__}: {error}"}, 500)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="MES regression read-only dashboard")
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--port", type=int, default=8765)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    run_dir = Path(args.run_dir).resolve()
    if not run_dir.exists():
        print(f"run directory not found: {run_dir}", file=sys.stderr)
        return 2
    handler = type("BoundDashboardHandler", (DashboardHandler,), {"run_dir": run_dir})
    server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    print(f"dashboard=http://127.0.0.1:{args.port} run_dir={run_dir}", flush=True)
    try:
        server.serve_forever(poll_interval=0.5)
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
# update-end---author:pi---date:2026-08-04---for:【REGRESSION-DASHBOARD】新增只读回归测试看板服务---

# update-begin---author:pi---date:2026-08-04---for:【REGRESSION-CRASH-GUARD】新增可脱离Orca运行的回归任务控制器---
"""Crash-resilient, resumable regression runner for the MES harness.

The public interface is intentionally small:
  start   - create a run and launch it detached from the current terminal
  run     - execute a manifest in the foreground
  resume  - continue an interrupted/blocked run
  status  - print durable checkpoint state
  stop    - stop the runner (and optionally services started by it)
  report  - regenerate the Markdown summary from checkpoint state
"""

from __future__ import annotations

import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = REPO_ROOT / "harness" / "regression" / "recovery-plan.json"
DEFAULT_RUNS_DIR = REPO_ROOT / "harness" / ".regression-runs"
TERMINAL_STATUSES = {"passed", "failed", "timeout", "skipped"}
RETRYABLE_STATUSES = {"pending", "running", "interrupted", "blocked_environment"}


def now_iso() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def safe_id(value: str) -> str:
    return "".join(c if c.isalnum() or c in "-_." else "-" for c in value)


def read_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as stream:
        return json.load(stream)


def atomic_write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as stream:
            json.dump(data, stream, ensure_ascii=False, indent=2)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp_name, path)
    finally:
        if os.path.exists(temp_name):
            os.unlink(temp_name)


def write_text_atomic(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp_name, path)
    finally:
        if os.path.exists(temp_name):
            os.unlink(temp_name)


def is_pid_alive(pid: int | None) -> bool:
    if not pid or pid <= 0:
        return False
    try:
        os.kill(pid, 0)
        return True
    except PermissionError:
        return True
    except (OSError, SystemError):
        return False


def terminate_process_tree(pid: int) -> None:
    if not is_pid_alive(pid):
        return
    if os.name == "nt":
        subprocess.run(
            ["taskkill", "/PID", str(pid), "/T", "/F"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    else:
        try:
            os.killpg(pid, signal.SIGTERM)
            time.sleep(0.5)
            if is_pid_alive(pid):
                os.killpg(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass


def display_path(path: Path) -> str:
    """Use a repo-relative path when possible, otherwise retain the absolute path."""
    try:
        return str(path.relative_to(REPO_ROOT)).replace("\\\\", "/")
    except ValueError:
        return str(path).replace("\\\\", "/")


def resolve_command(command: list[str]) -> list[str]:
    if not command:
        raise ValueError("command must not be empty")
    executable = command[0]
    if os.path.isabs(executable) or "/" in executable or "\\" in executable:
        return command
    resolved = shutil.which(executable)
    if not resolved:
        raise FileNotFoundError(f"executable not found: {executable}")
    return [resolved, *command[1:]]


def process_creation_flags(detached: bool) -> int:
    if os.name != "nt":
        return 0
    flags = subprocess.CREATE_NEW_PROCESS_GROUP
    if detached:
        flags |= subprocess.DETACHED_PROCESS
    return flags


def probe_health(spec: dict[str, Any]) -> tuple[bool, str]:
    url = spec.get("url")
    if not url:
        return False, "health URL is missing"
    timeout = float(spec.get("timeout_seconds", 3))
    expected = str(spec.get("contains", ""))
    try:
        request = Request(url, headers={"User-Agent": "mes-regression-guard/1.0"})
        with urlopen(request, timeout=timeout) as response:
            body = response.read(65536).decode("utf-8", errors="replace")
            status = response.getcode()
        if not 200 <= status < 300:
            return False, f"HTTP {status}"
        if expected and expected not in body:
            return False, f"response does not contain {expected!r}"
        return True, f"HTTP {status}"
    except HTTPError as error:
        return False, f"HTTP {error.code}"
    except (URLError, TimeoutError, OSError) as error:
        return False, f"{type(error).__name__}: {error}"


def manifest_snapshot(source: Path, run_dir: Path) -> Path:
    destination = run_dir / "manifest.json"
    run_dir.mkdir(parents=True, exist_ok=True)
    if source.resolve() != destination.resolve():
        shutil.copy2(source, destination)
    return destination


def initial_state(manifest: dict[str, Any], run_dir: Path) -> dict[str, Any]:
    created = now_iso()
    slices = {}
    for item in manifest.get("slices", []):
        slice_id = item["id"]
        slices[slice_id] = {
            "id": slice_id,
            "name": item.get("name", slice_id),
            "kind": item.get("kind", "test"),
            "status": "pending",
            "attempts": 0,
            "started_at": None,
            "finished_at": None,
            "duration_seconds": None,
            "exit_code": None,
            "timed_out": False,
            "log_path": None,
            "message": None,
        }
    return {
        "version": 1,
        "run_id": run_dir.name,
        "name": manifest.get("name", "regression"),
        "status": "pending",
        "created_at": created,
        "updated_at": created,
        "heartbeat_at": None,
        "runner_pid": None,
        "current_slice": None,
        "services": {},
        "slices": slices,
    }


class RunContext:
    def __init__(self, run_dir: Path, manifest: dict[str, Any], state: dict[str, Any]):
        self.run_dir = run_dir
        self.manifest = manifest
        self.state = state
        self.state_path = run_dir / "state.json"
        self.telemetry_path = run_dir / "telemetry.jsonl"
        self.last_heartbeat = 0.0

    def save(self) -> None:
        self.state["updated_at"] = now_iso()
        atomic_write_json(self.state_path, self.state)

    def heartbeat(self, event: str = "heartbeat", force: bool = False) -> None:
        current = time.monotonic()
        if not force and current - self.last_heartbeat < 5:
            return
        timestamp = now_iso()
        self.state["heartbeat_at"] = timestamp
        self.save()
        record = {
            "timestamp": timestamp,
            "event": event,
            "runner_pid": os.getpid(),
            "current_slice": self.state.get("current_slice"),
            "services": {
                key: {"pid": value.get("pid"), "status": value.get("status")}
                for key, value in self.state.get("services", {}).items()
            },
        }
        with self.telemetry_path.open("a", encoding="utf-8", newline="\n") as stream:
            stream.write(json.dumps(record, ensure_ascii=False) + "\n")
            stream.flush()
        self.last_heartbeat = current


class RunLock:
    def __init__(self, path: Path):
        self.path = path

    def __enter__(self) -> "RunLock":
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if self.path.exists():
            try:
                previous_pid = int(self.path.read_text(encoding="ascii").strip())
            except (OSError, ValueError):
                previous_pid = None
            if is_pid_alive(previous_pid):
                raise RuntimeError(f"run is already active (pid={previous_pid})")
            self.path.unlink(missing_ok=True)
        fd = os.open(self.path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        with os.fdopen(fd, "w", encoding="ascii") as stream:
            stream.write(str(os.getpid()))
            stream.flush()
            os.fsync(stream.fileno())
        return self

    def __exit__(self, exc_type, exc, traceback) -> None:
        self.path.unlink(missing_ok=True)


def service_definition(manifest: dict[str, Any], service_id: str) -> dict[str, Any] | None:
    for service in manifest.get("services", []):
        if service.get("id") == service_id:
            return service
    return None


def wait_for_health(ctx: RunContext, service_id: str, timeout_seconds: float) -> tuple[bool, str]:
    spec = ctx.manifest.get("health", {}).get(service_id)
    if not spec:
        return False, f"health specification missing for {service_id}"
    deadline = time.monotonic() + timeout_seconds
    last_detail = "not probed"
    while time.monotonic() < deadline:
        healthy, last_detail = probe_health(spec)
        if healthy:
            return True, last_detail
        ctx.heartbeat(f"waiting-for-{service_id}")
        time.sleep(1)
    return False, last_detail


def start_service(ctx: RunContext, service_id: str, definition: dict[str, Any]) -> tuple[bool, str]:
    service_state = ctx.state.setdefault("services", {}).setdefault(
        service_id,
        {"attempts": 0, "pid": None, "status": "unknown", "started_at": None, "log_path": None},
    )
    max_restarts = int(definition.get("max_restarts", 2))
    if service_state["attempts"] >= max_restarts:
        return False, f"restart limit reached ({max_restarts})"

    start_spec = definition.get("start")
    if not start_spec:
        return False, "no automatic start command configured"

    command = resolve_command(list(start_spec["command"]))
    cwd = (REPO_ROOT / start_spec.get("cwd", ".")).resolve()
    log_path = ctx.run_dir / "services" / f"{safe_id(service_id)}.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    environment = os.environ.copy()
    environment.update({str(k): str(v) for k, v in ctx.manifest.get("environment", {}).items()})
    environment.update({str(k): str(v) for k, v in start_spec.get("environment", {}).items()})

    with log_path.open("ab", buffering=0) as log_stream:
        log_stream.write(
            f"\n[{now_iso()}] START {json.dumps(command, ensure_ascii=False)}\n".encode("utf-8")
        )
        process = subprocess.Popen(
            command,
            cwd=cwd,
            env=environment,
            stdin=subprocess.DEVNULL,
            stdout=log_stream,
            stderr=subprocess.STDOUT,
            creationflags=process_creation_flags(detached=True),
            start_new_session=(os.name != "nt"),
        )

    service_state.update(
        {
            "attempts": service_state["attempts"] + 1,
            "pid": process.pid,
            "status": "starting",
            "started_at": now_iso(),
            "log_path": display_path(log_path),
        }
    )
    ctx.save()
    healthy, detail = wait_for_health(
        ctx, service_id, float(definition.get("startup_timeout_seconds", 120))
    )
    service_state["status"] = "healthy" if healthy else "unhealthy"
    service_state["message"] = detail
    ctx.save()
    return healthy, detail


def ensure_service(ctx: RunContext, service_id: str) -> tuple[bool, str]:
    health_spec = ctx.manifest.get("health", {}).get(service_id)
    if not health_spec:
        return False, f"health specification missing for {service_id}"
    healthy, detail = probe_health(health_spec)
    service_state = ctx.state.setdefault("services", {}).setdefault(
        service_id,
        {"attempts": 0, "pid": None, "status": "unknown", "started_at": None, "log_path": None},
    )
    if healthy:
        service_state["status"] = "healthy"
        service_state["message"] = detail
        ctx.save()
        return True, detail
    service_state["status"] = "unhealthy"
    service_state["message"] = detail
    ctx.save()
    definition = service_definition(ctx.manifest, service_id)
    if not definition:
        return False, detail
    return start_service(ctx, service_id, definition)


def check_requirements(ctx: RunContext, item: dict[str, Any]) -> tuple[bool, str]:
    for service_id in item.get("requires", []):
        healthy, detail = ensure_service(ctx, service_id)
        if not healthy:
            return False, f"{service_id}: {detail}"
    return True, "all required services are healthy"


def run_slice_process(ctx: RunContext, item: dict[str, Any], slice_state: dict[str, Any]) -> tuple[int | None, bool, float, str]:
    attempt = slice_state["attempts"]
    log_path = ctx.run_dir / "logs" / f"{safe_id(item['id'])}.attempt-{attempt}.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    command = resolve_command(list(item["command"]))
    cwd = (REPO_ROOT / item.get("cwd", ".")).resolve()
    timeout_seconds = float(item.get("timeout_seconds", 300))
    environment = os.environ.copy()
    environment.update({str(k): str(v) for k, v in ctx.manifest.get("environment", {}).items()})
    environment.update({str(k): str(v) for k, v in item.get("environment", {}).items()})
    started = time.monotonic()

    with log_path.open("wb") as log_stream:
        header = (
            f"[{now_iso()}] slice={item['id']} cwd={cwd}\n"
            f"command={json.dumps(command, ensure_ascii=False)}\n\n"
        )
        log_stream.write(header.encode("utf-8"))
        log_stream.flush()
        process = subprocess.Popen(
            command,
            cwd=cwd,
            env=environment,
            stdin=subprocess.DEVNULL,
            stdout=log_stream,
            stderr=subprocess.STDOUT,
            creationflags=process_creation_flags(detached=False),
            start_new_session=(os.name != "nt"),
        )
        slice_state["child_pid"] = process.pid
        slice_state["log_path"] = display_path(log_path)
        ctx.save()
        timed_out = False
        while process.poll() is None:
            elapsed = time.monotonic() - started
            if elapsed >= timeout_seconds:
                timed_out = True
                terminate_process_tree(process.pid)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    pass
                break
            ctx.heartbeat("slice-running")
            time.sleep(0.2)
        exit_code = process.poll()
        duration = round(time.monotonic() - started, 3)
        footer = f"\n[{now_iso()}] exit_code={exit_code} timed_out={timed_out} duration={duration}s\n"
        log_stream.write(footer.encode("utf-8"))

    return exit_code, timed_out, duration, display_path(log_path)


def recover_interrupted_state(state: dict[str, Any]) -> None:
    for slice_state in state.get("slices", {}).values():
        if slice_state.get("status") == "running":
            slice_state["status"] = "interrupted"
            slice_state["finished_at"] = now_iso()
            slice_state["message"] = "previous runner stopped before this slice completed"
            child_pid = slice_state.pop("child_pid", None)
            if child_pid and is_pid_alive(child_pid):
                terminate_process_tree(child_pid)


def generate_report(ctx: RunContext) -> str:
    rows = []
    counts: dict[str, int] = {}
    for item in ctx.manifest.get("slices", []):
        result = ctx.state["slices"][item["id"]]
        status = result["status"]
        counts[status] = counts.get(status, 0) + 1
        duration = "-" if result["duration_seconds"] is None else f"{result['duration_seconds']}s"
        exit_code = "-" if result["exit_code"] is None else str(result["exit_code"])
        log_path = result.get("log_path") or "-"
        message = (result.get("message") or "-").replace("|", "\\|").replace("\n", " ")
        rows.append(
            f"| {item['id']} | {item.get('name', item['id'])} | {status} | "
            f"{result['attempts']} | {exit_code} | {duration} | `{log_path}` | {message} |"
        )
    counts_text = ", ".join(f"{key}={value}" for key, value in sorted(counts.items())) or "无"
    content = f"""# MES 可恢复回归报告

- 运行 ID：`{ctx.state['run_id']}`
- 任务：{ctx.state['name']}
- 状态：**{ctx.state['status']}**
- 创建时间：{ctx.state['created_at']}
- 更新时间：{ctx.state['updated_at']}
- 汇总：{counts_text}

| 切片 | 名称 | 状态 | 尝试 | 退出码 | 耗时 | 原始日志 | 说明 |
|---|---|---:|---:|---:|---:|---|---|
{chr(10).join(rows)}

## 恢复方式

```bash
python harness/scripts/resilient_regression.py status --run-dir "{ctx.run_dir}"
python harness/scripts/resilient_regression.py resume --run-dir "{ctx.run_dir}"
```

> `passed` 表示命令真实退出码为 0；`blocked_environment` 表示依赖服务不可用，未当作产品失败。
"""
    local_report = ctx.run_dir / "summary.md"
    write_text_atomic(local_report, content)
    configured = ctx.manifest.get("report_path")
    if configured:
        write_text_atomic((REPO_ROOT / configured).resolve(), content)
    return content


def execute_run(run_dir: Path, retry_failed: bool = False) -> int:
    manifest_path = run_dir / "manifest.json"
    if not manifest_path.exists():
        raise FileNotFoundError(f"manifest snapshot not found: {manifest_path}")
    manifest = read_json(manifest_path)
    state_path = run_dir / "state.json"
    state = read_json(state_path) if state_path.exists() else initial_state(manifest, run_dir)
    ctx = RunContext(run_dir, manifest, state)

    with RunLock(run_dir / "runner.lock"):
        recover_interrupted_state(state)
        state.update(
            {
                "status": "running",
                "runner_pid": os.getpid(),
                "current_slice": None,
                "heartbeat_at": now_iso(),
            }
        )
        ctx.save()
        ctx.heartbeat("runner-started", force=True)

        blocked = False
        for item in manifest.get("slices", []):
            slice_state = state["slices"][item["id"]]
            status = slice_state["status"]
            if status == "passed" or status == "skipped":
                continue
            if status in {"failed", "timeout"} and not retry_failed:
                continue
            if status not in RETRYABLE_STATUSES and not retry_failed:
                continue

            state["current_slice"] = item["id"]
            ctx.heartbeat("slice-preflight", force=True)
            requirements_ok, requirement_message = check_requirements(ctx, item)
            if not requirements_ok:
                slice_state.update(
                    {
                        "status": "blocked_environment",
                        "finished_at": now_iso(),
                        "message": requirement_message,
                        "exit_code": None,
                        "timed_out": False,
                    }
                )
                state["status"] = "blocked_environment"
                blocked = True
                ctx.save()
                generate_report(ctx)
                break

            slice_state.update(
                {
                    "status": "running",
                    "attempts": slice_state["attempts"] + 1,
                    "started_at": now_iso(),
                    "finished_at": None,
                    "duration_seconds": None,
                    "exit_code": None,
                    "timed_out": False,
                    "message": None,
                }
            )
            ctx.save()
            try:
                exit_code, timed_out, duration, log_path = run_slice_process(ctx, item, slice_state)
                slice_state.pop("child_pid", None)
                slice_state.update(
                    {
                        "finished_at": now_iso(),
                        "duration_seconds": duration,
                        "exit_code": exit_code,
                        "timed_out": timed_out,
                        "log_path": log_path,
                    }
                )
                if timed_out:
                    slice_state["status"] = "timeout"
                    slice_state["message"] = f"exceeded {item.get('timeout_seconds', 300)} seconds"
                elif exit_code == 0:
                    slice_state["status"] = "passed"
                    slice_state["message"] = "command exited with code 0"
                else:
                    slice_state["status"] = "failed"
                    slice_state["message"] = f"command exited with code {exit_code}"
            except Exception as error:  # The error is durable; later slices may still be useful.
                child_pid = slice_state.pop("child_pid", None)
                if child_pid:
                    terminate_process_tree(int(child_pid))
                slice_state.update(
                    {
                        "status": "failed",
                        "finished_at": now_iso(),
                        "exit_code": None,
                        "timed_out": False,
                        "message": f"runner error: {type(error).__name__}: {error}",
                    }
                )
            ctx.save()
            generate_report(ctx)
            ctx.heartbeat("slice-finished", force=True)
            if slice_state["status"] in {"failed", "timeout"} and not item.get("continue_on_failure", True):
                break

        state["current_slice"] = None
        statuses = [value["status"] for value in state["slices"].values()]
        if blocked:
            state["status"] = "blocked_environment"
            exit_code = 2
        elif statuses and all(status in {"passed", "skipped"} for status in statuses):
            state["status"] = "completed"
            exit_code = 0
        elif any(status in {"failed", "timeout"} for status in statuses):
            state["status"] = "completed_with_failures"
            exit_code = 1
        else:
            state["status"] = "interrupted"
            exit_code = 1
        state["runner_pid"] = None
        ctx.save()
        ctx.heartbeat("runner-finished", force=True)
        generate_report(ctx)
        return exit_code


def create_run(manifest_source: Path, run_dir: Path) -> None:
    manifest_path = manifest_snapshot(manifest_source, run_dir)
    manifest = read_json(manifest_path)
    state_path = run_dir / "state.json"
    if not state_path.exists():
        atomic_write_json(state_path, initial_state(manifest, run_dir))


def detached_launch(run_dir: Path, retry_failed: bool = False) -> int:
    runner_log = run_dir / "runner.log"
    command = [sys.executable, str(Path(__file__).resolve()), "_worker", "--run-dir", str(run_dir)]
    if retry_failed:
        command.append("--retry-failed")
    runner_log.parent.mkdir(parents=True, exist_ok=True)
    with runner_log.open("ab", buffering=0) as log_stream:
        process = subprocess.Popen(
            command,
            cwd=REPO_ROOT,
            stdin=subprocess.DEVNULL,
            stdout=log_stream,
            stderr=subprocess.STDOUT,
            creationflags=process_creation_flags(detached=True),
            start_new_session=(os.name != "nt"),
        )
    (run_dir / "runner.pid").write_text(str(process.pid), encoding="ascii")
    return process.pid


def latest_run_dir(runs_dir: Path = DEFAULT_RUNS_DIR) -> Path:
    candidates = sorted((path for path in runs_dir.glob("*") if path.is_dir()), reverse=True)
    if not candidates:
        raise FileNotFoundError(f"no regression runs found under {runs_dir}")
    return candidates[0]


def resolve_run_dir(value: str | None) -> Path:
    return Path(value).resolve() if value else latest_run_dir()


def print_status(run_dir: Path) -> None:
    state = read_json(run_dir / "state.json")
    print(json.dumps(state, ensure_ascii=False, indent=2))


def stop_run(run_dir: Path, stop_services: bool) -> None:
    state_path = run_dir / "state.json"
    state = read_json(state_path)
    runner_pid = state.get("runner_pid")
    if runner_pid:
        terminate_process_tree(int(runner_pid))
    if stop_services:
        for service in state.get("services", {}).values():
            pid = service.get("pid")
            if pid:
                terminate_process_tree(int(pid))
                service["status"] = "stopped"
    recover_interrupted_state(state)
    state["status"] = "stopped"
    state["runner_pid"] = None
    state["current_slice"] = None
    state["updated_at"] = now_iso()
    atomic_write_json(state_path, state)
    print(f"stopped: {run_dir}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Crash-resilient MES regression runner")
    subparsers = parser.add_subparsers(dest="command", required=True)

    start_parser = subparsers.add_parser("start", help="start a detached regression run")
    start_parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
    start_parser.add_argument("--run-dir")

    run_parser = subparsers.add_parser("run", help="run in the foreground")
    run_parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
    run_parser.add_argument("--run-dir", required=True)
    run_parser.add_argument("--retry-failed", action="store_true")

    resume_parser = subparsers.add_parser("resume", help="resume a durable run")
    resume_parser.add_argument("--run-dir")
    resume_parser.add_argument("--foreground", action="store_true")
    resume_parser.add_argument("--retry-failed", action="store_true")

    status_parser = subparsers.add_parser("status", help="show durable state")
    status_parser.add_argument("--run-dir")

    stop_parser = subparsers.add_parser("stop", help="stop a run")
    stop_parser.add_argument("--run-dir")
    stop_parser.add_argument("--services", action="store_true")

    report_parser = subparsers.add_parser("report", help="regenerate Markdown summary")
    report_parser.add_argument("--run-dir")

    worker_parser = subparsers.add_parser("_worker", help=argparse.SUPPRESS)
    worker_parser.add_argument("--run-dir", required=True)
    worker_parser.add_argument("--retry-failed", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.command == "start":
        manifest = Path(args.manifest).resolve()
        run_dir = (
            Path(args.run_dir).resolve()
            if args.run_dir
            else DEFAULT_RUNS_DIR / datetime.now().strftime("%Y%m%d-%H%M%S")
        )
        create_run(manifest, run_dir)
        pid = detached_launch(run_dir)
        print(json.dumps({"run_dir": str(run_dir), "pid": pid}, ensure_ascii=False))
        return 0
    if args.command == "run":
        run_dir = Path(args.run_dir).resolve()
        create_run(Path(args.manifest).resolve(), run_dir)
        return execute_run(run_dir, retry_failed=args.retry_failed)
    if args.command == "resume":
        run_dir = resolve_run_dir(args.run_dir)
        if args.foreground:
            return execute_run(run_dir, retry_failed=args.retry_failed)
        pid = detached_launch(run_dir, retry_failed=args.retry_failed)
        print(json.dumps({"run_dir": str(run_dir), "pid": pid}, ensure_ascii=False))
        return 0
    if args.command == "status":
        print_status(resolve_run_dir(args.run_dir))
        return 0
    if args.command == "stop":
        stop_run(resolve_run_dir(args.run_dir), args.services)
        return 0
    if args.command == "report":
        run_dir = resolve_run_dir(args.run_dir)
        manifest = read_json(run_dir / "manifest.json")
        state = read_json(run_dir / "state.json")
        print(generate_report(RunContext(run_dir, manifest, state)))
        return 0
    if args.command == "_worker":
        return execute_run(Path(args.run_dir).resolve(), retry_failed=args.retry_failed)
    return 2


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"fatal: {type(error).__name__}: {error}", file=sys.stderr)
        raise SystemExit(3)
# update-end---author:pi---date:2026-08-04---for:【REGRESSION-CRASH-GUARD】新增可脱离Orca运行的回归任务控制器---

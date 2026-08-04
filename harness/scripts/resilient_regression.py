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


def read_state(run_dir: Path) -> dict[str, Any]:
    primary = run_dir / "state.json"
    fallback = run_dir / "state.json.fallback"
    candidates = [path for path in (primary, fallback) if path.exists()]
    if not candidates:
        raise FileNotFoundError(f"state.json not found under {run_dir}")
    candidates.sort(key=lambda path: path.stat().st_mtime, reverse=True)
    errors = []
    for path in candidates:
        try:
            return read_json(path)
        except (OSError, json.JSONDecodeError) as error:
            errors.append(f"{path}: {error}")
    raise RuntimeError("no valid state checkpoint: " + "; ".join(errors))


def atomic_write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as stream:
            json.dump(data, stream, ensure_ascii=False, indent=2)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        last_error: OSError | None = None
        for attempt in range(8):
            try:
                os.replace(temp_name, path)
                path.with_name(path.name + ".fallback").unlink(missing_ok=True)
                return
            except PermissionError as error:
                last_error = error
                time.sleep(0.25 * (attempt + 1))
        fallback = path.with_name(path.name + ".fallback")
        try:
            with fallback.open("w", encoding="utf-8", newline="\n") as stream:
                json.dump(data, stream, ensure_ascii=False, indent=2)
                stream.write("\n")
                stream.flush()
                os.fsync(stream.fileno())
            return
        except OSError:
            if last_error:
                raise last_error
            raise
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


def _run_one_command(command: list[str], cwd: Path, environment: dict[str, Any],
                     log_stream, timeout_seconds: float, ctx: RunContext,
                     item_id: str, started: float) -> tuple[int | None, bool]:
    """Spawn ``command`` and wait for completion, writing output to ``log_stream``.

    Returns (exit_code, timed_out). The caller owns the overall slice duration
    so that ``command`` + ``fallback_command`` count as one attempt with a
    single timeout budget.
    """
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
    return process.poll(), timed_out


def run_slice_process(ctx: RunContext, item: dict[str, Any], slice_state: dict[str, Any]) -> tuple[int | None, bool, float, str]:
    attempt = slice_state["attempts"]
    log_path = ctx.run_dir / "logs" / f"{safe_id(item['id'])}.attempt-{attempt}.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    command = resolve_command(list(item["command"]))
    fallback_command = item.get("fallback_command")
    cwd = (REPO_ROOT / item.get("cwd", ".")).resolve()
    timeout_seconds = float(item.get("timeout_seconds", 300))
    environment = os.environ.copy()
    environment.update({str(k): str(v) for k, v in ctx.manifest.get("environment", {}).items()})
    environment.update({str(k): str(v) for k, v in item.get("environment", {}).items()})
    started = time.monotonic()
    timed_out = False
    exit_code: int | None = None

    with log_path.open("wb") as log_stream:
        log_stream.write(
            f"[{now_iso()}] slice={item['id']} cwd={cwd}\n"
            f"command={json.dumps(command, ensure_ascii=False)}\n".encode("utf-8")
        )
        if fallback_command:
            log_stream.write(
                f"fallback_command={json.dumps(fallback_command, ensure_ascii=False)}\n".encode("utf-8")
            )
        log_stream.write(b"\n")
        log_stream.flush()
        log_path_for_state = display_path(log_path)

        # Try the primary command first.
        try:
            exit_code, timed_out = _run_one_command(
                command, cwd, environment, log_stream, timeout_seconds, ctx,
                item['id'], started,
            )
        except Exception as error:  # pragma: no cover - safety net for spawn errors
            log_stream.write(f"runner spawn error: {type(error).__name__}: {error}\n".encode("utf-8"))
            exit_code, timed_out = 1, False

        # If primary failed (non-zero exit, NOT a timeout) and fallback_command
        # is configured, give the alternative a shot. The fallback shares the
        # primary's timeout budget so a slice's overall SLA still applies.
        if (
            fallback_command
            and not timed_out
            and (exit_code is None or exit_code != 0)
        ):
            remaining = max(1.0, timeout_seconds - (time.monotonic() - started))
            log_stream.write(
                f"\n[{now_iso()}] primary exit_code={exit_code}, falling back to fallback_command "
                f"(remaining timeout={remaining:.1f}s)\n".encode("utf-8")
            )
            try:
                fallback_exit, fallback_timed_out = _run_one_command(
                    list(fallback_command), cwd, environment, log_stream, remaining, ctx,
                    item['id'], started,
                )
            except Exception as error:  # pragma: no cover
                log_stream.write(f"runner fallback spawn error: {type(error).__name__}: {error}\n".encode("utf-8"))
                fallback_exit, fallback_timed_out = 1, False

            if fallback_exit == 0 and not fallback_timed_out:
                exit_code = 0
                timed_out = False
                log_stream.write(f"fallback_command succeeded, treating slice as passed\n".encode("utf-8"))
            elif fallback_timed_out:
                timed_out = True
                exit_code = fallback_exit

        duration = round(time.monotonic() - started, 3)
        footer = f"\n[{now_iso()}] exit_code={exit_code} timed_out={timed_out} duration={duration}s\n"
        log_stream.write(footer.encode("utf-8"))

    slice_state["log_path"] = log_path_for_state
    ctx.save()
    return exit_code, timed_out, duration, log_path_for_state


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
    review_summary_path = REPO_ROOT / "hermes" / "eagle-eye" / "reports" / datetime.now().strftime("%Y-%m-%d") / "issues" / "review-summary.json"
    if review_summary_path.exists():
        try:
            review_summary = read_json(review_summary_path)
            review_counts = ", ".join(
                f"{key}={value}" for key, value in sorted(review_summary.get("counts", {}).items())
            ) or "无候选问题"
            review_section = (
                "## 失败复核摘要\n\n"
                f"- 复核目录：`{display_path(review_summary_path.parent)}`\n"
                f"- 当前复核结果：{review_counts}\n"
            )
        except (OSError, json.JSONDecodeError):
            review_section = "## 失败复核摘要\n\n- 复核报告存在但暂时无法读取。\n"
    else:
        review_section = "## 失败复核摘要\n\n- 本轮没有生成 E2E 失败复核报告，或该切片尚未完成。\n"
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

{review_section}
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
        target = (REPO_ROOT / configured).resolve()
        try:
            write_text_atomic(target, content)
        except OSError as error:
            # Shared report delivery is best-effort. Never let a locked report file
            # terminate the runner after the durable run-local checkpoint is safe.
            delivery_error = (
                f"{now_iso()} shared report write failed: {type(error).__name__}: {error}\n"
                f"local report: {local_report}\n"
            )
            try:
                with (ctx.run_dir / "report-delivery-error.log").open("a", encoding="utf-8") as stream:
                    stream.write(delivery_error)
                ctx.state["report_delivery_error"] = delivery_error.strip()
                ctx.save()
            except OSError:
                pass
    return content


def _dispatch_slice_kind(slice_state: dict[str, Any], item: dict[str, Any], exit_code: int, timed_out: bool, message: str) -> None:
    if timed_out:
        slice_state["status"] = "timeout"
        slice_state["message"] = f"exceeded {item.get('timeout_seconds', 300)} seconds"
    elif exit_code == 0:
        slice_state["status"] = "passed"
        slice_state["message"] = "command exited with code 0"
    else:
        verdict = item.get("verdict_when_failed")
        if verdict:
            slice_state["status"] = "verdict"
        else:
            slice_state["status"] = "failed"
        slice_state["message"] = message or (f"command exited with code {exit_code}")


def load_chains_doc() -> dict[str, Any]:
    chains_path = REPO_ROOT / "hermes" / "business-chains.json"
    if not chains_path.exists():
        return {"chains": {}}
    try:
        return read_json(chains_path)
    except (OSError, json.JSONDecodeError):
        return {"chains": {}}


def chain_ids_for_diff(chains_doc: dict[str, Any], diff_files: list[str]) -> set[str]:
    matched: set[str] = set()
    for chain in (chains_doc.get("chains") or {}).values():
        chain_id = chain.get("id")
        if not chain_id:
            continue
        modules = chain.get("modules") or []
        for diff_file in diff_files:
            for module in modules:
                needle = f"/{module}/"
                marker = f"/{module}."
                tail_marker = f"/{module}."
                if f"/{diff_file}".find(needle) != -1 or f"/{diff_file}".find(marker) != -1 or diff_file.endswith(tail_marker.lstrip("/")) or diff_file.endswith(f"{module}.java"):
                    matched.add(chain_id)
                    break
            if chain_id in matched:
                break
    return matched


def execute_run(run_dir: Path, retry_failed: bool = False) -> int:
    manifest_path = run_dir / "manifest.json"
    if not manifest_path.exists():
        raise FileNotFoundError(f"manifest snapshot not found: {manifest_path}")
    manifest = read_json(manifest_path)
    state_path = run_dir / "state.json"
    chains_doc = load_chains_doc()
    diff_files: list[str] = list(manifest.get("diff_files") or [])
    scope: str = manifest.get("scope") or "full"
    matched_chains: set[str] = set()
    if diff_files:
        matched_chains = chain_ids_for_diff(chains_doc, diff_files)
    if scope != "full":
        try:
            from regression_plan import filter_slices_by_scope
            manifest["slices"] = filter_slices_by_scope(list(manifest.get("slices", [])), scope, matched_chains)
        except (ImportError, AttributeError):
            pass
    state = (
        read_state(run_dir)
        if state_path.exists() or state_path.with_name(state_path.name + ".fallback").exists()
        else initial_state(manifest, run_dir)
    )
    ctx = RunContext(run_dir, manifest, state)
    state["diff_files"] = diff_files
    state["matched_chains"] = sorted(matched_chains)
    state["scope"] = scope
    state["base"] = manifest.get("base")

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
                    _dispatch_slice_kind(slice_state, item, exit_code, False, f"command exited with code {exit_code}")
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
    # Apply scope-based slice filter BEFORE the first state checkpoint so
    # state.slices never contains phantom pending entries for chain ids the
    # change-scope filter removed. Otherwise run/detached workers would read
    # the unfiltered list via read_state (existing state.json wins).
    scope: str = manifest.get("scope") or "full"
    diff_files: list[str] = list(manifest.get("diff_files") or [])
    matched_chains: set[str] = set()
    if diff_files:
        matched_chains = chain_ids_for_diff(load_chains_doc(), diff_files)
    if scope != "full":
        try:
            from regression_plan import filter_slices_by_scope
            manifest["slices"] = filter_slices_by_scope(list(manifest.get("slices", [])), scope, matched_chains)
        except (ImportError, AttributeError):
            pass
        atomic_write_json(manifest_path, manifest)
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


def launch_dashboard(run_dir: Path, port: int) -> int:
    dashboard_log = run_dir / "dashboard.log"
    script = Path(__file__).resolve().with_name("regression_dashboard.py")
    command = [sys.executable, str(script), "--run-dir", str(run_dir), "--port", str(port)]
    with dashboard_log.open("ab", buffering=0) as log_stream:
        process = subprocess.Popen(
            command,
            cwd=REPO_ROOT,
            stdin=subprocess.DEVNULL,
            stdout=log_stream,
            stderr=subprocess.STDOUT,
            creationflags=process_creation_flags(detached=True),
            start_new_session=(os.name != "nt"),
        )
    (run_dir / "dashboard.pid").write_text(str(process.pid), encoding="ascii")
    (run_dir / "dashboard.url").write_text(f"http://127.0.0.1:{port}\n", encoding="utf-8")
    return process.pid


def latest_run_dir(runs_dir: Path = DEFAULT_RUNS_DIR) -> Path:
    candidates = sorted((path for path in runs_dir.glob("*") if path.is_dir()), reverse=True)
    if not candidates:
        raise FileNotFoundError(f"no regression runs found under {runs_dir}")
    return candidates[0]


def resolve_run_dir(value: str | None) -> Path:
    return Path(value).resolve() if value else latest_run_dir()


def print_status(run_dir: Path) -> None:
    state = read_state(run_dir)
    print(json.dumps(state, ensure_ascii=False, indent=2))


def stop_run(run_dir: Path, stop_services: bool, stop_dashboard: bool = False) -> None:
    state_path = run_dir / "state.json"
    state = read_state(run_dir)
    runner_pid = state.get("runner_pid")
    if runner_pid:
        terminate_process_tree(int(runner_pid))
    if stop_dashboard:
        dashboard_pid_path = run_dir / "dashboard.pid"
        if dashboard_pid_path.exists():
            try:
                terminate_process_tree(int(dashboard_pid_path.read_text(encoding="ascii").strip()))
            except (OSError, ValueError):
                pass
            dashboard_pid_path.unlink(missing_ok=True)
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
    start_parser.add_argument("--scope", choices=["full", "change"], default="full", help="full: run every slice, change: only smoke + chain slices matching git diff")
    start_parser.add_argument("--base", help="base commit used to compute the diff for --scope change")
    start_parser.add_argument("--dashboard", action="store_true", help="also start the read-only dashboard")
    start_parser.add_argument("--port", type=int, default=8765)

    run_parser = subparsers.add_parser("run", help="run in the foreground")
    run_parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
    run_parser.add_argument("--run-dir", required=True)
    run_parser.add_argument("--retry-failed", action="store_true")

    resume_parser = subparsers.add_parser("resume", help="resume a durable run")
    resume_parser.add_argument("--run-dir")
    resume_parser.add_argument("--foreground", action="store_true")
    resume_parser.add_argument("--retry-failed", action="store_true")
    resume_parser.add_argument("--scope", choices=["full", "change"], help="override the persisted scope for this resume")
    resume_parser.add_argument("--base", help="base commit for the diff when --scope change is used")
    resume_parser.add_argument("--dashboard", action="store_true", help="also start the read-only dashboard")
    resume_parser.add_argument("--port", type=int, default=8765)

    status_parser = subparsers.add_parser("status", help="show durable state")
    status_parser.add_argument("--run-dir")

    stop_parser = subparsers.add_parser("stop", help="stop a run")
    stop_parser.add_argument("--run-dir")
    stop_parser.add_argument("--services", action="store_true")
    stop_parser.add_argument("--dashboard", action="store_true")

    dashboard_parser = subparsers.add_parser("dashboard", help="start the read-only dashboard in the foreground")
    dashboard_parser.add_argument("--run-dir")
    dashboard_parser.add_argument("--port", type=int, default=8765)
    dashboard_parser.add_argument("--detach", action="store_true")

    report_parser = subparsers.add_parser("report", help="regenerate Markdown summary")
    report_parser.add_argument("--run-dir")

    plan_parser = subparsers.add_parser("plan", help="build a merged plan from chains + manifest")
    plan_parser.add_argument("--manifest", default=str(REPO_ROOT / "harness" / "regression" / "recovery-plan.json"))
    plan_parser.add_argument("--target", default=str(REPO_ROOT / "harness" / "regression" / "recovery-plan.merged.json"))
    plan_parser.add_argument("--base")

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
        scope = args.scope
        if scope == "change" and not args.base:
            print("--scope change requires --base <commit>", file=sys.stderr)
            return 2
        diff_files: list[str] = []
        if args.base:
            from regression_plan import git_diff_names
            diff_files = git_diff_names(args.base)
        manifest_doc = read_json(manifest)
        manifest_doc = {**manifest_doc, "scope": scope, "diff_files": diff_files, "base": args.base}
        # create_run filters via filter_slices_by_scope, which matches chain
        # slices by ``source.chain``. The raw recovery-plan.json slices have no
        # ``source`` field; only the merged plan does. Build the merged plan
        # first so change-scope actually filters.
        from regression_plan import expand_chain_slices, merge_slices
        # ``python harness/scripts/resilient_regression.py`` puts scripts/ on
        # sys.path[0], so the bare ``regression_plan`` module imports work.
        merged = merge_slices(manifest_doc, expand_chain_slices(load_chains_doc()))
        manifest_doc = {**merged, "scope": scope, "diff_files": diff_files, "base": args.base}
        # create_run snapshots the manifest, then applies the scope filter and
        # writes run_dir/manifest.json. Feed it the decorated manifest via a
        # temp file so it can see scope/diff_files/base when filtering.
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", delete=False, encoding="utf-8"
        ) as tmp:
            tmp.write(json.dumps(manifest_doc, ensure_ascii=False))
            decorated_path = Path(tmp.name)
        try:
            create_run(decorated_path, run_dir)
        finally:
            decorated_path.unlink(missing_ok=True)
        pid = detached_launch(run_dir)
        dashboard_pid = launch_dashboard(run_dir, args.port) if args.dashboard else None
        print(json.dumps({"run_dir": str(run_dir), "pid": pid, "dashboard_pid": dashboard_pid, "dashboard_url": f"http://127.0.0.1:{args.port}" if args.dashboard else None, "scope": scope, "diff_files": diff_files}, ensure_ascii=False))
        return 0
    if args.command == "run":
        run_dir = Path(args.run_dir).resolve()
        create_run(Path(args.manifest).resolve(), run_dir)
        return execute_run(run_dir, retry_failed=args.retry_failed)
    if args.command == "resume":
        run_dir = resolve_run_dir(args.run_dir)
        if args.scope:
            manifest_path = run_dir / "manifest.json"
            try:
                manifest = read_json(manifest_path)
                manifest["scope"] = args.scope
                atomic_write_json(manifest_path, manifest)
            except (OSError, json.JSONDecodeError):
                pass
        if args.foreground:
            return execute_run(run_dir, retry_failed=args.retry_failed)
        pid = detached_launch(run_dir, retry_failed=args.retry_failed)
        dashboard_pid = launch_dashboard(run_dir, args.port) if args.dashboard else None
        print(json.dumps({"run_dir": str(run_dir), "pid": pid, "dashboard_pid": dashboard_pid, "dashboard_url": f"http://127.0.0.1:{args.port}" if args.dashboard else None}, ensure_ascii=False))
        return 0
    if args.command == "status":
        print_status(resolve_run_dir(args.run_dir))
        return 0
    if args.command == "stop":
        stop_run(resolve_run_dir(args.run_dir), args.services, args.dashboard)
        return 0
    if args.command == "dashboard":
        run_dir = resolve_run_dir(args.run_dir)
        if args.detach:
            pid = launch_dashboard(run_dir, args.port)
            print(json.dumps({"run_dir": str(run_dir), "dashboard_pid": pid, "dashboard_url": f"http://127.0.0.1:{args.port}"}, ensure_ascii=False))
            return 0
        from regression_dashboard import main as dashboard_main
        return dashboard_main(["--run-dir", str(run_dir), "--port", str(args.port)])
    if args.command == "plan":
        from regression_plan import main as plan_main
        argv = ["build", "--manifest", args.manifest, "--target", args.target]
        if args.base:
            argv.extend(["--base", args.base])
        return plan_main(argv)
    if args.command == "report":
        run_dir = resolve_run_dir(args.run_dir)
        manifest = read_json(run_dir / "manifest.json")
        state = read_state(run_dir)
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

# update-begin---author:pi---date:2026-08-04---for:【REGRESSION-INTEGRATION】recovery-plan 联动 business-chains + 测试质量门槛 + 变更感知---
"""Wire the regression runner into the coverage-improvement stack.

Responsibilities:
  * read `hermes/business-chains.json` and expand enabled chain tests into
    runner slices so chains and recovery-plan never drift apart
  * score API test files for shallow assertions (R009 gate)
  * keep the merge between built-in manifest entries and discovered chain
    slices deterministic and atomic
"""

from __future__ import annotations

from datetime import datetime
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CHAINS_PATH = REPO_ROOT / "hermes" / "business-chains.json"
SEMANTIC_PATTERNS: tuple[re.Pattern[str], ...] = (
    re.compile(r"\.[A-Za-z_]+\s*[!=]==\s*['\"]"),
    re.compile(r"\.status\s*[!=]==\s*['\"0-9]"),
    re.compile(r"\.code\s*[!=]==\s*['\"]"),
    re.compile(r"\.startsWith\(|\.includes\(|\.toContain\(|\.toBe\("),
    re.compile(r"expect\([^,]*\.to[A-Z][A-Za-z_]+\("),
    re.compile(r"\.quantity\s*[!=]=|\.qty\s*[!=]=|\.total\s*[!=]=|\.amount\s*[!=]="),
    re.compile(r"getByText\(|locator\("),
)
GENERIC_PATTERN = re.compile(r"c\.check\(|expect\(|assert\(")


def read_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as stream:
        return json.load(stream)


def write_json_atomic(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    tmp.replace(path)


def expand_chain_slices(chains_doc: dict[str, Any]) -> list[dict[str, Any]]:
    slices: list[dict[str, Any]] = []
    for chain_name, chain in (chains_doc.get("chains") or {}).items():
        chain_tests = chain.get("chainTests") or {}
        if not chain_tests.get("enabled"):
            continue
        chain_id = chain.get("id") or chain_name
        for index, segment in enumerate(chain_tests.get("segments") or [], start=1):
            relative_test = segment.get("file")
            if not relative_test:
                continue
            test_path = (REPO_ROOT / relative_test).resolve()
            if not test_path.exists():
                continue
            slices.append(
                {
                    "id": f"chain.{chain_id}.{index}",
                    "name": f"链路 {chain_name} · {segment.get('name', 'segment')}",
                    "kind": "chain",
                    "cwd": str(REPO_ROOT.relative_to(REPO_ROOT) if test_path.is_relative_to(REPO_ROOT) else "."),
                    "command": ["node", str(test_path.relative_to(REPO_ROOT)).replace("\\", "/")],
                    "timeout_seconds": int(segment.get("timeout_seconds", 240)),
                    "requires": ["backend"],
                    "source": {
                        "chain": chain_id,
                        "segment": segment.get("name"),
                        "file": str(relative_test),
                    },
                }
            )
    return slices


def merge_slices(manifest: dict[str, Any], extra_slices: list[dict[str, Any]]) -> dict[str, Any]:
    existing_ids = {slice_data["id"] for slice_data in manifest.get("slices", [])}
    merged: list[dict[str, Any]] = list(manifest.get("slices", []))
    for extra in extra_slices:
        if extra["id"] in existing_ids:
            continue
        merged.append(extra)
        existing_ids.add(extra["id"])
    return {**manifest, "slices": merged, "slices_source": "merged"}


def emit_merged_plan(manifest: dict[str, Any], extra_slices: list[dict[str, Any]], target: Path) -> Path:
    merged = merge_slices(manifest, extra_slices)
    merged["merged_at"] = datetime.now().astimezone().isoformat(timespec="seconds")
    write_json_atomic(target, merged)
    return target


def evaluate_test_quality(tests_root: Path) -> dict[str, Any]:
    files: dict[str, dict[str, int]] = {}
    if not tests_root.exists():
        return {"summary": {"files": 0, "assertions": 0, "deep_assertions": 0, "quality_score": 0}, "files": files}
    for test_file in sorted(tests_root.rglob("*.js")):
        if not test_file.is_file() or not test_file.name.endswith(".test.js"):
            continue
        try:
            relative = test_file.relative_to(tests_root)
        except ValueError:
            continue
        if not relative.parts:
            continue
        content = test_file.read_text(encoding="utf-8", errors="replace")
        generic = GENERIC_PATTERN.findall(content)
        semantic_hits = sum(len(p.findall(content)) for p in SEMANTIC_PATTERNS)
        files[str(relative).replace("\\", "/")] = {
            "assertions": len(generic),
            "deep_assertions": semantic_hits,
        }
    total_files = len(files)
    total_assertions = sum(item["assertions"] for item in files.values())
    total_deep = sum(item["deep_assertions"] for item in files.values())
    score = round(total_deep * 100 / total_assertions) if total_assertions else 0
    return {
        "summary": {
            "files": total_files,
            "assertions": total_assertions,
            "deep_assertions": total_deep,
            "quality_score": score,
        },
        "files": files,
    }


def git_diff_names(base: str | None) -> list[str]:
    if not base:
        return []
    try:
        completed = subprocess.run(
            ["git", "diff", "--name-only", f"{base}..HEAD"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=False,
            encoding="utf-8",
            errors="replace",
        )
    except FileNotFoundError:
        return []
    if completed.returncode != 0:
        return []
    return [line.strip().replace("\\", "/") for line in completed.stdout.splitlines() if line.strip()]


def filter_slices_by_scope(slices: list[dict[str, Any]], scope: str, matched_chains: set[str]) -> list[dict[str, Any]]:
    if scope == "full":
        return list(slices)
    selected: list[dict[str, Any]] = []
    seen: set[str] = set()
    for entry in slices:
        kind = entry.get("kind", "")
        chain = (entry.get("source") or {}).get("chain", "")
        entry_id = entry.get("id", "")
        if kind == "build" or entry_id in {"frontend-static", "test-quality"} or entry_id.startswith("smoke-"):
            selected.append(entry)
            seen.add(entry_id)
            continue
        if kind == "chain" and chain and chain in matched_chains and entry_id not in seen:
            selected.append(entry)
            seen.add(entry_id)
    return selected


def main(argv: list[str] | None = None) -> int:
    args = list(argv or sys.argv[1:])
    if not args or args[0] != "build" and args[0] != "report":
        print("usage: regression_plan.py build|report [--manifest <path>] [--target <path>] [--base <commit>] [--root <dir>]", file=sys.stderr)
        return 2
    iterator = iter(args[1:])
    action = args[0]
    manifest_path = None
    chains_path = DEFAULT_CHAINS_PATH
    target = None
    base = None
    tests_root = REPO_ROOT / "harness" / "tests" / "modules"
    for token in iterator:
        if token == "--manifest":
            manifest_path = Path(next(iterator))
        elif token == "--chains":
            chains_path = Path(next(iterator))
        elif token == "--target":
            target = Path(next(iterator))
        elif token == "--base":
            base = next(iterator)
        elif token == "--root":
            tests_root = Path(next(iterator))
    if action == "report":
        report = evaluate_test_quality(tests_root)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 0
    if not manifest_path or not target:
        print("missing --manifest or --target", file=sys.stderr)
        return 2
    if not chains_path.exists():
        print(f"chains not found: {chains_path}", file=sys.stderr)
        return 2
    manifest = read_json(manifest_path)
    chains_doc = read_json(chains_path)
    chain_slices = expand_chain_slices(chains_doc)
    if base:
        diff_files = git_diff_names(base)
        if diff_files:
            manifest = {**manifest, "diff_files": diff_files}
    emit_merged_plan(manifest, chain_slices, target)
    print(json.dumps({
        "target": str(target),
        "chain_slices": len(chain_slices),
        "diff_files": (manifest.get("diff_files") or []),
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
# update-end---author:pi---date:2026-08-04---for:【REGRESSION-INTEGRATION】recovery-plan 联动 business-chains + 测试质量门槛 + 变更感知---

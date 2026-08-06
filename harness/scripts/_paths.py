#!/usr/bin/env python3
# update-begin---author:pi---date:2026-08-06---for:【PATHS-CONFIG】Phase 3 路径集中加载器---
"""harness/scripts/_paths.py — 路径集中加载器

Phase 3 / 建议 5：所有 driver 通过此模块读 paths.json，向后兼容（缺文件时硬编码）。

用法：
    from _paths import PATHS, REPO_ROOT, resolve, reload_paths
    manifest_path = resolve(PATHS['harness']['regression_manifest'])
"""
from __future__ import annotations

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Any

REPO_ROOT: Path = Path(__file__).resolve().parents[2]  # harness/scripts/_paths.py → jeecgBoot/
DEFAULT_PATHS_FILE: Path = REPO_ROOT / "harness" / "config" / "paths.json"

# 缺文件时的硬编码 fallback（与 paths.json 内容保持一致）
_FALLBACK: dict[str, dict[str, str]] = {
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
        "dashboard": "harness/dashboard",
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
            # 移除元数据键（_description / _doc / _template_vars / _comment）
            return {k: v for k, v in loaded.items() if not k.startswith("_")}
        except (OSError, json.JSONDecodeError) as e:
            print(
                f"⚠️  paths.json 加载失败 ({e.__class__.__name__}: {e})，使用 fallback"
            )
    return _FALLBACK


PATHS: dict[str, Any] = load_paths()


def reload_paths() -> dict[str, Any]:
    """手动重载 paths.json（用于 detached runner 周期性刷新，默认不调用）。"""
    global PATHS
    PATHS = load_paths()
    return PATHS


def resolve(rel_or_abs: str, date: str | None = None) -> Path:
    """解析路径：绝对路径直接用，相对路径以 REPO_ROOT 为锚，支持 ${date} 模板。

    Args:
        rel_or_abs: 相对或绝对路径字符串
        date: YYYY-MM-DD 日期字符串；None 时用 datetime.now() 本地时间
    """
    s = rel_or_abs
    if "${date}" in s:
        if date is None:
            date = datetime.now().strftime("%Y-%m-%d")
        s = s.replace("${date}", date)
    p = Path(s)
    return p.resolve() if p.is_absolute() else (REPO_ROOT / s).resolve()
# update-end---author:pi---date:2026-08-06---for:【PATHS-CONFIG】Phase 3 路径集中加载器---
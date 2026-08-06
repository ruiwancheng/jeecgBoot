// update-begin---author:pi---date:2026-08-06---for:【PATHS-CONFIG】Phase 3 Node 端路径集中加载器---
// harness/scripts/_paths.js — Node 端路径集中加载器（Phase 3 / 建议 5）
//
// 用法：
//   const { PATHS, REPO, resolve, loadPaths } = require('./_paths');
//   const manifestPath = resolve(PATHS.harness.regression_manifest);
//
// 与 Python _paths.py 保持完全对称的 API。

const fs = require('fs');
const path = require('path');

const REPO = path.resolve(__dirname, '..', '..');
const DEFAULT_PATHS_FILE = path.join(REPO, 'harness', 'config', 'paths.json');

// 与 Python _paths.py 保持完全一致
const FALLBACK = {
  harness: {
    root: 'harness',
    regression_manifest: 'harness/regression/recovery-plan.json',
    runs_dir: 'harness/.regression-runs',
    tests_root: 'harness/tests',
    tests_modules: 'harness/tests/modules',
    tests_chains: 'harness/tests/chains',
    tests_concurrent: 'harness/tests/concurrent',
    e2e_root: 'harness/e2e',
    e2e_mes: 'harness/e2e/mes',
    playwright_config: 'harness/playwright.config.ts',
    templates_dir: 'harness/templates',
    report_template: 'harness/templates/regression-report.md',
    dashboard: 'harness/dashboard',
  },
  hermes: {
    eagle_eye_root: 'hermes/eagle-eye',
    eagle_eye_reports: 'hermes/eagle-eye/reports',
    business_chains: 'hermes/business-chains.json',
    plans_dir: 'hermes/plan',
    reviews_dir: 'hermes/reviews',
  },
  external_mirror: {
    user_notes_root: '/Users/ruisuyun/Documents/笔记空间/低代码平台方案/03测试',
  },
};

function loadPaths(pathsFile) {
  const target = pathsFile || process.env.HARNESS_PATHS_FILE || DEFAULT_PATHS_FILE;
  if (fs.existsSync(target)) {
    try {
      const raw = JSON.parse(fs.readFileSync(target, 'utf8'));
      const out = {};
      for (const [k, v] of Object.entries(raw)) {
        if (!k.startsWith('_')) out[k] = v;
      }
      return out;
    } catch (e) {
      console.warn(`⚠️  paths.json 加载失败 (${e.message})，使用 fallback`);
    }
  }
  return FALLBACK;
}

const PATHS = loadPaths();

function reloadPaths() {
  // PATHS 是 const 引用；不能直接重赋值。调用方需自行处理：const newPaths = reloadPaths();
  return loadPaths();
}

function resolve(relOrAbs, date) {
  let s = relOrAbs;
  if (s && s.includes('${date}')) {
    if (!date) {
      const d = new Date();
      const yyyy = d.getFullYear();
      const mm = String(d.getMonth() + 1).padStart(2, '0');
      const dd = String(d.getDate()).padStart(2, '0');
      date = `${yyyy}-${mm}-${dd}`;
    }
    s = s.replace(/\$\{date\}/g, date);
  }
  return path.isAbsolute(s) ? path.resolve(s) : path.resolve(REPO, s);
}

module.exports = { PATHS, REPO, resolve, loadPaths, reloadPaths, FALLBACK };
// update-end---author:pi---date:2026-08-06---for:【PATHS-CONFIG】Phase 3 Node 端路径集中加载器---
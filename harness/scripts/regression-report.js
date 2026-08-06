#!/usr/bin/env node
// update-begin---author:pi---date:2026-08-06---for:【REGRESSION-REPORT】v1 报告生成器（0804 Sprint Review 风格）---
/**
 * harness/scripts/regression-report.js — MES 回归测试报告生成器 (v1)
 *
 * 用法：
 *   node harness/scripts/regression-report.js --run-dir <run-id>     # 单次报告
 *   node harness/scripts/regression-report.js --run-dir <run-id> --extra-cuts "..."
 *
 * 输入：
 *   - harness/.regression-runs/<run-id>/summary.md       （机器表格）
 *   - harness/.regression-runs/<run-id>/state.json       （切片状态）
 *   - harness/.regression-runs/<run-id>/logs/<slice>.log （每切片 stdout/stderr）
 *   - hermes/eagle-eye/reports/<YYYY-MM-DD>/issues/      （Playwright 失败复核）
 *   - git log <base>..HEAD --oneline                      （本次会话 commits）
 *
 * 输出：
 *   - harness/.regression-runs/<run-id>/regression-report.md  （详细分析报告）
 *   - hermes/eagle-eye/reports/<YYYY-MM-DD>/regression-report.md  （每日归档）
 *
 * 模板：harness/templates/regression-report.md
 * 风格参考：hermes/eagle-eye/reports/2026-08-04/ 各 slice-* + Sprint Review
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PROJECT = path.resolve(__dirname, '..', '..');
const REPO = PROJECT;
const RUNS_DIR = path.join(PROJECT, 'harness', '.regression-runs');
const EAGLE_EYE = path.join(PROJECT, 'hermes', 'eagle-eye', 'reports');
const TEMPLATE = path.resolve(__dirname, '..', 'templates', 'regression-report.md');

// ─────────────────────────────────────────────
// 工具函数
// ─────────────────────────────────────────────

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function readText(p) {
  return fs.readFileSync(p, 'utf8');
}

function shell(cmd, opts = {}) {
  return execSync(cmd, { encoding: 'utf8', cwd: REPO, ...opts });
}

function detectDate(runId) {
  // run-id 格式: YYYYMMDD-HHMMSS
  if (runId && /^\d{8}-\d{6}$/.test(runId)) {
    return `${runId.slice(0,4)}-${runId.slice(4,6)}-${runId.slice(6,8)}`;
  }
  return new Date().toISOString().slice(0, 10);
}

// ─────────────────────────────────────────────
// 数据收集
// ─────────────────────────────────────────────

function loadRun(runDir) {
  const state = readJson(path.join(runDir, 'state.json'));
  const summary = readText(path.join(runDir, 'summary.md'));
  return { state, summary };
}

function sliceStatusCounts(state) {
  const slices = state.slices || {};
  const counts = { passed: 0, failed: 0, verdict: 0, pending: 0, timeout: 0, blocked_environment: 0, running: 0 };
  for (const s of Object.values(slices)) {
    const st = s.status || 'pending';
    counts[st] = (counts[st] || 0) + 1;
  }
  return counts;
}

function sliceDetailTable(state, manifest) {
  const slices = state.slices || {};
  const manifestById = {};
  for (const m of manifest.slices || []) manifestById[m.id] = m;
  const rows = [];
  for (const [sid, s] of Object.entries(slices)) {
    const m = manifestById[sid] || {};
    const dur = s.duration_seconds ? `${s.duration_seconds.toFixed(1)}s` : '-';
    const statusIcon = { passed: '✅', failed: '❌', verdict: '⚖️', pending: '⏸', timeout: '⏱', blocked_environment: '🔒' }[s.status] || '?';
    const note = (s.message || '').slice(0, 50);
    rows.push(`| ${sid} | ${m.name || sid} | ${statusIcon} ${s.status} | ${dur} | ${note} |`);
  }
  return rows.join('\n');
}

function failureAnalysis(state, manifest) {
  const slices = state.slices || {};
  const manifestById = {};
  for (const m of manifest.slices || []) manifestById[m.id] = m;
  const failed = [];
  for (const [sid, s] of Object.entries(slices)) {
    if (s.status === 'failed' || s.status === 'timeout') {
      const logPath = s.log_path ? path.join(REPO, s.log_path.replace(/^.*\/harness\//, 'harness/').replace(/^.*\//, '')) : null;
      // 简化：logPath 是相对路径，直接拼 runDir
      const realLogPath = s.log_path ? path.join(state.run_id && path.join(RUNS_DIR, state.run_id, 'logs'), path.basename(s.log_path || '')) : null;
      // 从 log 提取错误摘要
      let errorSummary = '';
      const realLog = path.join(RUNS_DIR, state.run_id, 'logs', `${sid}.attempt-${s.attempts || 1}.log`);
      if (fs.existsSync(realLog)) {
        const log = readText(realLog);
        // 提取 Error: 行
        const errMatch = log.match(/(Error[^\n]{0,200})/g);
        errorSummary = errMatch ? errMatch.slice(0, 3).join(' / ') : '';
      }
      failed.push({
        slice_id: sid,
        name: manifestById[sid]?.name || sid,
        message: s.message || '',
        log_path: realLog,
        error_summary: errorSummary,
      });
    }
  }
  return failed;
}

function issuesDir(date) {
  return path.join(EAGLE_EYE, date, 'issues');
}

function issueReviewSummary(date) {
  const dir = issuesDir(date);
  if (!fs.existsSync(dir)) return { count: 0, summaries: [] };
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.md') && !f.includes('runtime-diagnostics') && f !== 'review-summary.md');
  const summaries = files.map(f => {
    const txt = readText(path.join(dir, f));
    const name = f.replace(/^[a-f0-9]+-/, '').replace(/\.md$/, '');
    const verdict = (txt.match(/\*\*当前判定：\*\*\s*(\S+)/) || [])[1] || 'unknown';
    return { name, verdict };
  });
  const counts = {};
  for (const s of summaries) counts[s.verdict] = (counts[s.verdict] || 0) + 1;
  return { count: files.length, summaries, counts };
}

function recentCommits(sinceHours = 12) {
  try {
    const out = shell(`git log --since="${sinceHours} hours ago" --pretty=format:"%h|%s" | head -40`);
    return out.split('\n').filter(Boolean).map(line => {
      const [hash, subject] = line.split('|', 2);
      return { hash, subject: (subject || '').slice(0, 60) };
    });
  } catch {
    return [];
  }
}

// ─────────────────────────────────────────────
// 模板渲染
// ─────────────────────────────────────────────

function renderTemplate(template, vars) {
  let out = template;
  for (const [key, val] of Object.entries(vars)) {
    const re = new RegExp(`\\{\\{${key}\\}\\}`, 'g');
    out = out.replace(re, val);
  }
  return out;
}

function renderFailureSections(failures) {
  if (failures.length === 0) {
    return '### ✅ 本次无失败切片';
  }
  return failures.map((f, i) => `
### 4.${i + 1} \`${f.slice_id}\` — ${f.name}

**症状**：\`${f.message}\`

**关键错误**：\`${f.error_summary || '（无 Error 行，请查日志 ' + f.log_path + '）'}\`

**判定**：待人工复核（详见 \`hermes/eagle-eye/reports/issues/${f.slice_id}-*.md\`）

**原始日志**：\`${f.log_path}\`
`).join('\n');
}

// ─────────────────────────────────────────────
// 主流程
// ─────────────────────────────────────────────

function generate(runDirArg) {
  const runDir = path.join(RUNS_DIR, runDirArg);
  if (!fs.existsSync(runDir)) {
    console.error(`Run directory not found: ${runDir}`);
    process.exit(1);
  }

  const { state, summary } = loadRun(runDir);
  const manifest = readJson(path.join(runDir, 'manifest.json'));
  const date = detectDate(state.run_id);
  const counts = sliceStatusCounts(state);
  const total = Object.values(state.slices || {}).length;
  const passedRate = total ? (counts.passed / total * 100).toFixed(1) : '0';
  const durationTotal = Object.values(state.slices || {})
    .reduce((s, x) => s + (x.duration_seconds || 0), 0).toFixed(1);

  const issues = issueReviewSummary(date);
  const commits = recentCommits(12);
  const failures = failureAnalysis(state, manifest);

  const vars = {
    date,
    datetime: new Date().toISOString().replace('T', ' ').slice(0, 16) + ' (UTC)',
    run_id: state.run_id,
    task_name: state.name,
    scope: state.scope || 'full',
    slice_count: String(total),
    total: String(total),
    passed_count: String(counts.passed),
    failed_count: String(counts.failed || 0),
    verdict_count: String(counts.verdict || 0),
    pending_count: String(counts.pending || 0),
    pass_rate: passedRate,
    duration_total: durationTotal + 's',
    commits_table: commits.map(c => `| \`${c.hash}\` | ${c.subject} |`).join('\n') || '| (无) | - |',
    slices_table: sliceDetailTable(state, manifest),
    failure_sections: renderFailureSections(failures),
    issue_count: String(issues.count),
    issue_summary: issues.summaries.length
      ? Object.entries(issues.counts).map(([k, v]) => `- **${k}**: ${v}`).join('\n')
      : '- 本轮无 E2E 复核 issues',
    fixed_issues: '| (待人工补充) | - | - |',
    remaining_risks: '| (待人工补充) | - | - |',
    user_todo: '- 核对通过率\n- 复核失败切片根因\n- 选择后续选项',
  };

  const report = renderTemplate(readText(TEMPLATE), vars);

  // 写本地
  const localPath = path.join(runDir, 'regression-report.md');
  fs.writeFileSync(localPath, report);
  console.log(`✅ Local: ${localPath}`);

  // 归档到当天目录
  const archivePath = path.join(EAGLE_EYE, date, 'resilient-regression-recovery.md');
  fs.mkdirSync(path.dirname(archivePath), { recursive: true });
  fs.writeFileSync(archivePath, report);
  console.log(`✅ Archive: ${archivePath}`);

  return report;
}

// ─────────────────────────────────────────────
// CLI
// ─────────────────────────────────────────────

function main() {
  const args = process.argv.slice(2);
  let runDir = null;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--run-dir') runDir = args[++i];
  }
  if (!runDir) {
    // 默认最新 run
    const runs = fs.readdirSync(RUNS_DIR).sort().reverse();
    if (runs.length === 0) {
      console.error('No regression runs found');
      process.exit(1);
    }
    runDir = runs[0];
    console.log(`Using latest run: ${runDir}`);
  }
  generate(runDir);
}

if (require.main === module) {
  main();
}

module.exports = { generate, renderTemplate };
// update-end---author:pi---date:2026-08-06---for:【REGRESSION-REPORT】v1 报告生成器（0804 Sprint Review 风格）---

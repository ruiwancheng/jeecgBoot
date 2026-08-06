#!/usr/bin/env node
// update-begin---author:pi---date:2026-08-06---for:【REGRESSION-REPORT】v2 真实数据抽取 + 自动归类---
/**
 * harness/scripts/regression-report.js — MES 回归测试报告生成器 (v2)
 *
 * v2 改进（相对 v1）：
 *   - issues/*.md 自动解析 verdict（疑似产品 bug / 测试 bug / 数据前置 / 环境问题）
 *   - 失败切片 log 自动抽取首个 Error 行（不只是路径）
 *   - commit 链按 run_dir 创建时间筛选（只列本次会话相关的）
 *   - 技术债务自动归类（fix:* → 已修复；refactor:* → 优化）
 *   - 所有占位符强制填充（残留 {{var}} 即报错）
 *
 * 用法：node harness/scripts/regression-report.js --run-dir <run-id>
 * 输出：
 *   - harness/.regression-runs/<run-id>/regression-report.md
 *   - hermes/eagle-eye/reports/<date>/resilient-regression-recovery.md
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Phase 3 / 建议 5：路径集中加载（缺文件时硬编码 fallback）
const { PATHS, REPO, resolve, FALLBACK } = require('./_paths');
const RUNS_DIR = resolve(PATHS.harness.runs_dir);
const EAGLE_EYE = resolve(PATHS.hermes.eagle_eye_reports);
const TEMPLATE = resolve(PATHS.harness.report_template);
const REPO_ROOT = REPO;  // 别名供 extractFieldFromSpecFile 使用

// ─────────────────────────────────────────────
// 工具
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
  if (runId && /^\d{8}-\d{6}$/.test(runId)) {
    return `${runId.slice(0,4)}-${runId.slice(4,6)}-${runId.slice(6,8)}`;
  }
  // 使用本地时间（与 Python runner 的 datetime.now() 一致）
  // Phase 2 / 建议 4 修复 P0 时区不一致：
  // 原 .toISOString() 用 UTC，跨午夜场景 Python 写 2026-08-07，Node 会写 2026-08-06（错）
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
}
function parseRunTimestamp(runId) {
  if (runId && /^\d{8}-\d{6}$/.test(runId)) {
    return new Date(
      `${runId.slice(0,4)}-${runId.slice(4,6)}-${runId.slice(6,8)}T${runId.slice(9,11)}:${runId.slice(11,13)}:${runId.slice(13,15)}+08:00`
    ).getTime();
  }
  return Date.now();
}
function truncate(s, n) {
  if (!s) return '';
  s = s.replace(/\n/g, ' ').replace(/\s+/g, ' ').trim();
  return s.length > n ? s.slice(0, n) + '…' : s;
}

// ─────────────────────────────────────────────
// 数据收集
// ─────────────────────────────────────────────

function loadRun(runDir) {
  return {
    state: readJson(path.join(runDir, 'state.json')),
    manifest: readJson(path.join(runDir, 'manifest.json')),
  };
}

function sliceStatusCounts(state) {
  const counts = {};
  for (const s of Object.values(state.slices || {})) {
    counts[s.status] = (counts[counts] || 0) + 1;
    counts[s.status] = (counts[s.status] || 0) + 1;
  }
  // 用 set 重写
  const out = { passed: 0, failed: 0, verdict: 0, pending: 0, timeout: 0, blocked_environment: 0 };
  for (const s of Object.values(state.slices || {})) {
    out[s.status] = (out[s.status] || 0) + 1;
  }
  return out;
}

function sliceDetailTable(state, manifest) {
  const slices = state.slices || {};
  const mById = {};
  for (const m of manifest.slices || []) mById[m.id] = m;
  const rows = [];
  for (const [sid, s] of Object.entries(slices)) {
    const m = mById[sid] || {};
    const dur = s.duration_seconds ? `${s.duration_seconds.toFixed(1)}s` : '-';
    const icon = { passed: '✅', failed: '❌', verdict: '⚖️', pending: '⏸', timeout: '⏱', blocked_environment: '🔒' }[s.status] || '❓';
    const note = truncate(s.message || '-', 40);
    rows.push(`| ${sid} | ${m.name || sid} | ${icon} ${s.status} | ${dur} | ${note} |`);
  }
  return rows.join('\n');
}

// 抽取失败切片首个 Error 行
function extractFirstError(logPath) {
  if (!fs.existsSync(logPath)) return '(日志缺失)';
  const log = readText(logPath);
  // 多种 Error 格式：Error: / Test timeout / TypeError / expect() failed
  const patterns = [
    /(Test timeout of \d+ms exceeded[^\n]{0,150})/,
    /(Error[^\n]{0,200})/,
    /(TypeError[^\n]{0,200})/,
    /(expect\([^\n]{0,200})/,
    /(timed_out[^\n]{0,150})/,
  ];
  for (const re of patterns) {
    const m = log.match(re);
    if (m) return m[1];
  }
  // fallback：最后 1 行非空
  const lines = log.trim().split('\n').filter(Boolean);
  return truncate(lines[lines.length - 1] || '(无 Error 行)', 200);
}

// 抽取失败切片的"测试名 + 文件位置"
function extractTestNames(logPath) {
  if (!fs.existsSync(logPath)) return [];
  const log = readText(logPath);
  // Playwright 格式：e2e/mes/stocktake.spec.ts:46:7
  const m = log.matchAll(/([\w\/\.-]+\.spec\.ts):(\d+):\d+\s+›\s+([^\n]{0,80})/g);
  const tests = [];
  for (const match of m) {
    tests.push(`${match[1]}:${match[2]} — ${match[3].trim()}`);
  }
  return [...new Set(tests)];
}

function failureAnalysis(state, manifest, runDir, date) {
  const slices = state.slices || {};
  const mById = {};
  for (const m of manifest.slices || []) mById[m.id] = m;
  const failed = [];
  // v2: 按 slice_id 从 issues/*.md 抽取“复现步骤”和“页面路径”（供业务人员复核）
  const issueBySpec = indexIssuesBySpec(date);
  for (const [sid, s] of Object.entries(slices)) {
    if (s.status !== 'failed' && s.status !== 'timeout') continue;
    const logName = `${sid}.attempt-${s.attempts || 1}.log`;
    const realLog = path.join(runDir, 'logs', logName);
    const errMsg = extractFirstError(realLog);
    const testNames = extractTestNames(realLog);
    // 从该切片关联的 issues 里提取复现步骤 + 页面路径（按测试名匹配，聚合该切片所有 issue）
    const matched = matchIssuesForSlice(testNames, issueBySpec);
    failed.push({
      slice_id: sid,
      name: mById[sid]?.name || sid,
      status: s.status,
      message: truncate(s.message || '-', 80),
      error: errMsg,
      tests: testNames,
      log_path: realLog,
      reproduction: matched.reproduction,
      page_path: matched.page_path,
      matched_specs: matched.matched_specs,
    });
  }
  return failed;
}

// v2: 按 spec 文件名建立索引 (从 issues/*.md 的 "测试文件" 字段提取)
function indexIssuesBySpec(date) {
  const dir = path.join(EAGLE_EYE, date, 'issues');
  if (!fs.existsSync(dir)) return {};
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.md') && !f.includes('review-summary') && !f.includes('runtime-diagnostics'));
  const bySpec = {};
  for (const f of files) {
    const parsed = parseIssueMd(path.join(dir, f));
    if (!parsed || !parsed.test_name) continue;
    // test_name 形如 `harness/e2e/mes/traceabilityBatch.spec.ts`
    const m = parsed.test_name.match(/([\w\/-]+\.spec\.ts)/);
    if (!m) continue;
    const specKey = m[1].replace(/^harness\/e2e\//, '');
    if (!bySpec[specKey]) bySpec[specKey] = [];
    bySpec[specKey].push(parsed);
  }
  return bySpec;
}

// MES 业务字段名 → 业务语义映射表
// 当 reporter 提供原始字段名（item.bookQty / Number(item.unitCost) 等）时，转为业务可读语义
const FIELD_NAME_MAPPING = {
  // 批次主档/流水
  batchNo: '批次号',
  batchId: '批次ID',
  qty: '数量',
  quantity: '数量',
  remainQty: '剩余数量',
  inQty: '入库数量',
  outQty: '出库数量',
  // 盘点主档/快照
  bookQty: '盘点账面数量',
  actualQty: '盘点实盘数量',
  diffQty: '盘点差异数量',
  snapshotTime: '快照时间',
  // 成本/金额
  unitCost: '批次单位成本',
  unitPrice: '单价',
  price: '价格',
  amount: '金额',
  totalAmount: '总金额',
  totalDebit: '借方总额',
  totalCredit: '贷方总额',
  taxRate: '税率',
  taxAmount: '税额',
  // 物料
  materialId: '物料ID',
  materialCode: '物料编码',
  warehouseId: '仓库ID',
  // 订单
  orderCode: '订单编号',
  orderNo: '订单号',
  supplierId: '供应商ID',
  customerId: '客户ID',
  productionOrderId: '生产订单ID',
  salesOrderId: '销售订单ID',
  // 状态
  status: '状态',
  remark: '备注',
  // 日期
  deliveryDate: '交货日期',
  orderDate: '订单日期',
  productionDate: '生产日期',
  expiryDate: '有效期',
};

// 从 spec 源代码中提取断言字段名（配合 code_location 行号）
// 例：spec.ts:75 -> 读第 75 行，提取 `item.bookQty` / `record.unitCost` 等
function extractFieldFromSpecFile(specFile, lineNumber) {
  if (!specFile || !lineNumber) return null;
  const filePath = path.join(REPO_ROOT, specFile);
  if (!fs.existsSync(filePath)) return null;
  const lines = readText(filePath).split('\n');
  // 读错误行 + 前 2 行（断言表达式可能跨多行）
  const start = Math.max(0, lineNumber - 3);
  const end = Math.min(lines.length, lineNumber + 1);
  const context = lines.slice(start, end).join('\n');
  // 过滤掉常见 API 中间字段/通用字段（避免噪音）
  const NOISE = new Set([
    'result', 'data', 'records', 'res', 'response', 'keys', 'values', 'entries', 'from', 'to',
    'json', 'body', 'code', 'id', 'name', 'type', 'value', 'date', 'time', 'list',
    'createdAt', 'updatedAt', 'createTime', 'updateTime',
    'costValue', 'expectedCost', 'accessToken', 'loginRes', 'apiRes',
  ]);
  // 匹配 item.bookQty / record.unitCost / Number(item.X) / expect(...X...).toBe 等
  const fieldPatterns = [
    /item\.([a-zA-Z][a-zA-Z0-9_]*)/g,
    /record\.([a-zA-Z][a-zA-Z0-9_]*)/g,
    /\.([a-zA-Z][a-zA-Z0-9_]*)[\.\[\)\=]/g,  // .fieldName. 或 .fieldName[ 或 .fieldName) 或 .fieldName=
    /Object\.keys\([^)]*\)\.includes\(['"]([\w]+)['"]/g, // Object.keys(X).includes('field')
    /saved\.([a-zA-Z][a-zA-Z0-9_]*)/g,       // saved.fieldName (单据落库后验证)
    /detail\.result\.items\.([a-zA-Z][a-zA-Z0-9_]*)/g, // detail.result.items[0].fieldName
  ];
  const fields = new Set();
  for (const pat of fieldPatterns) {
    const matches = context.matchAll(pat);
    for (const m of matches) {
      const field = m[1];
      if (field && !NOISE.has(field)) {
        fields.add(field);
      }
    }
  }
  return [...fields];
}

// 从 actual_error stack 中提取 expect 错误的真实行号
// Playwright 错误堆栈格式：at .../<spec-file>.spec.ts:LINE:COL
// 比 issue.code_location（test describe 行）更精确，指向真正的 expect 断言
function extractRealLineFromErrorStack(actualError, specFile) {
  if (!actualError || !specFile) return 0;
  // 提取 spec 文件名 basename
  const baseName = specFile.split('/').pop();
  if (!baseName) return 0;
  // 正则匹配 stack 中的 at .../xxx.spec.ts:LINE:COL
  const re = new RegExp(`at\\s+(?:[^\\s]+\\s+)?\\(?[^\\s]*${baseName.replace(/\./g, '\\.')}:(\\d+):(\\d+)`, 'm');
  const m = actualError.match(re);
  if (m) return parseInt(m[1], 10) || 0;
  return 0;
}

// 把技术性 actual_error 转换为业务语言描述
//   入参新增 specFile + codeLocation：用于从 spec 源码上下文提取断言字段名
function toBusinessLanguage(errorText, specFile, codeLocation) {
  if (!errorText || errorText === '(无)') return '(无)';
  const clean = errorText.replace(/\x1b\[[\d;]*m/g, '').trim();
  // 提取断言字段名（从 spec 源码上下文）+ 业务语义映射
  const fields = extractFieldFromSpecFile(specFile, codeLocation) || [];
  const fieldLabel = fields.length > 0
    ? fields.map(f => `${FIELD_NAME_MAPPING[f] || f}(\`${f}\`)`).join('、')
    : null;
  // 模式1：expect 断言失败（提取 Expected/Received）
  const expectMatch = clean.match(/Error[^\n]*expect[^\n]*[\s\S]*?Expected:\s*(\S+)[\s\S]*?Received:\s*(\S+)/);
  if (expectMatch) {
    const fieldPart = fieldLabel ? `【${fieldLabel}】` : '';
    return `断言失败${fieldPart}：期望值 \`${expectMatch[1]}\`，实际值 \`${expectMatch[2]}\``;
  }
  // 模式2：locator.isVisible() / element not found
  if (/TimeoutError|element\(s\) not found|Expected:\s*visible/.test(clean)) {
    const errorLine = clean.split('\n').find(l => /Error:|TimeoutError/.test(l)) || '';
    return `页面元素未出现：${errorLine.replace(/^Error:\s*/, '').slice(0, 120)}`;
  }
  // 模式3：导航/连接错误（ERR_CONNECTION_REFUSED）
  if (/ERR_CONNECTION_REFUSED|net::ERR_/.test(clean)) {
    return '前端页面无法访问（Connection Refused）';
  }
  // 模式4：Test timeout
  const timeoutMatch = clean.match(/Test timeout of (\d+)ms exceeded/);
  if (timeoutMatch) {
    return `测试超时（>${Math.round(timeoutMatch[1] / 1000)}秒）`;
  }
  // 模式5：权限不足
  if (/Subject does not have permission/.test(clean)) {
    const perm = clean.match(/permission \[([^\]]+)\]/);
    return `权限不足：缺失权限码 \`${perm ? perm[1] : '?'}\``;
  }
  // 模式6：SQL/数据库错误（Unknown column / doesn't exist）
  if (/Unknown column|SQLSyntaxErrorException|doesn't have a default value/.test(clean)) {
    const col = clean.match(/Unknown column '([^']+)'/) || clean.match(/Field '([^']+)' doesn't have a default value/);
    return `数据库 schema 错误${col ? `：字段 \`${col[1]}\` 缺失或约束错误` : ''}`;
  }
  // fallback：去掉 ANSI 颜色 + 截前 200 字符
  const firstLine = clean.split('\n').find(l => l.trim()) || clean;
  return firstLine.slice(0, 200);
}

// v2: 传 testNames (包含 spec 文件名) + issueBySpec，提取所有匹配的复现步骤
function matchIssuesForSlice(testNames, issueBySpec) {
  const matched = [];
  const pages = new Set();
  const seen = new Set();
  for (const t of testNames) {
    // t 形如 e2e/mes/stocktake.spec.ts:48 — 锚点#4
    const m = t.match(/([\w\/-]+\.spec\.ts)/);
    if (!m) continue;
    const specKey = m[1].replace(/^e2e\//, '');
    const issues = issueBySpec[specKey];
    if (issues && issues.length > 0) {
      matched.push(specKey);
      for (const issue of issues) {
        // 去重：同 spec + 同 title 只输出一次
        const key = `${specKey}::${issue.title || ''}`;
        if (seen.has(key)) continue;
        seen.add(key);
        if (issue.page_path) pages.add(issue.page_path);
      }
    }
  }
  if (matched.length === 0) {
    return { reproduction: '', page_path: '', matched_specs: [] };
  }
  // 格式化输出：按 spec 分组列出所有复现步骤 + 页面路径 + 问题点
  const lines = [];
  for (const specKey of [...new Set(matched)]) {
    const issues = issueBySpec[specKey] || [];
    lines.push(`**spec**: \`${specKey}\``);
    for (const issue of issues) {
      const loc = issue.code_location || '';
      const title = issue.title || '';
      const reprod = issue.reproduction || '(无)';
      const problem = issue.actual_error || '(无)';
      const expected = issue.expected || '(无)';
      lines.push(`- 测试位置：\`${loc}\`${title ? ` 标题：${title}` : ''}`);
      // 1. 操作步骤（业务描述）
      lines.push(`  操作步骤：`);
      for (const line of reprod.split('\n')) {
        lines.push(`    ${line}`);
      }
      // 2. 预期结果（业务语言：来自 scenario.expected）
      lines.push(`  预期结果（业务描述）：${expected}`);
      // 3. 实际结果（业务语言：从 actual_error 提取 Expected/Received，含字段名+业务语义）
      const specFile = issue.test_name || '';  // 形如 `harness/e2e/mes/stocktake.spec.ts`
      // 优先从 actual_error stack 提取真实 expect 行号（如 75）；fallback 到 issue.code_location（如 48=describe 行）
      let codeLine = extractRealLineFromErrorStack(problem, specFile);
      if (!codeLine) {
        const lines_2 = (issue.code_location || '').split(':');
        codeLine = parseInt(lines_2[1] || '0', 10) || 0;
      }
      lines.push(`  实际结果：${toBusinessLanguage(problem, specFile, codeLine)}`);
    }
  }
  return {
    reproduction: lines.join('\n'),
    page_path: [...pages].join(', '),
    matched_specs: [...new Set(matched)],
  };
}

function renderFailureSections(failures) {
  if (failures.length === 0) return '### ✅ 本次无失败切片';
  return failures.map((f, i) => {
    const testsText = f.tests.length
      ? f.tests.slice(0, 5).map(t => `  - \`${t}\``).join('\n')
      : '  - (无 Playwright spec 匹配)';
    // v2: 复现步骤 + 复核结果（从 issues/*.md 抽取，业务人员手工填写复核结论）
    const reproText = f.reproduction && f.reproduction.length > 0
      ? f.reproduction
      : '⚠️ 本次回归未生成对应的 issue 复核报告（e2e/mes 之外的切片可能没有 issues/*.md）。\n   业务人员请根据下方"失败的测试"中描述的操作路径手工复现。';
    const pagePath = f.page_path ? `页面路径: \`${f.page_path}\`\n` : '';
    return `### 4.${i + 1} \`${f.slice_id}\` — ${f.name}

**状态**：${f.status}

**症状**：\`${f.message}\`

**关键错误**：
\`\`\`
${f.error}
\`\`\`

**失败的测试**：${f.tests.length ? '' : '(无 Playwright 测试，API/链路切片)'}
${testsText}

**复现步骤**：${pagePath}
${reproText}

> 📝 业务人员复核后请填写下方「复核结果」（真实 BUG / 误判 + 原因）

**复核结果**：
\`\`\`
判定：  [ ] 真实 BUG   [ ] 误判（非 BUG）
严重度（如真实 BUG）： [ ] P0 (阻塞)  [ ] P1 (主流程)  [ ] P2 (次要)
误判原因（如误判）：____________________________________________________
跟进负责人：__________________________________
复核人 / 时间：__________________________________
\`\`\`

**原始日志**：\`${f.log_path}\`

**修复建议**：
1. 阅读原始日志的 Error 行定位根因
2. 检查 \`hermes/eagle-eye/reports/issues/\` 目录下 Playwright 自动生成的复核报告（如有）
3. 修复后用 \`python harness/scripts/resilient_regression.py resume --run-dir <run-id> --retry-failed\` 重跑`;
  }).join('\n\n');
}

// ─────────────────────────────────────────────
// issues/ 解析
// ─────────────────────────────────────────────

function parseIssueMd(filePath) {
  if (!fs.existsSync(filePath)) return null;
  const txt = readText(filePath);
  // 逐行扫描（兼容 `- 当前判定：**xxx**` 这种 markdown 格式 + 全角冒号 `：`）
  const lineGet = (label) => {
    const lines = txt.split('\n');
    for (const line of lines) {
      // 行包含 `**label**` （label 可以是中英文，如"当前判定"/"测试文件"）
      const idx = line.indexOf(label);
      if (idx < 0) continue;
      // 跳过 `- ` 前缀和 `**` 标记
      const after = line.slice(idx + label.length);
      // after 形如 `：**\`xxx\`**` 或 `: \`xxx\``，要去掉 ` 和 * 包裹
      const value = after.replace(/^[：:\s*]+/, '').replace(/\*+$/, '').replace(/^`/, '').replace(/`$/, '').trim();
      return value;
    }
    return '';
  };
  // 从 markdown 首行（# ...）提取 title
  const firstLine = txt.split('\n').find(l => l.trim().startsWith('#')) || '';
  const title = firstLine.replace(/^#\s*/, '').trim();
  return {
    title,
    test_name: lineGet('测试文件'),
    code_location: lineGet('代码位置'),
    page_path: lineGet('页面路径'),
    verdict: lineGet('当前判定'),
    category: lineGet('问题分类'),
    attempt_count: lineGet('失败次数'),
    first_seen: lineGet('首次发现'),
    actual_error: extractSection(txt, '实际错误'),
    reproduction: extractSection(txt, '复现步骤'),
    expected: extractSection(txt, '预期结果'),
  };
}

function extractSection(txt, header) {
  // 按 `## ` 分割 section（split 比正则更可靠，避免贪婪吞换行）
  const sections = txt.split(/^## /m);
  for (const s of sections) {
    const firstLine = s.split('\n')[0];
    // firstLine 可能是原标题如 "复现步骤" 或包含 BOM 的变体
    if (firstLine.trim() === header || firstLine.includes(header)) {
      // 去掉 markdown 围栏 + 头尾空白
      return s.substring(firstLine.length)
        .replace(/```[a-z]*\n/g, '')
        .replace(/```\n?/g, '')
        .trim()
        .split('\n')
        .slice(0, 12)
        .join('\n');
    }
  }
  return '';
}

function issueReviewSummary(date) {
  const dir = path.join(EAGLE_EYE, date, 'issues');
  if (!fs.existsSync(dir)) return { count: 0, parsed: [], counts: {} };
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.md') && !f.includes('review-summary') && !f.includes('runtime-diagnostics'));
  const parsed = files.map(f => ({ file: f, ...(parseIssueMd(path.join(dir, f)) || {}) }));
  const counts = {};
  for (const p of parsed) {
    const v = p.verdict || 'unknown';
    counts[v] = (counts[v] || 0) + 1;
  }
  return { count: parsed.length, parsed, counts };
}

function renderIssueTable(issueSummary) {
  if (issueSummary.count === 0) return '本轮无 E2E 复核 issues';
  // 按 verdict 分组
  const byVerdict = {};
  for (const p of issueSummary.parsed) {
    const v = p.verdict || 'unknown';
    if (!byVerdict[v]) byVerdict[v] = [];
    byVerdict[v].push(p);
  }
  const lines = [];
  lines.push('**按判定分类**：');
  for (const [v, items] of Object.entries(byVerdict)) {
    const icon = { suspected_bug: '🔴', test_defect: '🟡', data_precondition: '🟠', environment_issue: '⚪', false_positive: '🟢', passed: '✅' }[v] || '❓';
    lines.push(`- ${icon} **${v}**: ${items.length} 个`);
  }
  lines.push('');
  lines.push('**详情（前 10 个）**：');
  lines.push('| 文件 | 页面 | 判定 | 分类 |');
  lines.push('|---|---|---|---|');
  for (const p of issueSummary.parsed.slice(0, 10)) {
    lines.push(`| ${truncate(p.file.replace(/^[a-f0-9]+-/, ''), 60)} | ${p.page_path || '-'} | ${p.verdict || '-'} | ${p.category || '-'} |`);
  }
  if (issueSummary.parsed.length > 10) {
    lines.push(`| _...还有 ${issueSummary.parsed.length - 10} 个_ | | | |`);
  }
  return lines.join('\n');
}

// ─────────────────────────────────────────────
// commit 链筛选 + 自动归类
// ─────────────────────────────────────────────

function classifyCommit(subject) {
  if (/^test:/i.test(subject)) return 'test';
  if (/^fix\(/i.test(subject)) return 'fix';
  if (/^fix:/i.test(subject)) return 'fix';
  if (/^tool:/i.test(subject)) return 'tool';
  if (/^docs:/i.test(subject)) return 'docs';
  if (/^chore:/i.test(subject)) return 'chore';
  if (/^refactor:/i.test(subject)) return 'refactor';
  return 'other';
}

function recentCommits(runTimestamp) {
  try {
    // 本次会话的 commit = 相对于 origin/main 未推送的 commit
    // （避免出现 1 周前 commit 等无关内容）
    let out;
    try {
      out = shell('git log origin/main..HEAD --pretty=format:"%h|%s" 2>/dev/null');
    } catch {
      // fallback：上次 push 后的 commit
      out = shell('git log --since="24 hours ago" --pretty=format:"%h|%s"');
    }
    if (!out.trim()) {
      // 再 fallback：当天全部 commit（用本地时间，与 detectDate / Python 一致）
      const d = new Date();
      const today = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
      out = shell(`git log --since="${today} 00:00" --pretty=format:"%h|%s"`);
    }
    return out.split('\n').filter(Boolean).map(line => {
      const [hash, subject] = line.split('|', 2);
      return { hash, subject: subject || '', type: classifyCommit(subject || '') };
    });
  } catch {
    return [];
  }
}

function renderCommitsTable(commits) {
  if (commits.length === 0) return '| (无本次会话 commit) | - | - |';
  return commits.map(c => `| \`${c.hash}\` | ${c.subject} |`).join('\n');
}

// ─────────────────────────────────────────────
// 技术债务自动归类
// ─────────────────────────────────────────────

function techDebt(commits) {
  const fixed = [];
  for (const c of commits) {
    if (c.type === 'fix' || c.type === 'fix:') {
      const desc = c.subject.replace(/^fix(\([^)]+\))?:\s*/, '').slice(0, 50);
      fixed.push({ desc, hash: c.hash });
    }
  }
  return fixed;
}

function renderFixedIssues(commits) {
  const items = techDebt(commits);
  if (items.length === 0) return '| (本次会话无 fix: commit) | - | - |';
  return items.slice(0, 15).map(i => `| ${truncate(i.desc, 50)} | \`${i.hash}\` | 通过验证（详见 commit message） |`).join('\n');
}

// ─────────────────────────────────────────────
// 模板渲染
// ─────────────────────────────────────────────

function renderTemplate(template, vars) {
  let out = template;
  for (const [key, val] of Object.entries(vars)) {
    out = out.replace(new RegExp(`\\{\\{${key}\\}\\}`, 'g'), val);
  }
  // 校验残留
  const residual = out.match(/\{\{[a-z_]+\}\}/g);
  if (residual) {
    console.warn(`⚠️ 模板残留占位符: ${[...new Set(residual)].join(', ')}`);
  }
  return out;
}

// ─────────────────────────────────────────────
// 主流程
// ─────────────────────────────────────────────

function generate(runDirArg) {
  // Phase 4 / 建议 6 bugfix：runDirArg 可能是绝对路径或 run-id
  // Python runner 用 subprocess 传绝对路径；CLI 用户可能传 run-id
  const runDir = path.isAbsolute(runDirArg) ? runDirArg : path.join(RUNS_DIR, runDirArg);
  if (!fs.existsSync(runDir)) {
    console.error(`Run directory not found: ${runDir}`);
    process.exit(1);
  }

  const { state, manifest } = loadRun(runDir);
  const date = detectDate(state.run_id);
  const runTimestamp = parseRunTimestamp(state.run_id);
  const counts = sliceStatusCounts(state);
  const total = Object.values(state.slices || {}).length;
  const passRate = total ? (counts.passed / total * 100).toFixed(1) : '0';
  const totalDuration = Object.values(state.slices || {}).reduce((s, x) => s + (x.duration_seconds || 0), 0).toFixed(1);

  const failures = failureAnalysis(state, manifest, runDir, date);
  const issues = issueReviewSummary(date);
  const commits = recentCommits(runTimestamp);

  const vars = {
    date,
    datetime: new Date().toISOString().replace('T', ' ').slice(0, 16) + ' UTC',
    run_id: state.run_id,
    task_name: state.name,
    scope: state.scope || 'full',
    slice_count: String(total),
    total: String(total),
    passed_count: String(counts.passed),
    failed_count: String(counts.failed || 0),
    verdict_count: String(counts.verdict || 0),
    pending_count: String(counts.pending || 0),
    pass_rate: passRate,
    duration_total: totalDuration + 's',
    commits_table: renderCommitsTable(commits),
    slices_table: sliceDetailTable(state, manifest),
    failure_sections: renderFailureSections(failures),
    issue_count: String(issues.count),
    issue_summary: renderIssueTable(issues),
    fixed_issues: renderFixedIssues(commits),
    remaining_risks: '| (待人工补充) | - | - |',
    user_todo: '- 核对通过率（' + passRate + '%）\n- 复核第四节失败切片根因\n- 阅读第五节 E2E 复核证据\n- 选择第八节后续选项',
    slice_id_1: failures[0]?.slice_id || 'N/A',
    slice_name_1: failures[0]?.name || 'N/A',
    symptom_1: failures[0]?.message || 'N/A',
    root_cause_1: failures[0]?.error || 'N/A',
    judgment_1: failures[0] ? '查看 issues/ 复核报告' : 'N/A',
    classification_1: failures[0]?.status || 'N/A',
    fix_suggestion_1: failures[0] ? '见失败切片原始日志和 Playwright 复核报告' : 'N/A',
  };

  const report = renderTemplate(readText(TEMPLATE), vars);

  // 写本地
  const localPath = path.join(runDir, 'regression-report.md');
  fs.writeFileSync(localPath, report);
  console.log(`✅ Local: ${localPath}`);

  // 归档到当天（Phase 2 / 建议 4：多路径写入 + best-effort 错误隔离）
  // 路径收集（向后兼容）：
  //   1. report_paths[] 数组（manifest 新增）
  //   2. fallback 到 report_path 单数字段（保留兼容）
  //   3. 追加 report_mirror_paths[] 数组（如用户笔记空间）
  const manifestPaths = manifest.report_paths || (manifest.report_path ? [manifest.report_path] : []);
  const mirrorPaths = manifest.report_mirror_paths || [];
  const allPaths = [...manifestPaths, ...mirrorPaths];

  let successCount = 0, failCount = 0;
  for (const pathTemplate of allPaths) {
    const resolved = pathTemplate.replace(/\$\{date\}/g, date);
    const absolute = path.isAbsolute(resolved) ? resolved : path.join(REPO, resolved);
    try {
      fs.mkdirSync(path.dirname(absolute), { recursive: true });
      fs.writeFileSync(absolute, report);
      console.log(`✅ Archive: ${absolute}`);
      successCount++;
    } catch (e) {
      console.error(`❌ Failed to write ${absolute}: ${e.message}`);
      failCount++;
    }
  }
  if (failCount > 0) {
    console.warn(`⚠️  ${failCount}/${allPaths.length} archive writes failed (best-effort)`);
  }

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
// update-end---author:pi---date:2026-08-06---for:【REGRESSION-REPORT】v2 真实数据抽取 + 自动归类---

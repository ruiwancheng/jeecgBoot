#!/usr/bin/env node
// update-begin---author:pi---date:2026-08-06---for:【TEST-COVERAGE】v4 扫描器：识别 PREFIX scope + 模板字符串，正确判定测试覆盖---
/**
 * harness/scripts/coverage.js — MES 测试覆盖率扫描器 (v4)
 *
 * 用法：
 *   node harness/scripts/coverage.js                # 总览
 *   node harness/scripts/coverage.js gap            # 缺口清单
 *   node harness/scripts/coverage.js <项目>         # 单项目详情（目前只支持 mes）
 *   node harness/scripts/coverage.js <项目> <模块>  # 单模块详情（如 mes finance）
 *
 * v4 关键改进：
 *   - 识别 const|let|var NAME = '/path' 声明，按 scope（"声明-下次同名声明前"）
 *     替换 `${NAME}` 和模板字符串内的裸 NAME，避免 v3 全局替换破坏函数内 const
 *   - 自动识别 @RequestMapping 前缀 + 所有 @(Get|Post|Put|Delete)Mapping 端点
 *   - 按 controller 输出未覆盖端点明细，便于 /add-tests 精确补缺
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Phase 3 / 建议 5：路径集中加载
const { REPO, PATHS, resolve } = require('./_paths');
const PROJECT = REPO;
const CTRL_DIRS = {
  mes: path.join(PROJECT, 'jeecg-boot/jeecg-boot-module/project-mes')
};
const TEST_DIRS = [
  resolve(PATHS.harness.tests_modules),
  resolve(PATHS.harness.e2e_mes),
];

// ─────────────────────────────────────────────────────────────
// 源码扫描
// ─────────────────────────────────────────────────────────────

/**
 * 提取 controller 的所有端点。
 * @param {string} ctrlFile controller 绝对路径
 * @returns {{base: string, endpoints: Array<{method: string, path: string, full: string}>}}
 */
function extractEndpoints(ctrlFile) {
  const content = fs.readFileSync(ctrlFile, 'utf8');
  const baseMatch = content.match(/@RequestMapping\(["']([^"']+)["']\)/);
  const base = baseMatch ? baseMatch[1] : '';
  const epRegex = /@(Get|Post|Put|Delete)Mapping\(["']([^"']+)["']/g;
  const endpoints = [];
  let m;
  while ((m = epRegex.exec(content)) !== null) {
    endpoints.push({ method: m[1], path: m[2], full: base + m[2] });
  }
  return { base, endpoints };
}

function listControllers(project) {
  const dir = CTRL_DIRS[project];
  if (!dir || !fs.existsSync(dir)) return [];
  return execSync(`find ${dir} -name "*Controller.java" -type f`, { encoding: 'utf8' })
    .trim().split('\n').filter(Boolean).sort();
}

function listTests() {
  const files = [];
  for (const d of TEST_DIRS) {
    if (!fs.existsSync(d)) continue;
    const list = execSync(`find ${d} -type f \\( -name "*.js" -o -name "*.mjs" -o -name "*.ts" \\)`, { encoding: 'utf8' });
    files.push(...list.trim().split('\n').filter(Boolean));
  }
  return files;
}

// ─────────────────────────────────────────────────────────────
// 测试内容预处理：按 scope 展开 const NAME = '...'
// ─────────────────────────────────────────────────────────────

/**
 * 正确处理 const PREFIX = '/mes/finance/payable' 这种声明——按 scope 替换同名引用，
 * 避免 v3 全局替换破坏"同一文件内多个函数各自声明同名 const"的语义。
 */
function expandConstantsByScope(src) {
  const declRegex = /\b(const|let|var)\s+([A-Z_][A-Z0-9_]*)\s*=\s*["'`]([^"'`]+)["'`]/g;
  const decls = [];
  let m;
  while ((m = declRegex.exec(src)) !== null) {
    decls.push({ idx: m.index, len: m[0].length, name: m[2], value: m[3] });
  }
  if (decls.length === 0) return src;

  let out = src.split('');
  // 从后往前处理，避免位置偏移
  for (let i = decls.length - 1; i >= 0; i--) {
    const d = decls[i];
    // 找该声明之后到下一个同名声明之前的区间
    let endPos = out.length;
    for (let j = i + 1; j < decls.length; j++) {
      if (decls[j].name === d.name) { endPos = decls[j].idx; break; }
    }
    const before = out.slice(0, d.idx + d.len).join('');
    const middle = out.slice(d.idx + d.len, endPos).join('');
    const after = out.slice(endPos).join('');
    // 替换 ${NAME} → value
    let mid = middle.replace(new RegExp('\\$\\{' + d.name + '\\}', 'g'), d.value);
    // 替换模板字符串内裸 NAME：`...NAME...` → `...value...`
    mid = mid.replace(/`([^`]*?)`/g, (_, inner) =>
      '`' + inner.replace(new RegExp('\\b' + d.name + '\\b', 'g'), d.value) + '`');
    out = (before + mid + after).split('');
  }
  return out.join('');
}

const testCache = new Map();
function getExpandedTest(f) {
  if (!testCache.has(f)) {
    try {
      testCache.set(f, expandConstantsByScope(fs.readFileSync(f, 'utf8')));
    } catch (e) {
      testCache.set(f, '');
    }
  }
  return testCache.get(f);
}

// ─────────────────────────────────────────────────────────────
// 覆盖率计算
// ─────────────────────────────────────────────────────────────

/**
 * 数 endpoint 在测试文件里被引用的次数（已展开 const）。
 */
function countCalls(endpoint, testFiles) {
  let count = 0;
  const escaped = endpoint.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  for (const f of testFiles) {
    const c = getExpandedTest(f);
    if (!c) continue;
    const re = new RegExp(escaped, 'g');
    const matches = c.match(re);
    if (matches) count += matches.length;
  }
  return count;
}

/**
 * 找 controller 对应的"直接测试文件"（按文件名粗匹配）。
 */
function findDirectTest(ctrlFile, testFiles) {
  const basename = path.basename(ctrlFile, '.java')
    .replace(/^Mes/, '').replace(/Controller$/, '');
  return testFiles.filter(f => {
    const bn = path.basename(f, path.extname(f));
    return bn.toLowerCase().includes(basename.toLowerCase());
  });
}

/**
 * 主扫描：对单个项目（如 'mes'）下所有 controller 计算覆盖。
 */
function scanProject(project) {
  const controllers = listControllers(project);
  const testFiles = listTests();
  const results = [];

  for (const ctrl of controllers) {
    const { base, endpoints } = extractEndpoints(ctrl);
    const directTest = findDirectTest(ctrl, testFiles);
    let coveredCount = 0;
    const detail = endpoints.map(ep => {
      const calls = countCalls(ep.full, testFiles);
      if (calls > 0) coveredCount++;
      return { ...ep, calls };
    });
    results.push({
      ctrl: path.relative(CTRL_DIRS[project], ctrl),
      base,
      total: endpoints.length,
      covered: coveredCount,
      hasDirectTest: directTest.length > 0,
      endpoints: detail
    });
  }
  return results;
}

// ─────────────────────────────────────────────────────────────
// 输出格式化
// ─────────────────────────────────────────────────────────────

function shortName(ctrlPath) {
  return ctrlPath
    .replace(/src\/main\/java\/org\/jeecg\/modules\/mes\//, '')
    .replace(/\/controller\//, '/');
}

function printOverview(project) {
  const results = scanProject(project);
  const totalEp = results.reduce((s, r) => s + r.total, 0);
  const coveredEp = results.reduce((s, r) => s + r.covered, 0);
  const pct = (coveredEp * 100 / totalEp).toFixed(1);

  console.log(`## 测试覆盖率（${project}，v4 扫描器）\n`);
  console.log(`Controller: ${results.length} 个 | 端点: ${totalEp} 个 | 已调用: ${coveredEp} 个`);
  console.log(`**覆盖率: ${pct}%** (${coveredEp}/${totalEp})\n`);

  console.log(`| Controller | 端点 | 已覆盖 | 直接测试 | 覆盖率 |`);
  console.log(`|---|---|---|---|---|`);
  for (const r of results) {
    const p = r.total === 0 ? '-' : (r.covered * 100 / r.total).toFixed(0) + '%';
    const dt = r.hasDirectTest ? '✅' : '❌';
    console.log(`| ${shortName(r.ctrl)} | ${r.total} | ${r.covered} | ${dt} | ${p} |`);
  }

  // 按模块汇总
  const byModule = {};
  for (const r of results) {
    const mod = shortName(r.ctrl).split('/')[0];
    if (!byModule[mod]) byModule[mod] = { total: 0, covered: 0, ctrl: 0 };
    byModule[mod].total += r.total;
    byModule[mod].covered += r.covered;
    byModule[mod].ctrl += 1;
  }
  console.log(`\n### 按模块汇总`);
  console.log(`| 模块 | Controller | 端点 | 覆盖 |`);
  console.log(`|---|---|---|---|`);
  for (const [mod, s] of Object.entries(byModule)) {
    const p = (s.covered * 100 / s.total).toFixed(0) + '%';
    console.log(`| ${mod} | ${s.ctrl} | ${s.covered}/${s.total} | ${p} |`);
  }

  const gaps = results.filter(r => r.covered === 0);
  console.log(`\n## 🔴 完全无覆盖的 Controller（${gaps.length}）`);
  if (gaps.length === 0) console.log('(无)');
  else gaps.forEach(g => console.log(`- **${shortName(g.ctrl)}** (${g.total} 端点) — \`${g.base}\``));

  const partial = results.filter(r => r.covered > 0 && r.covered < r.total * 0.8);
  console.log(`\n## 🟡 部分覆盖 (< 80%, ${partial.length})`);
  partial.forEach(g => console.log(`- **${shortName(g.ctrl)}** ${g.covered}/${g.total}`));
}

function printGap(project) {
  const results = scanProject(project);
  console.log(`## 缺口清单（${project}）\n`);
  const missing = [];
  for (const r of results) {
    for (const ep of r.endpoints) {
      if (ep.calls === 0) {
        missing.push({ ctrl: shortName(r.ctrl), method: ep.method, full: ep.full });
      }
    }
  }
  if (missing.length === 0) console.log('✅ 无缺口');
  else {
    console.log(`共 ${missing.length} 个未覆盖端点：\n`);
    console.log(`| Controller | Method | 端点 |`);
    console.log(`|---|---|---|`);
    for (const m of missing) console.log(`| ${m.ctrl} | ${m.method} | \`${m.full}\` |`);
  }
}

function printDetail(project, module) {
  const results = scanProject(project);
  const filtered = module
    ? results.filter(r => shortName(r.ctrl).startsWith(module + '/'))
    : results;
  if (filtered.length === 0) {
    console.log(`❌ 未找到 ${project}/${module} 模块`);
    process.exit(1);
  }
  console.log(`## ${project}/${module} 详情\n`);
  for (const r of filtered) {
    console.log(`### ${shortName(r.ctrl)}（${r.covered}/${r.total}）`);
    for (const ep of r.endpoints) {
      const mark = ep.calls > 0 ? '✅' : '❌';
      console.log(`  ${mark} ${ep.method} \`${ep.full}\` (${ep.calls} calls)`);
    }
    console.log();
  }
}

// ─────────────────────────────────────────────────────────────
// CLI 入口
// ─────────────────────────────────────────────────────────────

function main() {
  const args = process.argv.slice(2);
  const project = 'mes'; // 目前只支持 mes
  if (args[0] === 'gap') {
    printGap(project);
  } else if (args.length === 1 && args[0] !== 'gap') {
    if (args[0] === 'mes' || CTRL_DIRS[args[0]]) {
      printOverview(args[0]);
    } else {
      // 单模块
      printDetail(project, args[0]);
    }
  } else if (args.length === 2) {
    printDetail(args[0], args[1]);
  } else {
    printOverview(project);
  }
}

if (require.main === module) {
  main();
}

module.exports = { scanProject, expandConstantsByScope, extractEndpoints, countCalls };
// update-end---author:pi---date:2026-08-06---for:【TEST-COVERAGE】v4 扫描器：识别 PREFIX scope + 模板字符串，正确判定测试覆盖---

// update-begin---author:pi---date:2026-08-04---for:【REGRESSION-EVIDENCE-REVIEW】失败自动复核与问题证据报告---
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import type { FullConfig, FullResult, Reporter, Suite, TestCase, TestResult } from '@playwright/test/reporter';

type Scenario = {
  file: string;
  titleContains: string;
  route: string;
  preconditions?: string[];
  steps: string[];
  expected: string;
  category: string;
  data?: Record<string, string>;
};

type MetadataFile = {
  defaults?: {
    preconditions?: string[];
    expected?: string;
  };
  scenarios: Scenario[];
};

type Candidate = {
  id: string;
  file: string;
  title: string;
  location: { line: number; column: number };
  route: string;
  preconditions: string[];
  steps: string[];
  expected: string;
  category: string;
  data?: Record<string, string>;
  failures: number;
  verdict: string;
  firstFailureAt: string;
  lastAttemptAt: string;
  lastStatus: string;
  lastError: string;
  evidence: Array<{ name: string; path?: string; contentType: string; body?: string }>;
};

function localDate(): string {
  const now = new Date();
  const pad = (value: number) => String(value).padStart(2, '0');
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
}

function normalize(value: string): string {
  return value.replace(/\\/g, '/');
}

function slug(value: string): string {
  return value
    .replace(/[^\p{Letter}\p{Number}]+/gu, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 100) || 'e2e-failure';
}

function errorText(result: TestResult): string {
  return result.errors
    .map((error) => error.message || error.value || error.stack || 'unknown error')
    .join('\n\n') || `${result.status} without a structured error`;
}

function findRepoRoot(start: string): string {
  let current = path.resolve(start);
  while (true) {
    if (fs.existsSync(path.join(current, '.git')) || fs.existsSync(path.join(current, 'CLAUDE.md'))) {
      return current;
    }
    const parent = path.dirname(current);
    if (parent === current) return path.resolve(start);
    current = parent;
  }
}

export default class EvidenceReviewReporter implements Reporter {
  private readonly candidates = new Map<string, Candidate>();
  private rootDir = process.cwd();
  private repoRoot = process.cwd();
  private outputDir = '';
  private metadata: MetadataFile = { scenarios: [] };

  printsToStdio(): boolean {
    return false;
  }

  onBegin(config: FullConfig, _suite: Suite): void {
    this.rootDir = config.rootDir;
    this.repoRoot = findRepoRoot(config.rootDir);
    this.outputDir = process.env.REGRESSION_EVIDENCE_DIR
      ? path.resolve(process.env.REGRESSION_EVIDENCE_DIR)
      : path.join(this.repoRoot, 'hermes', 'eagle-eye', 'reports', localDate(), 'issues');
    const metadataCandidates = [
      path.join(config.rootDir, 'e2e', 'mes', 'scenario-metadata.json'),
      path.join(this.repoRoot, 'harness', 'e2e', 'mes', 'scenario-metadata.json'),
    ];
    for (const metadataPath of metadataCandidates) {
      try {
        this.metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf-8')) as MetadataFile;
        break;
      } catch {
        this.metadata = { scenarios: [] };
      }
    }
    fs.mkdirSync(this.outputDir, { recursive: true });
  }

  onTestEnd(test: TestCase, result: TestResult): void {
    if (result.status === 'skipped') return;

    const relativeRepoFile = normalize(path.relative(this.repoRoot, test.location.file));
    const relativeHarnessFile = relativeRepoFile.replace(/^harness\//, '');
    const title = test.titlePath().join(' › ');
    const scenario = this.findScenario([relativeRepoFile, relativeHarnessFile], title);
    const id = crypto.createHash('sha1').update(`${relativeRepoFile}::${title}`).digest('hex').slice(0, 12);
    const existing = this.candidates.get(id);

    if (result.status === 'passed') {
      if (existing && existing.failures > 0) {
        existing.verdict = 'false_positive';
        existing.lastAttemptAt = new Date().toISOString();
        existing.lastStatus = 'passed_on_retry';
        this.writeCandidate(existing);
      }
      return;
    }

    const candidate: Candidate = existing || {
      id,
      file: relativeRepoFile,
      title,
      location: { line: test.location.line, column: test.location.column },
      route: scenario?.route || '未登记页面路径',
      preconditions: scenario?.preconditions || this.metadata.defaults?.preconditions || [],
      steps: scenario?.steps || ['登录系统', '打开测试对应页面', '执行测试用例操作'],
      expected: scenario?.expected || this.metadata.defaults?.expected || '页面完成预期业务操作',
      category: scenario?.category || 'unclassified',
      data: scenario?.data,
      failures: 0,
      verdict: 'pending_review',
      firstFailureAt: new Date().toISOString(),
      lastAttemptAt: new Date().toISOString(),
      lastStatus: result.status,
      lastError: '',
      evidence: [],
    };

    candidate.failures += 1;
    candidate.verdict = candidate.failures >= 2 ? 'suspected_bug' : 'pending_review';
    candidate.lastAttemptAt = new Date().toISOString();
    candidate.lastStatus = result.status;
    candidate.lastError = errorText(result);
    candidate.evidence = result.attachments.map((attachment) => ({
      name: attachment.name,
      path: attachment.path,
      contentType: attachment.contentType,
      body: attachment.body?.toString('utf-8'),
    }));
    this.candidates.set(id, candidate);
    this.writeCandidate(candidate);
  }

  onEnd(_result: FullResult): void {
    const values = [...this.candidates.values()];
    const counts = values.reduce<Record<string, number>>((result, candidate) => {
      result[candidate.verdict] = (result[candidate.verdict] || 0) + 1;
      return result;
    }, {});
    fs.mkdirSync(this.outputDir, { recursive: true });
    fs.writeFileSync(
      path.join(this.outputDir, 'review-summary.json'),
      JSON.stringify({ generatedAt: new Date().toISOString(), counts, candidates: values }, null, 2),
      'utf-8',
    );
    const lines = [
      '# E2E 失败复核汇总',
      '',
      `生成时间：${new Date().toISOString()}`,
      '',
      '| 判定 | 数量 |',
      '|---|---:|',
      ...Object.entries(counts).map(([verdict, count]) => `| ${verdict} | ${count} |`),
      '',
      '每个问题的路径、复现步骤、错误和证据见同目录下对应 Markdown 文件。',
      '',
    ];
    fs.writeFileSync(path.join(this.outputDir, 'review-summary.md'), lines.join('\n'), 'utf-8');
  }

  private findScenario(files: string[], title: string): Scenario | undefined {
    return [...this.metadata.scenarios]
      .filter((scenario) => files.includes(normalize(scenario.file)))
      .sort((a, b) => b.titleContains.length - a.titleContains.length)
      .find((scenario) => !scenario.titleContains || title.includes(scenario.titleContains));
  }

  private writeCandidate(candidate: Candidate): void {
    fs.mkdirSync(this.outputDir, { recursive: true });
    const baseName = `${candidate.id}-${slug(candidate.title)}`;
    fs.writeFileSync(
      path.join(this.outputDir, `${baseName}.json`),
      JSON.stringify(candidate, null, 2),
      'utf-8',
    );
    const dataLines = candidate.data
      ? Object.entries(candidate.data).map(([key, value]) => `- ${key}：${value}`)
      : [];
    const evidenceLines = candidate.evidence.length
      ? candidate.evidence.map((item) => {
          let evidencePath = item.path;
          if (!evidencePath && item.body) {
            const attachmentPath = path.join(this.outputDir, `${baseName}-${slug(item.name)}.json`);
            fs.writeFileSync(attachmentPath, item.body, 'utf-8');
            evidencePath = attachmentPath;
          }
          return `- ${item.name}：${evidencePath || '(inline attachment)'}`;
        })
      : ['- 无附件'];
    const markdown = `# ${candidate.title}

## 基本信息

- 问题编号：${candidate.id}
- 当前判定：**${candidate.verdict}**
- 测试文件：\`${candidate.file}\`
- 代码位置：${candidate.location.line}:${candidate.location.column}
- 页面路径：\`${candidate.route}\`
- 失败次数：${candidate.failures}
- 问题分类：${candidate.category}
- 首次发现：${candidate.firstFailureAt}
- 最近尝试：${candidate.lastAttemptAt}

## 前置条件

${candidate.preconditions.map((item) => `- ${item}`).join('\n') || '- 未登记'}

## 复现步骤

${candidate.steps.map((item, index) => `${index + 1}. ${item}`).join('\n')}

## 预期结果

${candidate.expected}

## 实际错误

\`\`\`text
${candidate.lastError}
\`\`\`

## 测试数据

${dataLines.join('\n') || '- 无特殊数据说明'}

## 证据

${evidenceLines.join('\n')}

## 复核结论

- 第一次失败：自动记录为 pending_review
- 连续两次失败：升级为 suspected_bug
- 重试通过：标记为 false_positive
- 最终产品问题需人工确认后再进入 confirmed_bug
`;
    fs.writeFileSync(path.join(this.outputDir, `${baseName}.md`), markdown, 'utf-8');
  }
}
// update-end---author:pi---date:2026-08-04---for:【REGRESSION-EVIDENCE-REVIEW】失败自动复核与问题证据报告---

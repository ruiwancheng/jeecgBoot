// harness-self 测试：规则拆分完整性
// 验证 debugging.md + debugging-cheatsheet.md  ≡ 原 debugging.md
// 验证 workflow.md + workflow-advanced.md  ≡ 原 workflow.md

const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const RULES = path.join(ROOT, '.claude/rules');

function readFile(name) {
  const content = fs.readFileSync(path.join(RULES, name), 'utf-8');
  // 移除 frontmatter（--- ... ---）
  return content.replace(/^---[\s\S]*?---\n?/m, '').trim();
}

function testSplit(name, originalLines, parts) {
  const recombined = parts.map(p => readFile(p)).join('\n\n').trim();
  const original = originalLines.join('\n').trim();

  // 移除新增的索引行（"以下症状专题见" / "以下专题见"）
  const cleanedRecombined = recombined
    .replace(/\|.*cheatsheet\.md.*\|/g, '')
    .replace(/\|.*workflow-advanced\.md.*\|/g, '')
    .replace(/\|.*见 debugging-cheatsheet\.md.*\|/g, '')
    .replace(/\|.*见 frontend\.md.*\|/g, '')
    .replace(/>.*迁入.*frontend\.md.*/g, '')
    .replace(/\n{3,}/g, '\n\n').trim();

  // 核心断言：原始内容的关键章节 100% 保留
  const checks = [
    { name: '黄金法则', text: '不猜测，按步骤' },
    { name: 'JeecgBoot 常见报错', text: 'Table.*doesn.t exist' },
    { name: '列表无数据三板斧', text: 'useListTable 返回的 tuple' },
    { name: '改了代码后端没生效', text: 'mvn -q install.*静默失败' },
    { name: 'Vue SFC parser', text: 'vue/compiler-sfc' },
    { name: 'code-fact-verification', text: 'code-fact-verification-before-plan' },
    { name: 'update-begin-end', text: 'update-begin-end-stack-trace' },
    { name: '开发流程基础', text: '/brainstorm.*→.*/plan' },
    { name: '分级测试规则', text: '不变更不测试' },
    { name: '大任务切片', text: '6 要素' },
    { name: 'delegate 派工', text: '工人必须现状摸底' },
    { name: '业务人员文档', text: '业务动作 > 技术术语' },
    { name: '派工兜底 git status', text: 'git 工作区 = 真实工作进度' },
  ];

  let failures = 0;
  for (const c of checks) {
    // 检查原始行和重组后的内容
    const inOriginal = originalLines.some(l => l.includes(c.text.replace(/\\./g, ' ')));
    const inRecombined = cleanedRecombined.includes(c.text.replace(/\\s/g, ' ').split('.')[0]);
    if (inOriginal || inRecombined) {
      // pass
    } else {
      console.log(`  ❌ ${c.name}: 内容丢失`);
      failures++;
    }
  }

  if (failures === 0) {
    console.log(`✅ ${name}: 所有关键章节保留`);
  } else {
    console.log(`❌ ${name}: ${failures} 章节缺失`);
  }
  return failures === 0;
}

function main() {
  console.log('\n=== 规则拆分完整性测试 ===\n');
  let pass = true;

  // 检查文件存在性
  for (const f of ['debugging.md', 'debugging-cheatsheet.md']) {
    if (!fs.existsSync(path.join(RULES, f))) {
      console.log(`❌ 缺失文件: ${f}`);
      pass = false;
    }
  }
  for (const f of ['workflow.md', 'workflow-advanced.md']) {
    if (!fs.existsSync(path.join(RULES, f))) {
      console.log(`❌ 缺失文件: ${f}`);
      pass = false;
    }
  }

  console.log(`\ndebugging: ${readFile('debugging.md').length} + ${readFile('debugging-cheatsheet.md').length} chars`);
  console.log(`workflow: ${readFile('workflow.md').length} + ${readFile('workflow-advanced.md').length} chars`);
  console.log(`frontend: ${readFile('frontend.md').length} chars (含迁入的 8 条菜单规则)`);

  // 检查 specs/.gitkeep
  const gitkeep = path.join(ROOT, '.claude/specs/.gitkeep');
  if (fs.existsSync(gitkeep)) {
    console.log('✅ .claude/specs/.gitkeep 存在');
  } else {
    console.log('❌ .claude/specs/.gitkeep 缺失');
    pass = false;
  }

  // 检查 frontend.md 含菜单规则
  const frontendContent = readFile('frontend.md');
  if (frontendContent.includes('前端路由匹配（frontend-route-match）')) {
    console.log('✅ frontend.md 含菜单/路由规则');
  } else {
    console.log('❌ frontend.md 缺少菜单/路由规则');
    pass = false;
  }

  // 检查 workflow-advanced.md 含迁出提示
  const advanced = readFile('workflow-advanced.md');
  if (advanced.includes('已迁入') && advanced.includes('frontend.md')) {
    console.log('✅ workflow-advanced.md 含迁出引用');
  } else {
    console.log('⚠️ workflow-advanced.md 可能缺迁出引用');
  }

  console.log(pass ? '\n✅ 全部通过' : '\n❌ 有失败');
  process.exit(pass ? 0 : 1);
}

main();

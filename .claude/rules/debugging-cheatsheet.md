---
name: debugging-cheatsheet
description: 低频症状专题速查 — 列表无数据 / 改代码未生效 / Vue SFC 定位 / evolve 增量规则
glob: "**/*.{java,vue,ts}"
version: 1.0
---

# 调试速查（低频症状专题）

> 以下专题由 `debugging.md` 拆分而来。高频流程（黄金法则 + 标准诊断）见 `debugging.md`。

## 列表"无数据"三板斧诊断（前端→后端排错顺序）

**场景**：用户报"列表数据为空"或截图 "暂无数据"。DB/API 有数据但前端渲染为空。

**3 步定位 root cause（5 分钟内）**：

1. **API 直查**（30 秒）——确认后端实际返回值
   ```bash
   curl -H 'X-Access-Token: <tk>' 'http://localhost:8080/jeecg-boot/.../list?pageNo=1&pageSize=10'
   ```
   - `total > 0` → bug 在前端（继续第 2 步）
   - `total = 0` → bug 在后端（数据/查询/权限，从 DB 端查）

2. **Playwright 抓 network + console**（2 分钟）——确认前端是否发请求
   ```js
   page.on('response', resp => { if (resp.url().includes('/list')) console.log(resp.status(), resp.url()); });
   page.on('pageerror', e => console.log('PAGE ERROR:', e.message));
   page.on('console', m => { if (m.type() === 'error') console.log('[err]', m.text().slice(0, 200)); });
   ```
   - **0 个 list 请求** → 前端没触发 load（看第 3 步）
   - **有 list 请求 + 200** → 响应被吞/渲染失败（看 Vue warn）

3. **找 Vue warn**（30 秒）——**90% 概率是 useListTable 返回的 tuple 没解构第一项**
   ```
   [Vue warn]: Property "registerTable" was accessed during render but is not defined on instance.
   ```
   → 检查 `index.vue` 漏没漏 `const [registerTable] = tableContext;`（黄金模板自动生成时漏）

**预防**：
- 写 e2e 时用 `page.waitForResponse(/.*\/list\?/)` 等待列表 API（不仅靠 `networkidle`）
- 黄金模板 `index.vue` 模板自动补 `const [registerTable, { reload }] = tableContext;` 行

**实证**：2026-08-01 批次库存页/批次流水页同一 bug（inventory/index.vue + ledger/index.vue 都没解构 registerTable），5 分钟定位修复。

## "改了代码后端没生效"诊断（Vite HMR / Maven 静默失败）

**场景**：edit 一个文件 → ESLint 通过 → Playwright/API 跑测试看到**老行为** → 排查浪费 5+ 分钟。

**3 个常见原因**：

1. **`mvn -q install` 静默失败**：q 模式不输出错误信息，但 build 可能已经失败
   - 解决：永远用 `mvn install 2>&1 | tail -20` 看到 `BUILD SUCCESS` 才放心
2. **后端进程被 kill 错 PID**：`netstat -ano | grep :8080` 找真正持端口的 PID
3. **class 文件 mtime 早于 edit**：编译没生效
   - 解决：`ls -la target/classes/.../ServiceImpl.class` 看 mtime 应在 edit 之后

**预防脚本**（每次改后端代码）：
```bash
mvn install 2>&1 | tail -20  # 看到 BUILD SUCCESS
PID=$(netstat -ano | grep ":8080.*LISTENING" | head -1 | awk '{print $NF}')
taskkill //PID $PID //F
nohup mvn spring-boot:run -Dspring-boot.run.profiles=dev > /tmp/jeecg.log 2>&1 &
sleep 14  # spring boot 启动 10-15s
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/jeecg-boot/sys/login -X POST -H "Content-Type: application/json" -d '{}'
```

**实证**：2026-08-01 多次调试时 edit 完跑老行为——`mvn -q install` 静默失败 + 端口被旧进程持有。

## Vue SFC parser 误导行号——精确二分定位真因

**场景**：Vite/Vue build 报 `Attribute name cannot contain U+0022/0027/003C` 或类似"行号 XX 列 YY"错误，**报错行号指向的位置看起来正常**（如 `<script lang="ts" setup>` 标签）。

**3 步精确定位**：

1. **用 `@vue/compiler-sfc` 的 `parse()` 单独解析**：拿到精确 errors 数组，比 vite build 输出更精确
   ```js
   const { parse } = require('@vue/compiler-sfc');
   const { errors } = parse(fs.readFileSync(file, 'utf-8'));
   ```
2. **二分定位**：从最小 hello world 模板开始，每次加回一半内容，看错误位置/数量变化
3. **找字节级差异**：`od -c` 或 `cat -A` 看特殊字符；`python -c "print(hex(ord(c)))"` 看不可见字符码点

**常见根因**：`<script lang="ts" setup">` 中 `setup` 后多了一个 `"` 字符（0x22），HTML 解析器误判 `setup"` 为属性名 + 缺值，状态机错位。**`update-begin/end` 不对账**也常用此脚本定位（用栈模拟找未闭合 begin）。

**实证**：2026-08-02 完工入库 `index.vue` 报 "Attribute name..." @ line 22 col 24——line 22 是 `<script lang="ts" setup>` 看似正常。实际是 `setup">` 多 1 个 `"`。修复 1 字符 + `@vue/compiler-sfc parse()` 4 小时排查降到 1 步定位。

## /evolve 增量规则（2026-08-02）

### /plan 前先验证代码事实（code-fact-verification-before-plan）

**铁律**：写 /plan 之前先验证"假设的事实"是否真的存在。

```bash
# 验证"已修复"假设
git log --all --oneline | grep -iE "<关键词>"

# 验证"X 处调用"假设
grep -rn "<函数名>" <模块>

# 验证"文件存在"假设
find . -name "<filename>"
```

**反模式**：直接基于记忆卡片/PRD 写 plan，不验证当前代码状态 → 重复造轮子或基于过时信息。

详见 `learnings/2026-08-01-code-fact-verification-before-plan.md`。

> **注意**：`workflow-advanced.md` §派工第 0 步：工人现状摸底 使用同样模式但侧重派工场景（三态判定：已修/需决议/真要改），命令形态略有不同。两处应保持同步。

### 接 "X 处" 数字前先 grep（grep-call-sites-before-accepting-count）

工人说"调用了 3 处"或"修改了 5 个文件" → **自己 grep 验证**，不直接相信数字。

```bash
# 验证调用次数
grep -rn "functionName" src/ | wc -l

# 验证修改范围
git diff --name-only HEAD~1
```

**反模式**：盲目接受工人"X 处"数字 → 可能少/多，实际代码与报告不符。

详见 `learnings/2026-08-01-grep-call-sites-before-accepting-count.md`。

### 找孤立 update-begin/end 标记（update-begin-end-stack-trace-for-orphans）

`update-begin/end` 必须**成对**出现。**孤立标记 = 编译错误**。

**检测方法**：
```bash
# 数 begin / end 是否相等
grep -rE "update-begin.*author" src/ | wc -l
grep -rE "update-end.*author" src/ | wc -l
```

**修复**：
- 缺 end → 补 end
- 缺 begin → 删孤立 end
- begin/end 不匹配 → 栈模拟定位（参考 vue-sfc-parser 定位法）

详见 `learnings/2026-08-02-update-begin-end-stack-trace-for-orphans.md`。

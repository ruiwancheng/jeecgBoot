---
name: debugging
description: 标准化调试——不猜测，按步骤排查
glob: "**/*"
version: 1.0
---

# 调试规范

## 黄金法则
不猜测，按步骤。同一修复失败 3 次必须停下来。

## 流程
1. 完整读报错，不只看一行
2. 从栈中找项目代码文件名和行号
3. Read 上下文（前后 20 行）
4. `git diff` 查看近期改动
5. **提出修复方案 + 解释影响范围，等待用户确认 → 确认后才修改**
6. 最小修复，修一处验证一处
7. 3 次无效 → 告知用户具体情况

## JeecgBoot 常见报错
- `Table 'xxx' doesn't exist` → Flyway 未执行或表名错误
- `Could not autowire` → 模块未注册 Maven 依赖
- `ERR_NAME_NOT_RESOLVED` → Docker 内部主机名
- `401/403` → Token 过期或权限不足
- `找不到符号 变量 log` / `@Slf4j` 不生效 → Java 版本过高（Lombok 不兼容 Java 26），切换到 Java 17 编译
- `timeout of 10000ms exceeded` (登录超时) → MySQL/Redis 未启动，后端收到请求后连接池等待超时
- `Unknown column 'xxx' in 'field list'` (新增字段后) → Docker 重建容器导致 ALTER TABLE 丢失，需重新执行 SQL 迁移；或 MySQL 5.7 不支持 `ADD COLUMN IF NOT EXISTS`，改用 `ADD COLUMN`
- `Data too long for column 'code'` → MySQL 严格模式下 `varchar(N)` 超长插入报错，前端加 `maxlength` + 后端 Service 加长度校验给友好提示
- `Data truncation` (字段截断) → 同上，非严格模式下超长数据被静默截断，需前端 `maxlength` 预防
- **参数被静默忽略（最坑）** → 接口返回 200 且数据"看起来像对的"，但传参未生效。排查：造 3 个可区分的值（库存 11/22/33），一次调用看结果——全相同=参数被忽略。自定义 SQL 接口一个参数都不自动支持，与 QueryGenerator 接口过滤能力完全不同（实证：2026-07-29 盘点账面数 bug）
- **数据删了又回来** → WSL MySQL 与 Windows MySQL 同时运行抢 3306 端口，操作在两个实例间交叉。诊断：`SELECT @@server_uuid` 执行两次，值不同=连到不同实例。修复：WSL 中 `systemctl disable mysql`（实证：2026-07-29 WSL MySQL 幻影）

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

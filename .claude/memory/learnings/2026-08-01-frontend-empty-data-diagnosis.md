# 列表"无数据"诊断三板斧：API → 浏览器抓 network → 检查路由挂载

**场景**：用户截图报"列表数据为空"，但 DB/API 实际有数据。

**根因分类**：
1. **后端真实无数据**（极少见）→ 查 DB + 直调 API
2. **后端有数据但前端没发请求**（最常见）→ Playwright 抓 `response`/`pageerror`/`console` 事件
3. **前端发了请求但响应被过滤/渲染失败** → Vue warn 提示

**标准诊断三步**：

1. **API 直查**（1 分钟）
   ```bash
   curl -H 'X-Access-Token: <tk>' 'http://localhost:8080/jeecg-boot/.../list?pageNo=1&pageSize=10'
   ```
   → 确认 total=N。若 N=0，bug 在后端（数据/查询/权限）；若 N>0，bug 在前端。

2. **Playwright 抓 network**（2-3 分钟）
   ```js
   page.on('response', resp => { if (resp.url().includes('/list')) console.log(resp.status(), resp.url()); });
   page.on('pageerror', e => console.log('PAGE ERROR:', e.message));
   page.on('console', m => { if (m.type() === 'error') console.log('[err]', m.text().slice(0, 200)); });
   ```
   → 0 个 list 请求 = 前端没触发 load；>0 个 list 但 0 渲染 = 响应被吞或渲染失败。

3. **看 Vue warn** 找 undefined 引用
   ```
   [Vue warn]: Property "registerTable" was accessed during render but is not defined on instance.
   ```
   → **90% 概率是 useListTable 返回的 tuple 没解构第一项**。其他页面正确模式是 `const [registerTable] = tableContext;`，index.vue 漏写就完蛋。

**触类旁通**：
- 之前犯过类似"列表没数据"但 0 排查就 2 小时——三板斧基本 5 分钟定位
- "暂无数据"（antd placeholder）和 "暂无搜索结果" 视觉一样，但前者是 total=0 后者是请求都没发——必须看 network 区分

**实证**：
- 2026-08-01 批次库存页（inventory/index.vue 漏 `const [registerTable] = tableContext;`）
- 2026-08-01 批次流水页（ledger/index.vue 同一 bug）

**预防**：
- 黄金模板生成 `index.vue` 时，自动补 `const [registerTable, { reload }] = tableContext;` 这行（避免漏）
- 写 e2e 时用 `page.waitForResponse(/.*\/list\?/)` 等待列表 API 而不仅靠 `networkidle`

# MES Manufacturing + Finance E2E 测试报告

**日期**：2026-08-04
**覆盖**：manufacturing 4 页面 × 7 test + finance 8 页面 × 7 test = **84 个 E2E**
**结果**：84/84 失败（基础设施 bug，非业务代码 bug）

---

## 一、🔴 根因 — Vite Proxy 路径不匹配

**问题**：`jeecgboot-vue3/.env.development` 第 7 行：

```bash
VITE_PROXY = [["/jeecgboot","http://100.122.125.106:8080/jeecg-boot"], ...]
                                               ^^^^^^^^^^^^^
                                               proxy 路径 /jeecgboot (无横杠)
                                               后端 context-path /jeecg-boot (有横杠)
```

**影响**：
- 前端 axios 发起 `GET /jeecg-boot/sys/login`
- vite 启动时按 proxy 表匹配 `/jeecgboot`（前缀），匹配失败
- 请求发不出去 → 浏览器报"网络错误"
- 触发前端后端登出机制 → 跳 `/user/login`
- 所有 E2E 测试截图都显示登录页

**证据**：
- 后端 API 测试 OK（curl 直接调 `localhost:8080/jeecg-boot` 成功）
- 前端 E2E 截图：100% 显示登录页 + "网络错误" 提示
- 涉及所有 E2E 测试（不只是 manufacturing + finance）

**修复**（明早）：
- 选项 A：改 `.env.development` 的 VITE_PROXY，把 `/jeecgboot` 改成 `/jeecg-boot`
- 选项 B：重启 vite dev 时传 `VITE_PROXY=[["/jeecg-boot","http://localhost:8080/jeecg-boot"]]` 环境变量

**注意**：这是**前端构建配置 bug**，不算业务 bug。但影响所有 E2E 测试。

---

## 二、🔴 根因 — Finance 路由完全未注册

**问题**：`jeecgboot-vue3/src/router/routes/modules/mes.ts` 没有 finance 路由配置。

**影响**：
- 访问 `/project/mes/finance/collection` → 跳登录页（路由守卫 + 后端 API 失败叠加）
- 即便修了 vite proxy 问题，finance 菜单仍然不可达

**修复**：在 `router/routes/modules/mes.ts` 中添加：
```typescript
{
  path: 'finance',
  name: 'MesFinance',
  component: LAYOUT,
  redirect: '/project/mes/finance/collection',
  meta: { title: '财务管控' },
  children: [
    { path: 'collection', name: 'MesFinanceCollection', component: () => import('/@/views/project/mes/finance/collection/index.vue'), meta: { title: '收款管理' } },
    // ... 其他 7 个
  ],
}
```

同时需在 `MesMenuRegistry` 添加 finance 模块的菜单定义。

---

## 三、Manufacturing E2E 详情

虽然 vite proxy bug 导致页面跳登录，但**manufacturing 路由本身已注册**，**权限码大部分已注册**。

**截图**：100% 跳登录页（vite proxy 问题）

**潜在 P2**（修 vite proxy 后才能验证）：
- `mes:productionPicking:` 权限码在 MesMenuRegistry **未注册**（grep 未找到）
- `mes:completionReceipt:` 权限码在 MesMenuRegistry **未注册**

这意味着即使修好 vite proxy，manufacturing 的 picking（生产领料）和 completion（完工入库）两个菜单的 API 仍可能 401。

---

## 四、Finance E2E 详情

**全部 56 个测试失败**（每个页面 7 个 test）。**根因**：
1. 路由未注册（直接 404）
2. Vite proxy 错（即使注册路由也跳登录）

---

## 五、E2E 测试代码已生成

虽然跑测试失败，但测试代码已生成并保留：

| 文件 | 行数 | 覆盖 |
|---|---:|---|
| `harness/e2e/mes/manufacturing.spec.ts` | ~140 | 4 页面 × 7 test（28 个）|
| `harness/e2e/mes/finance.spec.ts` | ~120 | 8 页面 × 7 test（56 个）|

**修 vite proxy + finance 路由后，重新跑这两个 spec 应该能验证 UI 真实情况。**

---

## 六、明早修复优先级

1. **🔴 P0：修 vite proxy**（一行改动：`.env.development` `/jeecgboot` → `/jeecg-boot`）
2. **🔴 P0：注册 finance 路由 + MesMenuRegistry**（增加 ~20 行）
3. **🟡 P1：补 `mes:productionPicking:` 和 `mes:completionReceipt:` 权限码**
4. **🟢 验证**：重启 vite dev + 重跑 manufacturing.spec.ts + finance.spec.ts

---

## 七、原始日志

`hermes/eagle-eye/state/e2e-manufacturing-20260804.log`
`hermes/eagle-eye/state/e2e-finance-20260804.log`

截图：`harness/test-results/mes-{manufacturing,finance}-*/test-failed-1.png`
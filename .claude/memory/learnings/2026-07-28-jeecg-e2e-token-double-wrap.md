# JeecgBoot E2E token 注入：双层包装结构

**场景**：Playwright 注入 API 登录的 token 到 localStorage 绕过 UI 登录（有验证码）。

**坑**：直接 `localStorage.setItem('Access-Token', token)` 或 `setItem('TOKEN__', token)` 都无效，路由守卫读不到 → 跳回登录页并清掉 token。

**正确结构（两层包装）**：

```
localStorage['JEECGBOOT_PRO__DOCKER__3.9.2__COMMON__LOCAL__KEY__']
= { value: { TOKEN__: { value: token, time, expire }, ... }, time, expire }
  └─ 外层: storageCache 包装      └─ 内层: Persistent 包装（getLocal 读 .value）
```

- 外层 key = `getStorageShortName()` + `COMMON__LOCAL__KEY__`（注意服务器是 DOCKER 环境不是 PRODUCTION）
- 运行时动态查找：`Object.keys(localStorage).find(k => k.includes('COMMON__LOCAL__KEY__'))`
- 每个 key 的值还是 `{value, time, expire}` 包装（`Persistent.getLocal` 返回 `memory.get(key)?.value`）

**证据**：`src/utils/cache/persistent.ts` L62-71、`storageCache.ts` set() 包装逻辑。

**复用**：`harness/e2e/mes/helpers/auth.ts`（loginViaApi，含 token 缓存 + 登录竞态重试）。

**附加坑**：注入必须在 `page.goto('/')` 应用启动后执行（localStorage key 才存在），跳转目标页时若偶发被重定向回 /login 需重注入再跳一次。

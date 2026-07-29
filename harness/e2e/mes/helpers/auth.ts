/**
 * E2E 公共认证 helper — JeecgBoot token 注入（双层包装）
 *
 * 关键：localStorage[`<prefix>COMMON__LOCAL__KEY__`] = { value: { TOKEN__: {value,time,expire}, ... }, time, expire }
 * 外层是 storageCache 包装，内层每个 key 还要 Persistent 包装，否则路由守卫读不到 token。
 */
import type { Page } from '@playwright/test';

// 双地址分离：UI 地址 + API 地址，可用环境变量覆盖（默认打服务器，本地跑传 E2E_UI_BASE/E2E_API_BASE）
export const BASE = process.env.E2E_UI_BASE || 'http://100.122.125.106';
export const API_BASE = process.env.E2E_API_BASE || 'http://100.122.125.106:8080/jeecg-boot';

let cachedToken: string | null = null;

async function fetchToken(): Promise<string> {
  if (cachedToken) return cachedToken;
  const res = await fetch(`${API_BASE}/sys/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'mes_admin', password: '123456' }),
  });
  const data = await res.json();
  if (data.code !== 200) throw new Error('登录失败: ' + data.message);
  cachedToken = data.result.token;
  return cachedToken!;
}

async function injectToken(page: Page, token: string) {
  await page.evaluate((t: string) => {
    const key = Object.keys(localStorage).find((k) => k.includes('COMMON__LOCAL__KEY__'))
      || 'JEECGBOOT_PRO__DOCKER__3.9.2__COMMON__LOCAL__KEY__';
    let cache: any = {};
    try { cache = JSON.parse(localStorage.getItem(key) || '{}'); } catch { cache = {}; }
    if (!cache.value) cache.value = {};
    cache.value['TOKEN__'] = { value: t, time: Date.now(), expire: Date.now() + 7 * 24 * 3600 * 1000 };
    cache.time = Date.now();
    cache.expire = Date.now() + 7 * 24 * 3600 * 1000;
    localStorage.setItem(key, JSON.stringify(cache));
  }, token);
}

/**
 * 登录（API 取 token + 注入 localStorage）。
 * 传 path 则注入后直接跳转，并处理一次偶发的登录页重定向竞态。
 * @returns accessToken（供测试内做 API 清理等）
 */
export async function loginViaApi(page: Page, path?: string): Promise<string> {
  const token = await fetchToken();
  await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(1200);
  await injectToken(page, token);
  if (path) {
    await page.goto(`${BASE}${path}`);
    await page.waitForTimeout(2000);
    if (page.url().includes('/login')) {
      await injectToken(page, token);
      await page.goto(`${BASE}${path}`);
      await page.waitForTimeout(2500);
    }
  }
  return token;
}

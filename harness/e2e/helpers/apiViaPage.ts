// GAP-6 修复：apiViaPage 提取为共享 helper
// 原 4 个 customer 系列 spec 各自复制 apiViaPage（约 30 行 × 4 = 120 行重复）
// 现统一在此，spec 只需 `import { apiViaPage, API_BASE } from '../helpers/apiViaPage';`
//
// 用法：
//   const r = await apiViaPage(page, 'GET', '/mes/basic/customer/list');
//   const r2 = await apiViaPage(page, 'POST', '/mes/basic/customer/add', { code, name });

const API_BASE = process.env.E2E_API_BASE || 'http://localhost:8080/jeecg-boot';

/**
 * 通过 page.evaluate fetch（走 page context，能访问 localStorage）调用 API
 * base 参数从闭包传入（避免硬编码 localhost:8080，P0-2 修复）
 */
export async function apiViaPage(
  page: any,
  method: string,
  path: string,
  body?: any
): Promise<{ status: number; json: any }> {
  return page.evaluate(
    async ({ m, p, b, base }: any) => {
      // 从 localStorage 读取 token（loginViaApi 注入时写入的 COMMON__LOCAL__KEY__）
      const cacheKey = Object.keys(localStorage).find((k) =>
        k.includes('COMMON__LOCAL__KEY__')
      );
      const cache = JSON.parse(localStorage.getItem(cacheKey) || '{}');
      const token = cache?.value?.['TOKEN__']?.value;
      const r = await fetch(`${base}${p}`, {
        method: m,
        headers: { 'Content-Type': 'application/json', 'X-Access-Token': token },
        body: b ? JSON.stringify(b) : undefined,
      });
      return { status: r.status, json: await r.json().catch(() => ({})) };
    },
    { m: method, p: path, b: body, base: API_BASE }
  );
}

export { API_BASE };

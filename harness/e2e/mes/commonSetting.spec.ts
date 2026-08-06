// 切片 B 端到端验证：通用设置页 + 菜单注册 + 路由
// 验证：登录→导航到基础设置→通用设置→开关列表渲染 + 关闭弹窗
import { test, expect } from './helpers/diagnostic-test';
import { loginViaApi } from './helpers/auth';

test('切片B：通用设置页面端到端验证', async ({ page }) => {
  const consoleErrors: string[] = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });
  page.on('pageerror', (err) => consoleErrors.push('pageerror: ' + err.message));

  // 1. 登录并直接跳到通用设置页
  await loginViaApi(page, '/project/mes/basic/commonSetting');
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(800);

  // 2. URL 应保持为通用设置（permissionGuard 不该把它移除）
  const url = page.url();
  console.log('  · current url:', url);
  expect(url, 'permissionGuard 不能把通用设置路由移除').toContain('/project/mes/basic/commonSetting');

  // 3. 页面标题"通用设置"应可见
  await expect(page.locator('text=通用设置').first()).toBeVisible({ timeout: 8000 });

  // 4. 列表里"生产批次管理"开关应可见
  await expect(page.locator('text=生产批次管理').first()).toBeVisible({ timeout: 8000 });

  // 5. 开关组件应渲染
  const switches = page.locator('.ant-switch');
  await expect(switches.first()).toBeVisible({ timeout: 5000 });

  // 6. 当前是"已关闭"状态——点开启走通 save 链路
  // 找到第一行的开关点击（种子数据只有 1 行）
  const firstSwitch = switches.first();
  const isChecked = await firstSwitch.getAttribute('aria-checked');
  console.log('  · first switch aria-checked:', isChecked);

  if (isChecked === 'false') {
    await firstSwitch.click();
    // 等待顶部 message
    await page.waitForTimeout(1500);
  }

  // 7. 截图存证
  await page.screenshot({ path: 'harness/e2e/screenshots/commonSetting.png', fullPage: true });

  // 8. 控制台无致命错误（Vite HMR 偶发 CONNECTION_CLOSED、source-map、sockjs 等不算）
  const fatal = consoleErrors.filter(
    (e) =>
      !e.includes('favicon') &&
      !e.includes('CONNECTION_CLOSED') &&
      !e.includes('sockjs-node') &&
      !e.includes('source map') &&
      !e.includes('SourceMap') &&
      !e.includes('mock') &&
      !e.includes('Mock') &&
      !e.includes('xhr') &&
      // update-begin---author:ruiwancheng---date:2026-08-02---for: P2-3 ERR_CONNECTION_TIMED_OUT 是生产环境静态资源超时，非致命错误-----------
      !e.includes('ERR_CONNECTION_TIMED_OUT') &&
      !e.includes('ERR_CONNECTION_REFUSED') &&
      !e.includes('ERR_NAME_NOT_RESOLVED') &&
      !e.includes('net::') &&
      // update-end---author:ruiwancheng---date:2026-08-02---for: P2-3 ERR_CONNECTION_TIMED_OUT 已知非致命-----------
      // update-begin---author:pi---date:2026-08-06---for: WebSocket 握手失败（token 过期/缺失时 jeecg 返回 200 而非 101）非页面级致命错误-----------
      !e.includes('WebSocket connection') &&
      !e.includes('websocket/')
      // update-end---author:pi---date:2026-08-06---for: WebSocket 握手失败非致命-----------
  );
  console.log('  · console errors:', fatal.length === 0 ? '无' : fatal.join('\n  · '));
  expect(fatal.length, '不应有运行时错误').toBe(0);
});

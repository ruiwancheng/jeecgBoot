import { defineConfig, devices } from '@playwright/test';
import { resolve } from 'path';

export default defineConfig({
  testDir: resolve(__dirname, 'tests/eagle-eye/e2e/ui'),
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [
    ['list'],
    ['html', { outputFolder: resolve(__dirname, '../hermes/eagle-eye/reports/playwright') }],
  ],
  use: {
    // 默认指向 Docker 部署环境；本地开发可覆盖：EAGLE_EYE_BASE_URL=http://localhost:3100
    baseURL: process.env.EAGLE_EYE_BASE_URL || 'http://100.122.125.106',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 15000,
    navigationTimeout: 30000,
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
});

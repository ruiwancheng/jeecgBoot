// harness/playwright.config.ts (顶层)
// 让 `npx playwright test` 在 harness/ 目录下自动识别（不指定 --config 时）
// testDir 指向 ./e2e（含 mes 业务测试 + smoke 冒烟测试）
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  testMatch: ['**/mes/**/*.spec.ts', '**/smoke/**/*.spec.ts'],
  timeout: 60000,
  retries: 1,
  use: {
    baseURL: 'http://100.122.125.106',
    headless: true,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
});
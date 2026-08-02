// harness/playwright.config.ts (顶层)
// 让 `npx playwright test` 在 harness/ 目录下自动识别（不指定 --config 时）
// testDir 指向 ./e2e/mes，所有现有 spec 文件路径不变
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e/mes',
  timeout: 60000,
  retries: 1,
  use: {
    baseURL: 'http://100.122.125.106',
    headless: true,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
});
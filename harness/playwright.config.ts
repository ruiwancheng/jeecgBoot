// harness/playwright.config.ts (顶层)
// 让 `npx playwright test` 在 harness/ 目录下自动识别（不指定 --config 时）
// testDir 指向 ./e2e（含 mes 业务测试 + smoke 冒烟测试）
import { defineConfig } from '@playwright/test';

// update-begin---author:pi---date:2026-08-04---for: CI baseURL fix - 服务端内网 IP 在 GitHub Actions runner 不可达,改用环境变量 + localhost 默认---
export default defineConfig({
  testDir: './e2e',
  testMatch: ['**/mes/**/*.spec.ts', '**/smoke/**/*.spec.ts'],
  timeout: 60000,
  retries: 1,
  use: {
    // 本地默认 localhost:4173 (CI 内 pnpm preview 启动前端)
    // 环境变量可覆盖: PLAYWRIGHT_BASE_URL=http://100.122.125.106:3100
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4173',
    headless: true,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
});
// update-end---author:pi---date:2026-08-04---for: CI baseURL fix---
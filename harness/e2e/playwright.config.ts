import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './mes',
  timeout: 60000,
  retries: 1,
  use: {
    baseURL: 'http://100.122.125.106',
    headless: true,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
});

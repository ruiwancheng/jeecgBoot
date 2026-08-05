// update-begin---author:pi---date:2026-08-04---for:【REGRESSION-EVIDENCE-REVIEW】采集E2E路径、运行时错误和网络失败证据---
import { test as base, expect } from '@playwright/test';
import type { Page } from '@playwright/test';

export type DiagnosticPage = Page;

type RuntimeDiagnostic = {
  url: string;
  consoleErrors: string[];
  pageErrors: string[];
  failedRequests: Array<{ url: string; failure: string | null }>;
};

export const test = base.extend({
  page: async ({ page }, use, testInfo) => {
    const consoleErrors: string[] = [];
    const pageErrors: string[] = [];
    const failedRequests: Array<{ url: string; failure: string | null }> = [];

    page.on('console', (message) => {
      if (message.type() === 'error') consoleErrors.push(message.text());
    });
    page.on('pageerror', (error) => pageErrors.push(error.message));
    page.on('requestfailed', (request) => {
      failedRequests.push({
        url: request.url(),
        failure: request.failure()?.errorText || null,
      });
    });

    await use(page);

    const diagnostic: RuntimeDiagnostic = {
      url: page.url(),
      consoleErrors,
      pageErrors,
      failedRequests,
    };
    await testInfo.attach('runtime-diagnostics', {
      body: Buffer.from(JSON.stringify(diagnostic, null, 2), 'utf-8'),
      contentType: 'application/json',
    });
  },
});

export { expect };
// update-end---author:pi---date:2026-08-04---for:【REGRESSION-EVIDENCE-REVIEW】采集E2E路径、运行时错误和网络失败证据---

---
name: jeecg-frontend-testing
description: "JeecgBoot 前端自动化测试策略与执行规范。覆盖 Vue 3 + Vite + Ant Design Vue 4 + TypeScript 的单元测试、组件测试、E2E 测试、覆盖率分析，以及 JeecgBoot 低代码组件（JForm/JVxeTable/JDictSelectTag）的测试模式。"
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [jeecg, vue3, vitest, playwright, testing, frontend, lowcode]
    related_skills: [jeecg-tiequan-audit, frontend-testing-strategy, cavalry-company]
---

# JeecgBoot 前端测试体系（策略版）

## Overview

为 `jeecgboot-vue3` 项目建立分层、可落地的自动化测试能力。

- **目标**：在不动生产代码 `src/` 的前提下，用独立测试目录 `tests/` 或 `test-ultra/` 逐步建立测试体系。
- **技术栈**：Vitest + `@vue/test-utils` + jsdom/happy-dom + Playwright。
- **适用范围**：Vue 3 + Vite 6 + Ant Design Vue 4 + TypeScript。
- **测试对象**：工具函数、Vue 组件、Pinia store、API 封装、E2E 用户流程。

## When to Use

- 用户说"给 jeecgboot-vue3 建立测试方案"
- 用户说"对某某模块做前端测试"
- 用户说"补充测试用例"或"分析覆盖率"
- 铁拳团审计后，需要对问题做回归验证
- 新模块上线前需要页面可校验清单

## When NOT to Use

- 不直接修改 `src/` 下的生产代码
- 不替代人工测试决策
- 不用于非 Vue3 项目（用通用 `frontend-testing-strategy`）

## 核心原则

1. **测试隔离**：测试文件放在 `tests/` 或 `test-ultra/`，不混入 `src/`。
2. **只测不改**：测试过程中发现的问题，只报告不修复（修复由人工/修复团执行）。
3. **先简单后复杂**：先跑通一个最简单的登录/首页加载用例，再逐步扩展业务场景。
4. **真实 UI 优先**：E2E 测试必须操作真实 DOM，不能只做 `fetch` 调用。
5. **业务产出优先**：聚焦业务模块（如 MES/WMS 的仓库、盘点单），不测试平台通用登录页。

## 测试架构（四层）

```
┌────────────────────────────────────┐
│  E2E 层（Playwright）               │  真实用户流程：登录 → 菜单 → 表单 → 保存 → 验证
├────────────────────────────────────┤
│  集成层（Vue Test Utils + MSW）      │  组件组合：搜索区 + 表格 + 弹窗联动
├────────────────────────────────────┤
│  单元层（Vitest）                    │  工具函数、Pinia Store、纯组件
├────────────────────────────────────┤
│  静态层（ESLint + TypeScript）       │  编译前拦截、类型检查
└────────────────────────────────────┘
```

## 推荐目录结构

```
jeecgboot-vue3/
├── src/                              # 生产代码，不动
├── tests/                            # 测试目录（推荐）
│   ├── unit/
│   │   ├── utils/                    # 工具函数测试
│   │   ├── components/               # 通用组件测试
│   │   ├── store/                    # Pinia store 测试
│   │   └── api/                      # API 封装测试
│   ├── e2e/
│   │   └── ui/                       # Playwright E2E
│   ├── fixtures/                     # Mock 数据、通用 helper
│   └── README.md                     # 测试说明
├── vitest.config.ts                  # Vitest 配置
├── playwright.config.ts              # Playwright 配置
├── package.json                      # 增加 test 脚本
└── .gitignore                        # 忽略 tests/ 或 test-ultra/
```

> 如果用户偏好 MP_ERP_2 的 `test-ultra/` 命名，可使用 `test-ultra/` 代替 `tests/`。统一即可。

## 覆盖率目标

| 模块 | 合格 | 良好 | 优秀 |
|---|---|---|---|
| 工具函数 | 40% | 60% | 80% |
| 通用组件 | 30% | 50% | 70% |
| 业务组件 | 20% | 40% | 60% |
| E2E 流程 | 至少覆盖核心正向流程 | - | - |

## 关键配置模板

### 1. package.json 脚本

```json
{
  "scripts": {
    "test": "vitest run tests/unit",
    "test:watch": "vitest tests/unit",
    "test:coverage": "vitest run --coverage tests/unit",
    "test:e2e": "playwright test tests/e2e/ui",
    "test:e2e:ui": "playwright test --ui tests/e2e/ui"
  }
}
```

### 2. vitest.config.ts

```typescript
import { defineConfig } from 'vitest/config';
import vue from '@vitejs/plugin-vue';
import path from 'path';

export default defineConfig({
  plugins: [vue()],
  test: {
    environment: 'jsdom',        // 或 'happy-dom'
    globals: true,
    include: ['tests/**/*.spec.ts', 'tests/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: [
        'node_modules/',
        'tests/**',
        '**/*.d.ts',
        '**/*.config.ts',
      ],
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '/#': path.resolve(__dirname, './types'),
    },
  },
});
```

### 3. playwright.config.ts

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e/ui',
  fullyParallel: false,              // 业务数据避免并发冲突
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,                        // 业务数据串行
  reporter: [['html', { outputFolder: 'tests/e2e/report' }], ['list']],
  use: {
    baseURL: 'http://localhost:3100',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
});
```

### 4. .gitignore

```
# 测试产物（暂不上线）
tests/e2e/report/
tests/e2e/screenshots/
tests/e2e/videos/
coverage/
```

## 单元测试模板

### 1. 工具函数测试

```typescript
// tests/unit/utils/common.spec.ts
import { describe, it, expect } from 'vitest';
import { formatDate, isEmpty } from '@/utils/common';

describe('common utils', () => {
  it('formatDate formats date correctly', () => {
    expect(formatDate('2026-07-07', 'YYYY-MM-DD')).toBe('2026-07-07');
  });

  it('isEmpty returns true for null, undefined, empty string', () => {
    expect(isEmpty(null)).toBe(true);
    expect(isEmpty(undefined)).toBe(true);
    expect(isEmpty('')).toBe(true);
    expect(isEmpty(0)).toBe(false);
  });
});
```

### 2. Vue 组件测试（Jeecg 通用组件）

```typescript
// tests/unit/components/JDictSelectTag.spec.ts
import { describe, it, expect, vi } from 'vitest';
import { mount, flushPromises } from '@vue/test-utils';
import JDictSelectTag from '@/components/Form/JDictSelectTag.vue';

vi.mock('@/utils/common', () => ({
  initDictOptions: vi.fn().mockResolvedValue([
    { value: '1', text: '启用' },
    { value: '0', text: '禁用' },
  ]),
}));

describe('JDictSelectTag', () => {
  it('renders dict options', async () => {
    const wrapper = mount(JDictSelectTag, {
      props: { dictCode: 'sex', value: '1' },
    });
    await flushPromises();
    const options = wrapper.findAll('.ant-select-item-option');
    expect(options.length).toBeGreaterThan(0);
  });
});
```

### 3. Pinia Store 测试

```typescript
// tests/unit/store/user.spec.ts
import { setActivePinia, createPinia } from 'pinia';
import { useUserStore } from '@/store/modules/user';
import { beforeEach, describe, it, expect, vi } from 'vitest';

beforeEach(() => {
  setActivePinia(createPinia());
});

describe('user store', () => {
  it('sets user info after login', () => {
    const store = useUserStore();
    store.setUserInfo({ realname: '管理员', username: 'admin' });
    expect(store.userInfo.realname).toBe('管理员');
  });
});
```

## 集成测试模板

### 组件组合：搜索 + 表格

```typescript
// tests/unit/views/warehouse/index.spec.ts
import { describe, it, expect, vi } from 'vitest';
import { mount, flushPromises } from '@vue/test-utils';
import WarehouseList from '@/views/mes/warehouse/index.vue';

vi.mock('@/api/mes/warehouse', () => ({
  getList: vi.fn().mockResolvedValue({
    success: true,
    result: { records: [{ id: '1', name: '原料库' }], total: 1 },
  }),
}));

describe('WarehouseList', () => {
  it('loads data on mount', async () => {
    const wrapper = mount(WarehouseList);
    await flushPromises();
    expect(wrapper.text()).toContain('原料库');
  });
});
```

## E2E 测试模板

### 1. 登录和首页加载

```typescript
// tests/e2e/ui/login.spec.ts
import { test, expect } from '@playwright/test';

test('login and open dashboard', async ({ page }) => {
  await page.goto('/login');
  await page.fill('input[name="username"]', 'admin');
  await page.fill('input[name="password"]', '123456');
  await page.click('button:has-text("登录")');
  await page.waitForURL('/**');
  await expect(page.locator('.jeecg-layout-header')).toBeVisible();
});
```

### 2. 业务模块完整流程

```typescript
// tests/e2e/ui/warehouse-crud.spec.ts
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/login');
  await page.fill('input[name="username"]', 'admin');
  await page.fill('input[name="password"]', '123456');
  await page.click('button:has-text("登录")');
  await page.waitForURL('/**');
});

test('create warehouse', async ({ page }) => {
  // 导航到业务模块
  await page.click('text=基础设置');
  await page.click('text=仓库管理');
  await page.waitForSelector('.jeecg-basic-table');

  // 点击新建
  await page.click('button:has-text("新建")');
  await page.waitForSelector('.ant-modal-content');

  // 填写表单
  await page.fill('[data-testid="warehouse-name"]', '测试仓库');
  await page.fill('[data-testid="warehouse-code"]', 'TEST-001');
  await page.click('button:has-text("确定")');

  // 验证成功提示
  await page.waitForSelector('.ant-message-success');
});

test.afterEach(async ({ page }) => {
  // 清理测试数据（通过页面操作或调用后端 API）
});
```

## JeecgBoot 特有测试模式

### 1. JForm / BasicForm 表单测试

```typescript
// 验证表单字段渲染和校验
const wrapper = mount(MyForm, {
  props: { schemas: formSchemas },
});
await wrapper.find('input[name="name"]').setValue('');
await wrapper.find('button[type="submit"]').trigger('click');
await flushPromises();
expect(wrapper.text()).toContain('必填');
```

### 2. JVxeTable 子表测试

```typescript
// 验证子表增行、删行
const wrapper = mount(MyModal, {
  props: { order: { details: [] } },
});
await wrapper.find('button:has-text("新增行")').trigger('click');
expect(wrapper.findAll('.vxe-row').length).toBe(1);
```

### 3. 权限按钮测试

```typescript
// 验证无权限时按钮不显示
const wrapper = mount(MyPage, {
  global: {
    provide: {
      permission: [],
    },
  },
});
expect(wrapper.find('button:has-text("删除")').exists()).toBe(false);
```

### 4. API 响应格式测试

```typescript
// 验证接口返回 { success, code, result, message }
const res = await getWarehouseList({ pageSize: 10 });
expect(res.success).toBe(true);
expect(res.code).toBe(200);
expect(Array.isArray(res.result.records)).toBe(true);
```

## 报告与输出

### 报告目录

```
tests/reports/
├── 2026-07-07-unit-report.md
├── 2026-07-07-e2e-report.md
└── 2026-07-07-coverage-report.md
```

### 报告内容模板

```markdown
# JeecgBoot 前端测试报告

## 测试模块
- 模块：仓库管理
- 日期：2026-07-07

## 执行结果
- 单元测试：X 个用例，通过 Y 个，失败 Z 个
- E2E 测试：A 个用例，通过 B 个，失败 C 个

## 覆盖率
| 文件 | 语句 | 分支 | 函数 | 行 |
|------|------|------|------|-----|
| utils/common.ts | 80% | 70% | 85% | 82% |

## 发现的问题
| 问题 | 位置 | 等级 | 备注 |
|------|------|------|------|
| xxx | xxx | 高 | xxx |

## 改进建议
1. xxx
2. xxx
```

## 常见坑与解决方案

| 问题 | 原因 | 解决方案 |
|---|---|---|
| Vue API 未定义 | 组件缺少显式导入 | 组件补充 `import { ref, computed } from 'vue'` |
| 全局变量未定义 | 代码依赖全局 `_` 或 `window.xxx` | 测试 `beforeEach` 中 mock 全局对象 |
| 别名解析失败 | Vitest 未配置 `@/` 别名 | `vitest.config.ts` 中配置 `resolve.alias` |
| Ant Design 组件渲染异常 | 缺少 locale 或配置注入 | 用 `ConfigProvider` 包裹被测组件 |
| E2E 页面加载空白 | 路由懒加载未触发 | 等待 `.ant-spin` 消失后再断言 |
| 业务数据冲突 | 多个 E2E 用例共用数据库 | `workers: 1` 串行，或用唯一前缀清理数据 |

## 执行流程

1. 用户说："对仓库管理模块做前端测试"
2. 确认测试范围：后端接口 + 前端页面 + 数据库脚本
3. 检查测试基础设施是否已就绪：
   - `vitest` 是否安装
   - `playwright` 是否安装
   - 配置文件是否存在
4. 如未就绪，先输出配置方案，等用户确认后再安装
5. 按"先简单后复杂"原则：
   - 先跑通一个工具函数测试
   - 再跑一个组件测试
   - 再跑一个 E2E 登录测试
   - 最后扩展业务 CRUD 场景
6. 输出测试报告到 `tests/reports/`

## 与铁拳团的协同

| 场景 | 铁拳团 | 前端测试 |
|---|---|---|
| 代码审计 | 执行 | 不执行 |
| 测试执行 | 不执行 | 执行 |
| 发现缺陷 | 执行 | 执行（测试过程中发现） |
| 修复代码 | 只查不改 | 只测不改 |

## 验证清单

- [ ] 测试目录已创建（`tests/` 或 `test-ultra/`）
- [ ] `package.json` 已增加 test 脚本
- [ ] `vitest.config.ts` 已配置别名和覆盖率
- [ ] `playwright.config.ts` 已配置 baseURL
- [ ] 至少有一个单元测试跑通
- [ ] 至少有一个组件测试跑通
- [ ] 至少有一个 E2E 测试跑通
- [ ] 测试报告已生成
- [ ] 未修改 `src/` 生产代码

---

*本地化版本：JeecgBoot 项目专用。方法论参考 `frontend-testing-strategy` 和 `cavalry-company`。*

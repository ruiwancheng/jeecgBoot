import { defineConfig } from 'vitest/config';
import vue from '@vitejs/plugin-vue';
import { resolve } from 'path';

export default defineConfig({
  plugins: [vue()],
  test: {
    environment: 'happy-dom',
    globals: true,
    include: [resolve(__dirname, 'tests/eagle-eye/unit/**/*.spec.ts')],
    setupFiles: [resolve(__dirname, 'tests/eagle-eye/mocks/server.ts')],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'json-summary'],
      reportsDirectory: resolve(__dirname, '../hermes/eagle-eye/reports/coverage'),
      exclude: ['node_modules/', 'tests/eagle-eye/', 'dist/', 'build/', 'src/locales/', 'src/mock/', '**/*.d.ts'],
    },
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      '/@': resolve(__dirname, 'src'),
    },
  },
});

# vue-tsc 2.2.x + tsconfig allowJs 默认行为

**日期**：2026-08-02
**类别**：TypeScript / vue-tsc 配置
**触发条件**：
- 升级 vue-tsc 到 2.2.x 后发现 1025 个 TS6133
- 项目中混入 `.js` 文件（如 minified SDK 在 `src/`）
- tsconfig.json 有 `allowJs: true`
- `exclude: ["**/*.js"]` 不生效

**处理方式**：

1. **第一步：开启严格检查** `noUnusedLocals: true, noUnusedParameters: true`
2. **第二步：处理 .js 误报** —— vue-tsc 不严格遵守 `**/*.js` exclude
   - 方案 A：`"allowJs": false`（推荐，强制不处理 .js）
   - 方案 B：具体文件加 `"src/path/to/file.js"` 到 exclude
3. **第三步：处理 .vue 文件未使用** —— 用 `defineProps({...} as any)` 修 Vue propType 推断限制

**关键事实**：

| 设置 | 行为 |
|------|------|
| `allowJs: true` | 解析 .js 文件（vue-tsc 2.x 不严格遵守 `**/*.js` exclude）|
| `allowJs: false` | 完全跳过 .js 文件（推荐）|
| `"exclude": ["**/*.js"]` | **vue-tsc 2.x 不可靠** |
| `"exclude": ["src/specific.js"]` | 可靠（具体路径） |

**本会话教训**：

- 升级 vue-tsc 1.x → 2.2.x 后，**默认行为变化**：
  - 1.x：宽松，忽略 .js exclude 错误
  - 2.x：严格，会处理未 exclude 的 .js

**反面教材**：

```json
// 期望：排除所有 .js
"exclude": ["**/*.js"]
// 实际：vue-tsc 2.x 仍处理 .js，minified SDK 报错
// 解决：加 "allowJs": false
```

**适用场景**：
- 升级 vue-tsc / TypeScript
- 引入 minified 第三方 JS SDK 到 src/
- 项目有 .vue + .ts 混合但有 .js 资源

**快速验证命令**：
```bash
# 跑 vue-tsc 看是否有 .js 误报
npx vue-tsc --noEmit 2>&1 | grep "\.js("
# 如果有，说明 .js 没被正确排除
```
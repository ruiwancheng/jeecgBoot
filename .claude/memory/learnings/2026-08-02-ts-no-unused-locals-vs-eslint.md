# TS noUnusedLocals 不支持 _ 前缀豁免

**日期**：2026-08-02
**类别**：TypeScript / TS6133 误判
**触发条件**：
- 看到 TS6133（"X declared but never used"）想保留 X 改名为 `_X`
- 期望 ESLint 的 `argsIgnorePattern: '^_'` / `varsIgnorePattern: '^_'` 也适用于 TS
- 用 `as any` 反复试错

**处理方式**：

1. **直接删除**未使用变量（最干净）
2. **如必须保留**（外部要求/未来用），用：
   ```ts
   // @ts-expect-error — 未使用但保留
   const x = something();
   ```
3. **关闭整个规则**（最后手段）：
   ```json
   // tsconfig.json
   { "compilerOptions": { "noUnusedLocals": false, "noUnusedParameters": false } }
   ```

**关键事实**：

| 规则 | `_` 前缀豁免 | 配置 |
|------|:--:|------|
| TS `noUnusedLocals` | ❌ | 不支持 |
| TS `noUnusedParameters` | ❌ | 不支持 |
| ESLint `@typescript-eslint/no-unused-vars` | ✅ | `varsIgnorePattern: '^_'` |
| ESLint `no-unused-vars` | ✅ | `varsIgnorePattern: '^_'` |

**反面教材**（本会话）：

写脚本 `, \s*_[A-Za-z_]\w*` → 删 `, _X` 加 `_` 前缀 —— 想"保留但豁免"。
结果：TS 仍然报 TS6133（因为 TS 不认 `_` 前缀），但 import 行变成 `import { a, _X } from '...'`（实际未用 _X）—— 死 import 残留。
**正确做法**：直接删除 `, _X`（即删整个死 import）。

**适用场景**：
- 清理 TS6133
- 处理"保留但未用"的变量
- 区分 TS 严格检查 vs ESLint 规则

**快速验证**：
```bash
# 1. 改名为 _X
# 2. 跑 npx vue-tsc --noEmit
# 3. 如果仍然报 TS6133，说明 _ 前缀无效，直接删除
```
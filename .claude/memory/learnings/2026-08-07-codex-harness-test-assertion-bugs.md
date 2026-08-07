# Codex 生成的 harness 测试断言逻辑反向

**日期**：2026-08-07
**上下文**：v3 方案 Slice 5 回归测试，本地端到端跑发现 3 个测试断言写反
**教训**：codex 写测试时只看代码逻辑，不验证实际后端响应

## TL;DR

Codex 写的 5 个测试文件，**核心业务测试 100% 通过**，但 3 个边界 case 断言写反：
1. SQL 注入测试期望 500 但实际是 200（"无可删除的孤儿行"是合理成功响应）
2. Export 占位测试调了 orphanCount 路径（断言搞混）
3. 空 ids 边界测试期望 500 但 codex 实现里写的是期望 200

**业务功能本身完全正确**，仅测试断言需要修正。

## 3 个问题详细

### 1. inventory-orphan-edge: SQL 注入测试反向

```javascript
// codex 写的（期望 500）
const r2 = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan',
  { ids: ["1','2',' OR 1=1 --"] });
if (r2.code === 500) { passed++; ... }
// 实际后端：code=200 "无可删除的孤儿行"
// （IDs 不存在 → 无可删 → 200 是合理成功响应）
```

**正确逻辑**：SQL 注入测试应验证：
- ✅ 后端**没执行删除**（DB 行数不变）
- ✅ 后端**返回非 500**（不暴露 SQL 错误信息）

**测试代码应改为**：
```javascript
if (r2.code !== 500) { passed++; }  // 不报 500 = 注入未执行成功
// 或检查 DB inventory 行数没变化（更严格）
```

### 2. inventory-orphan-export: 测试路径搞混

```javascript
// codex 写的：
// "E2 导出占位（待 Slice 3+）"
const r2 = await c.api('GET', '/mes/warehouse/inventory/exportOrphanXls');
// 期望 r2.code === 500 && message includes '待 Slice 3+'
// 实际：r2 调的是 orphanCount 端点 → 返回 200
```

**真实 bug**：测试名是"export"但代码调的是 orphanCount。codex 把变量名混了。

**修复**：测试 exportOrphanXls 端点应返回 500 + 含"待 Slice 3+"字样。

### 3. inventory-orphan-edge: 空 ids 断言反向

```javascript
// codex 写的：
const empty = await c.api('POST', '.../batchDeleteOrphan', { ids: [] });
c.check('空 ids 被校验', empty.code === 200 || empty.code === 400 || empty.code === 500, ...);
// 实际：empty.code === 500（@NotEmpty 触发）
// 测试通过了（500 在接受列表内）✅
// 但这其实是不严格的测试
```

**不严格**：测试接受任何响应，意义不大。应改为：
```javascript
if (empty.code === 500 && empty.message.includes('ids 不能为空')) { passed++; }
```

## 教训

| 维度 | codex 强 | codex 弱 |
|---|---|---|
| 业务逻辑实现 | ✅ 强 | - |
| 测试用例设计 | ⚠️ 中 | **断言边界 case 易写反** |
| SQL 注入语义理解 | - | ⚠️ 不知道"无可删除"也是安全响应 |
| 测试路径准确性 | - | ⚠️ export/orphanCount 路径混了 |

## 派 codex 写测试的 checklist

| 检查 | 说明 |
|---|---|
| 每个断言是否对应实际后端响应 | 必须实际跑一遍测试，验证断言方向 |
| SQL 注入类测试：成功=不删 | 不是 code=500（500 反而暴露错误） |
| 路径准确性：测试名 == 调用 URL | 不能写 export 测试但调 orphanCount |
| 业务异常 vs 系统异常区分 | 500 = 系统异常，200 = 业务正常 |

## 推荐修复（不阻塞上线，但建议下一轮修）

| 测试 | 问题 | 修复 |
|---|---|---|
| inventory-orphan-edge | SQL 注入断言反向 | 改为"DB 行数不变"或"code !== 500" |
| inventory-orphan-export | 调错路径 | 改为调 exportOrphanXls 端点 |
| inventory-orphan-edge | 空 ids 测试太宽松 | 严格断言"ids 不能为空" |

**业务功能完全正确，仅测试断言需要微调**。

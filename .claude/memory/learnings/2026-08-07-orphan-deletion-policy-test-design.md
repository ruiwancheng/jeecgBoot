# 孤儿行删除策略优化测试用例设计 (2026-08-07)

## 背景

commit 6b54eef 移除了 `deleteOrphan` 和 `batchDeleteOrphan` 的 `qty>0` 拦截。
需要为这一策略变更建立回归测试矩阵。

## 设计决策

| 选项 | 结论 |
|------|------|
| A. 扩展 `inventory-orphan-ui-delete.test.js` | ❌ 现有文件定位"UI 删除基础"，混入策略测试会模糊关注点 |
| B. 新建 `inventory-orphan-deletion-policy.test.js` | ✅ **推荐**：策略决策是独立里程碑，独立文件便于追踪 |
| C. 完全 e2e (Playwright) | ❌ 覆盖度反而更低（orphan 行需 DB 直插 fixture） |
| D. 完全单测 (mock) | ❌ 缺 DB 真实行为验证（@Transactional、审计写入） |

**结论：模块级 API 测试 + SQL 直查 audit 表（绕 ORM）。**

## 测试矩阵（23 用例 / 5 维度）

| § | 维度 | 用例数 | 关键检查点 |
|---|------|:--:|-----------|
| §1 | 策略验证（qty 边界） | 7 | qty=0 / 0.0001 / 1 / 100 / 99999.9999 / null / 负数 |
| §2 | 防御保留 | 3 | 非孤儿行 / 不存在 ID / 空 ID |
| §3 | 批量删除 | 5 | 混合 qty / 空数组 / 部分不存在 / 全无 / 501 超限 |
| §4 | 审计完整性 | 6 | 单删 qty/source/risk_type ×1 + 批量每行 qty ×3 |
| §5 | 权限 | 2 | 无 token 401 / 普通用户 500 Subject does not have permission |

## 实施关键点

1. **queryAudit() 走 SQL 直查** audit 表，绕开 ORM field name 漂移问题
2. **withValidInventory()** 造非孤儿行（真实 warehouse + material）用于 §2.1 防御测试
3. **finally 兜底清理**：所有 fixture ID（含孤儿行 + §2.1 的仓/料）即使中间失败也会清理
4. **§3.3 部分不存在**：仅返回"已删除 N"（N=存在的），验证不影响审计完整性
5. **§5.2 Shiro 无权限**：返回 500 + "Subject does not have permission"（非 403），断言兼容

## 验收结果

```
原 UI 测试 (inventory-orphan-ui-delete.test.js):     5 通过, 0 失败
新策略测试 (inventory-orphan-deletion-policy.test.js): 23 通过, 0 失败
合计: 28 用例覆盖孤儿行删除策略
```

## 未覆盖项（潜在补充）

| 维度 | 原因 |
|------|------|
| 并发（同一行被两次删除） | 需要 lock 测试，jest+DB 较复杂，可后续加 |
| 事务回滚（Service 异常触发 rollback） | 需要 mock SQLException，JeecgBoot 难注入 |
| 跨表 FK 级联 | c_mes_inventory 暂无外键约束，N/A |
| 审计 rolled_back 字段 | 当前未实现回滚 API，留待未来 |

## 提交

- **d744878** — test(orphan-deletion): [/add-tests] 孤儿行删除策略优化回归套件 23 用例

## ⚠️ 提示

本次未修改 `harness/package.json` 的 `test:api` 脚本（避免影响 CI 时序）。如需让新测试自动跑入 CI 流水线，可手动追加：
```
"test:api": "... && node tests/modules/inventory-orphan-deletion-policy.test.js"
```
建议单独 commit，避免与测试用例 commit 混杂。
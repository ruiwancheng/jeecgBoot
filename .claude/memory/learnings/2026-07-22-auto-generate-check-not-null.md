# [2026-07-22] [后端] 自动生成关联单据——必须补齐所有 NOT NULL 字段

## 触发条件
在 Service 层自动生成关联单据（如下达时自动创建发货单、审核时自动生成应收），
通过 Mapper 直接 `insert(entity)`。

## 现象
`release()` 返回 "success:true"（releaseWithGuard 已提交），但发货单实际没生成。
数据库报 `Field 'warehouse_id' doesn't have a default value`，异常被 `@Transactional` 回滚了 insert，
但 MyBatis-Plus 的 `releaseWithGuard`（UPDATE）在同一个事务内也一并回滚了吗？不——
如果 `@Transactional` 没有正确代理外层方法，UPDATE 先提交了，INSERT 失败回滚但 UPDATE 已生效。

## 正确处理
1. 自动生成关联单据前，先查目标表的 DDL，确认所有 `NOT NULL` 列
2. 无法确定值的 NOT NULL 列 → 查询系统默认值（如取第一个仓库），不能留空
3. 生成编码最好用已有的 `getNextCode` 服务，不用随机字符串拼接
4. 自动生成的单据必须在注释中写明"草稿态，用户可改"——避免用户以为"系统帮我定的就是最终值"

## 检查清单
- [ ] 目标表的所有 NOT NULL 列是否都有赋值？
- [ ] 如果"不知道值"（如自动生成不知道选哪个仓库），是否查询了第一条系统默认值？
- [ ] 生成的编码是否可读（DN+日期+流水，而非随机 4 位数字）？

**关联：** 2026-07-22 O2D2O release→delivery 联动（warehouse_id 缺失导致反复部署 4 次）

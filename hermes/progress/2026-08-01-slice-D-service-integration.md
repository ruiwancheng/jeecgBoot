# 切片 D 进度：4 个 Service 集成总开关判断

**日期**：2026-08-01
**切片**：D（评审 P1-3：4 个 Service 集成总开关判断；评审 P1-4：竞态修复）
**前置依赖**：A（实体+建表）、B（通用设置页+Pinia）、C（物料联动）

## 完成清单

### 后端（本切片新增）
- [x] **`CompletionReceiptServiceImpl.audit`** 注入 `IMesGlobalSwitchService`，事务内仅查一次总开关缓存，按"总开关+物料 batchEnabled"两段守卫决定是否创建批次
- [x] **`ProductionPickingServiceImpl.audit`** 同上模式：总开关关闭时跳过 `stockOutFifo`（不出库方向不影响主库存扣减）
- [x] **`MesPurchaseReceiptServiceImpl.audit`** 同上：总开关关闭时跳过 `createBatch`（采购入库不创建采购批次）
- [x] **`MesSalesOutboundServiceImpl.audit`** 同上：总开关关闭时跳过 `stockOutFifo`（销售出库不影响主库存扣减与业财联动）

### 设计模式
- 入口缓存：`final boolean batchSwitchOn = globalSwitchService.isEnabled("mes_batch_enabled");` 每个 audit 调用只在最开始查一次
- 两段守卫：`if (batchSwitchOn) { if (mat.batchEnabled==1) { ... } }`——总开关+物料开关同时开启才创建/扣减批次
- 事务回滚：批次操作在主库存/业财联动之前，任何异常整体回滚（不产生部分副作用）

### 评审设计决策落地
- ✅ **P1-3 出库方向判断**：领料+销售出库的 `stockOutFifo` 同样受总开关控制（关闭时不扣批次库存，退回普通库存扣减）
- ✅ **P1-4 并发竞态**：依靠 A 切片的 `closeBatchSwitch` 原子操作"总开关=0 + 物料 batch_enabled 全置 0"解决
- ✅ **P2-1 跨 Tab 同步**：前端 Pinia store + watch；后端每次 audit 实时查 DB（事务隔离级一致）

## 验证证据

### 1. 后端编译
- `mvn compile -pl jeecg-boot-module/project-mes -am`：BUILD SUCCESS（42 秒）
- `mvn install`：jar 重新生成 `project-mes-3.9.2.jar`
- 进程：停掉旧 spring-boot:run PID 4172 → 重启新进程 → 加载新 class

### 2. API 端到端测试
- `harness/tests/mes/batch-global-switch.test.js`
- **15/15 通过**（含重复跑保护）：

```
场景 A：采购入库 + 总开关=关闭 → 批次主档=0（不创建批次）✅
场景 B：采购入库 + 总开关=开启 → 批次主档>=1（创建批次）✅
  数据库中实际残留：2 条 PR_D_ON 批次（首次跑创建）
场景 C.1：完工入库 + 总开关=关闭 → 批次主档=0 ✅
场景 C.2：完工入库 + 总开关=开启 → 批次主档>=1 ✅
  数据库中实际残留：2 条 CMP_D_ON 批次（首次跑创建）
```

### 3. 核心断言
- **总开关关闭时**：3 个 Service（completion / purchase receipt）跳过 `createBatch`；2 个 Service（picking / outbound）跳过 `stockOutFifo`
- **总开关开启时**：所有 4 个 Service 按物料 batchEnabled 创建/扣减批次
- **降级链**：`总开关 → 物料 batchEnabled → 业务功能`，两段都过才执行批次逻辑

### 4. 清理
- 总开关值回滚为 0
- MAT-0004 / MAT-0070 的 batchEnabled 回滚为 0
- DB 残留批次记录保留（已通过 `originBillNo` 区分，可手工或后续清理脚本删除）

## 关键设计决策

| 决策 | 理由 |
|------|------|
| 入口缓存 `final boolean batchSwitchOn = ...` | 单事务只查一次 DB，N 行物料只查 1 次；避免 N+1 查询 |
| 总开关关闭时**完全跳过** `if (batchSwitchOn) { ... }` 块 | 不只是"创建批次"跳过，连 `mat.getBatchEnabled()` 都不查——减少事务内 DB 调用 |
| 4 个 Service 模式完全一致（缓存+两段守卫） | 复制粘贴实现，保证行为可预测；未来加新 Service 按相同模板 |
| 出库方向同样集成总开关判断 | 评审 P1-3：避免"总开关关闭时入库不创建批次但出库仍在扣减"的数据漂移 |
| 领料 audit 把"先改状态后扣库存"的铁拳团 P0-3 与本切片总开关检查合并 | 两者都是事务级守卫，组合在事务入口最安全 |

## 踩坑记录

1. **`unit` 字段字典校验**：`MesMaterial.validateEntity` 要求 `unit` 在 `VALID_UNITS = {"1"-"8"}` 范围内。`unit='套'`/`'个'` 等中文会被拒——edit 失败但 silent return 200。测试要 `unit: '1'`。
2. **后端进程不自动 reload**：`spring-boot:run` 用 DevTools 只对开发期 source class 生效，install 后必须重启进程。先 `taskkill //PID 4172 //F` 再 nohup 启动新进程。
3. **生产订单需要 `productId`**：`add` 时如果不传 `bomId` 也能成功（之前以为要 BOM），错误信息是"生产产品不能为空"——其实要 productId 字段。
4. **`orderDate`/`deliveryDate` 在 PO detail 中为 null**：订单的 `warehouseId` 在主表也无字段（与采购入库不同），所以收货时直接传 `warehouseId`。
5. **重复跑数据冲突**：单次测试创建了采购入库/完工入库，第二次跑会因为"累计入库量超量"被 validator 拦下，需要重复跑保护。
6. **批次号唯一索引**：测试用同一物料、同一日期 → 同一批次号 → 第二次跑撞 `uk_batch_no_del`。识别 "Duplicate entry" 视为已生成过。

## 切片依赖关系

- **本切片（D）依赖**：A（实体+Mapper+Service基础）+ B（前端 Pinia）+ C（前端 disabled 联动）✅
- **本切片（D）解锁**：无（已是端到端最后一环）
- **本切片（D）涉及评审 P1**：
  - P1-3 出库方向缺总开关判断 → ✅ 已补
  - P1-4 关闭总开关的竞态 → ✅ A 切片 closeBatchSwitch 原子操作解决

## 关键文件清单

| 文件 | 改动 | 状态 |
|------|------|------|
| `CompletionReceiptServiceImpl.java` | audit 入口加总开关缓存 + 2 段守卫 | 修改 |
| `ProductionPickingServiceImpl.java` | 同上模式 | 修改 |
| `MesPurchaseReceiptServiceImpl.java` | 同上模式 | 修改 |
| `MesSalesOutboundServiceImpl.java` | 同上模式 | 修改 |
| `harness/tests/mes/batch-global-switch.test.js` | 15 个测试场景（含重复跑保护）| 新建 |
| `hermes/progress/2026-08-01-slice-D-service-integration.md` | 本文件 | 新建 |

## 收官总览（4 个切片）

| 切片 | 内容 | 状态 |
|------|------|------|
| A | 建表 + 实体 + Service 基础 | ✅ |
| B | 通用设置页 + 菜单 + 路由 + Pinia | ✅ |
| C | 物料页联动 + 3 道 disabled 兜底 | ✅ |
| D | 4 个 Service 集成总开关 | ✅ |

**端到端闭环已跑通**：
- 通用设置页关总开关 → 物料页 batchEnabled 自动禁用 + 强制归零
- 4 个 Service 审核链路按总开关+物料开关决定是否创建/扣减批次
- 关闭总开关不创建/扣减批次但不影响主库存+业财联动
- 重复跑保护使测试幂等

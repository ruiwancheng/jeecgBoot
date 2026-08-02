# 评审输入：生产批次总开关 + 物料级开关联动 实施计划

## 背景

用户做 JeecgBoot MES 项目时，业务方反馈"生产批次管理"功能缺少系统级总开关，导致：
- 物料档案已能勾选"启用批次管理"，但缺少顶层管控
- 已勾选物料的业务数据（批次库存/进行中批次）会形成孤儿数据
- 出库场景逻辑漏洞：总开关关闭时入库不创建批次，但出库时扣减逻辑会让数据漂移

业务方要求两层开关：
- **系统级（总开关）**：基础设置 → 通用设置 → 生产批次管理开关
- **物料级**：物料管理 → 物料档案 → 启用批次管理开关

降级链：总开关关闭 → 物料级禁用 → 业务功能失效（不创建批次）

## 草案：完整实施计划

### 策略判定

- **类型**：策略 1：纯新增（`project-mes/` 下新建 `system` 模块）
- **涉及标品**：无（MesMenuRegistry 已存在的 `mes_basic` 文件夹下挂新菜单）
- **改动标品风险**：无

### 文件清单

**后端新增（7 个）：**
- `system/entity/MesGlobalSwitch.java`
- `system/controller/MesGlobalSwitchController.java`
- `system/service/IMesGlobalSwitchService.java`
- `system/service/impl/MesGlobalSwitchServiceImpl.java`（含 checkCanClose 3 层检查）
- `system/mapper/MesGlobalSwitchMapper.java`
- `resources/mapper/mes/MesGlobalSwitchMapper.xml`
- `db/V8.0.2__mes_global_switch.sql`（建表 + 种子）

**后端修改（5 个）：**
- 4 个 Service：`CompletionReceiptServiceImpl`/`ProductionPickingServiceImpl`/`MesPurchaseReceiptServiceImpl`/`MesSalesOutboundServiceImpl`（补"总开关关闭则不创建批次"判断）
- `config/init/MesMenuRegistry.java`（注册【基础设置 → 通用设置】菜单）

**前端新增（3 个）：**
- `views/project/mes/basic/commonSetting/index.vue`
- `views/project/mes/basic/commonSetting/commonSetting.data.ts`
- `api/project/mes/system/commonSetting.api.ts`

**前端修改（2 个）：**
- `views/project/mes/basic/material/material.data.ts`（formSchema 加 batchEnabled + 读总开关决定 disabled）
- `views/project/mes/basic/material/index.vue`（加载总开关状态）

### 9 个任务步骤

1. **建表**：`c_mes_global_switch` (key-value 结构) + 种子数据 `mes_batch_enabled=0`
2. **Entity + Mapper**（不含业务逻辑）
3. **Service + checkCanClose 3 层检查**：
   - L1：批次库存表（`mes_batch_inventory WHERE qty > 0`）
   - L2：进行中批次（`mes_batch_master WHERE status='IN_PROGRESS'`）
   - L3：未完结业务单据（`mes_completion_receipt WHERE batch_id IS NOT NULL AND status != 'COMPLETED'`，关联 4 个业务表）
4. **Controller**：list/save/closeWithCheck（关闭前调 checkCanClose，返回结构化 CloseCheckResult）
5. **注册菜单**：`MesMenuRegistry.java` mes_basic 下新增 `mes_basic_commonSetting`
6. **前端通用设置页**：BasicTable 列出所有开关，开关组件绑定；关闭时弹窗显示检查清单
7. **前端物料联动**：`material.data.ts` formSchema 加 `batchEnabled` 字段 + 用 window 全局变量读总开关状态决定 disabled
8. **4 个 Service 补总开关判断**：每个 Service 注入 `IMesGlobalSwitchService`，在创建批次前调 `isEnabled("mes_batch_enabled")`
9. **E2E 集成测试**：9 个场景（默认关闭/禁用/开启/可用/默认未勾选/3 种入库组合/L1 拦截/清理后关闭）

### 切片对应

| 切片 | 对应步骤 | 风险 |
|------|---------|:--:|
| 1 | 步骤 1（建表） | 中 |
| 2 | 步骤 2（Entity/Mapper） | 中 |
| 3 | 步骤 3（Service + checkCanClose） | 高 |
| 4 | 步骤 4（Controller） | 中 |
| 5 | 步骤 5（注册菜单） | 低 |
| 6 | 步骤 6（前端通用设置页） | 中 |
| 7 | 步骤 7（前端物料联动） | 中 |
| 8 | 步骤 8（4 个 Service 补总开关判断） | 高 |
| 9 | 步骤 9（E2E 集成测试） | 高 |

## 已查证项

- ✅ MesMenuRegistry 现有菜单结构（基础设置已有 mes_basic，sortNo=10.0）
- ✅ MesMenuDefinition 模板：folder/leaf + addPerms 模式
- ✅ 后端 MesMaterial.batchEnabled 字段已存在（Entity + SQL 迁移 V8.0.1）
- ✅ 现有 4 个 Service 已引用 `mat.getBatchEnabled()` 判断（入库场景）
- ✅ 4 个 Service 文件路径已知：
  - `manufacturing/completion/service/impl/CompletionReceiptServiceImpl.java`
  - `manufacturing/picking/service/impl/ProductionPickingServiceImpl.java`
  - `purchase/receipt/service/impl/MesPurchaseReceiptServiceImpl.java`
  - `sales/service/impl/MesSalesOutboundServiceImpl.java`
- ✅ commonSetting.api.ts 的 getAll 接口模式（参考 system/user.api.ts）

## 待评审问题

1. **L1/L2/L3 三层检查的 SQL 准确性**：
   - mes_batch_inventory 表名、qty 字段是否准确？
   - IN_PROGRESS 状态值是否正确？（其他状态可能有 FINISHED/CANCELLED/ACTIVE）
   - L3 检查只列了 mes_completion_receipt 表，其他 3 个业务表（领料/采购入库/销售出库）需要一起检查吗？

2. **4 个 Service 改造完整性**：
   - 现有 Service 已有的 `mat.getBatchEnabled()` 判断只覆盖"入库创建批次"场景
   - "出库扣减批次库存"的 Service 是否也需要补总开关判断？（避免总开关关闭时还在扣减）

3. **前端用 window 全局变量传递总开关状态**：
   - 是否合理？还是应该用 provide/inject 或 pinia？
   - 多 tab 打开时状态不同步怎么办？

4. **Controller 的 `closeWithCheck` 设计**：
   - 返回 200 + errors 非空是否符合项目现有 REST 风格？
   - 还是应该用 HTTP 400 + 详细错误？

5. **9 个切片粒度是否合适**：
   - 步骤 1+2 合并（建表+Entity）是否合理？
   - 步骤 6+7 合并（前端通用设置+物料联动）是否合理？

6. **L3 检查的覆盖度**：
   - 4 个业务表都要查？
   - "未完结"的判断标准是 status='IN_PROGRESS' 还是其他？
   - 如果某个业务表没有 batch_id 字段怎么办？

7. **总开关关闭后再次开启**：
   - 之前已勾选物料的勾选状态会保留吗？
   - 数据已清空（批次库存=0）的"已完结"批次会被忽略吗？

8. **菜单注册时机**：
   - MesMenuRegistry 是应用启动时缓存的吗？
   - 新增菜单需要重启后端吗？

## 风险评估（草案中已列）

| 风险 | 等级 |
|------|:--:|
| L3 检查的关联单据表名/状态字段不准确 | 中 |
| 前端 window 全局变量在 SSR 下失效 | 低 |
| 总开关状态不实时刷新 | 中 |
| 现有 4 个 Service 漏改一个 | 高 |
| mes_material.batch_enabled 字段已存在但前端 formSchema 漏配 | 低 |
| 菜单注册后 SQL 未提交导致菜单不显示 | 低 |

## 期望评审产物

请按 orca-review 技能的标准评审视角（plan 阶段 = 架构/实施可行性）输出：

- 文件清单是否完整？
- 策略判定是否正确？
- 依赖查证是否覆盖 5 项（权限/SQL/组件/字典/父菜单）？
- 是否有更优策略（能用已有模式就不要新造轮子）？
- 是否有高风险步骤（改 Mapper SQL、改状态机）？
- 是否所有步骤都有具体文件路径和操作，而非 TODO/TBD？
- 9 个切片粒度是否合适？
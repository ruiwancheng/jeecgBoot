# 记忆卡片 — P0-1~P0-5 批次管理修复任务

> 主会话（协调者）派发前的状态快照。工人端 pi 必须读完本卡片后再开始执行。

---

## 当前阶段

`plan`（即将进入 implement）

## 行为指令

按 v4.0 10 步执行：0 大任务切片（5 P0 = 5 切片）→ 1 brainstorm → 2 plan → 3 orca-review（独立评审）→ 4 实现 → 5 verify → 6 分级测试（全量）→ 7 收尾自检 → 8 commit+push → 9 /done → 10 worker_done

## 任务上下文

### 阻塞原因（必读）

**tiequan 2026-07-31 批次管理审计**（10 视角，5/5 P0 共识）发现 5 个致命 P0：

| # | 共识 | 问题 | 文件 | 行号 |
|:--:|:--:|------|------|:--:|
| **P0-1** | 6/10 | 批次号取号 count+1 无锁，并发必发重号 | `MesBatchServiceImpl.java` | 35 |
| **P0-2** | 5/10 | MesBatchLedgerMapper 接口方法无 SQL 实现，运行时 BindingException | `MesBatchLedgerMapper.java` | 14, 19 |
| **P0-3** | 4/10 | 生产领料先扣库存再改状态 = 幻扣库存 | `ProductionPickingServiceImpl.java` | 127-141 |
| **P0-4** | 3/10 | ledger.api.ts 缺 getExportUrl = 前端运行时错误 | `ledger.api.ts` | - |
| **P0-5** | 3/10 | stockOutFifo 返回值被调用方丢弃 = 销货成本丢失 | `MesSalesOutboundServiceImpl.java` | 133; `ProductionPickingServiceImpl.java` | 132 |

### 已排除方向（避免重蹈覆辙）

- ❌ 不要合并到 mes-purchase 的工单（这是 mes-batch 独立问题）
- ❌ 不要用 uk_batch_no_del 唯一索引"绕开"重号（P1-1 修复方向，不是 P0-1）
- ❌ 不要改前端 UI（前端无 P0，全部是后端 + API）

### 关键决策（已锁定）

1. **P0-1 用数据库原子方案**：用 `INSERT ... SELECT ... WHERE NOT EXISTS` 或 sequence 表，避免应用层锁
2. **P0-2 严格按接口名补 XML SQL**：先看 mapper.java 接口定义，再补同名 mapper.xml
3. **P0-3 状态机顺序修正**：先改状态后扣库存；或加 `@Transactional` 内的 try-catch 回滚
4. **P0-4 模仿其他 api.ts**：参考 `harness/tests/mes/` 现有 .api.ts 的 getExportUrl 写法
5. **P0-5 接返回值并落库**：调用方接 stockOutFifo 返回的批次出库成本，存到 MesSalesOutboundItem.unitCost

### 风险等级

🔴 **最高**（数据一致性 / 资损 / 并发安全）

- 涉及：Entity / Mapper / Service / Controller / 前端 API
- 分级测试：**全量**（compile + test-api + test-e2e + test-all + 视觉验证）
- orca-review：**强制**（Java/SQL/Vue 任何改动都必评）

## 下一步（具体文件路径）

### 切片 1: P0-1（批次号并发安全）
- 文件：`jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/batch/service/impl/MesBatchServiceImpl.java:35`
- 依据：tiequan P0-1（共识 6/10）
- 修复方向：原子化批次号生成（sequence / 数据库唯一约束）

### 切片 2: P0-2（Mapper 接口缺 SQL）
- 文件：`jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/batch/mapper/MesBatchLedgerMapper.java:14,19`
- 配套 XML：`MesBatchLedgerMapper.xml`（若不存在则创建）
- 依据：tiequan P0-2（共识 5/10）

### 切片 3: P0-3（生产领料顺序错）
- 文件：`jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/manufacturing/picking/service/impl/ProductionPickingServiceImpl.java:127-141`
- 依据：tiequan P0-3（共识 4/10）

### 切片 4: P0-4（前端 API 缺导出）
- 文件：`jeecgboot-vue3/src/views/project/mes/batch/ledger.api.ts`
- 依据：tiequan P0-4（共识 3/10）
- 参考：`harness/tests/mes/` 现有 api.ts

### 切片 5: P0-5（销货成本丢失）
- 文件 1：`MesSalesOutboundServiceImpl.java:133`（接返回值）
- 文件 2：`ProductionPickingServiceImpl.java:132`（接返回值）
- 文件 3：`MesSalesOutboundItem.java`（加 unitCost 字段，如缺）
- 依据：tiequan P0-5（共识 3/10）

## 关键资源

- 审计报告：`hermes/tiequan/2026-07-31/mes-batch/01_风控总报告.md`（必读）
- progress.md 待办：`.claude/memory/progress.md`（含估时 5-8h）
- 客户端启动检查清单：`D:/笔记空间/低代码平台方案/00环境配置/环境与MCP启动检查清单.md`
- 批次管理调度流程：`D:/笔记空间/低代码平台方案/00环境配置/工程维护调度流程.md`

## 完成标志

- ✅ 5 个 P0 全部修复
- ✅ 每个 P0 commit 一个 fix（5 commits，便于回滚）
- ✅ 或合 1 个 commit（feat(mes-batch): P0 必修 5 项）— 由 orca-review 决定
- ✅ mvn compile 通过
- ✅ test-api + test-e2e + test-all 通过（全量）
- ✅ 视觉验证（如有 UI 改动）
- ✅ commit + push 到 main
- ✅ worker_done 含 commit hash

## 注意

- 🚫 禁止 mvn clean（devtools 自动热加载）
- 🚫 禁止 git push --force / git reset --hard
- ⚠️ 后端存活检测：`curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/jeecg-boot/sys/getEncryptedString`
- ⚠️ 任何 P0 修复必须先 orca-review，不能跳过
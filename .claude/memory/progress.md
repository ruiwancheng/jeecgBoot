# Harness 工程进度

## 会话收尾（2026-08-05 session-wrap #11）回归体系评估+本地全量回归+9 修复

**本次主要工作**：
- 回归体系 v0.2 后 7 轴评估（B+ → A）
- 本地完整回归 run 20260805-041046：20/23 pass (87%)
- 9 修复：N1（token wrapper 反模式 9 文件）/ N2（fixtures.js CI 跨平台）/ N3（typecheck 硬门控 742）/ N4（summary 三 job 硬门控）/ N5（e2e 删 --retries=1）/ N8（runner 端口探测）/ N9（schema init --force）/ TS-1（finance skipAddBtn）/ TS-2（other-stock-in 物料动态化）/ TS-3（gen-tests 端点契约驱动规则）
- 3 条 learnings 沉淀 + /evolve 反哺 testing.md / workflow.md
- B1-B4 人工复核：B1/B2/B3 = false_positive（同型 #8/#10/#7 历史误判），B4 = confirmed_bug（批次追溯抽屉）
- CI 跑通：N3+N4+N5+N9 真硬门控生效

**关键决策**：
- N8 不自动 kill：避免误杀用户开发用进程，warn + 留决策权
- N2 跨平台用 env-var 隔离（不动业务逻辑）：CI 幂等 + 时间戳后缀 + fixture 不持久化
- N3 硬门控基线 742 锁定：后续错误数下降要主动同步阈值
- TS-3 gen-tests 端点契约驱动：防止 B1-B3 同型误判再生

**累计修复**（保留）：
- 体系评级：B+ → A（87% → 90% harness-check）
- learnings 总数 111 → 113-3=110（3 条反哺到 rules）
- CI 闸门真正生效：N3 typecheck + N4 summary + N5 失败重试删除

**遗留**（暂缓）：
- B4 批次追溯 V10.0.3 抽屉前端 bug（前端工程师 0.5-1 人天）
- N6 注释示范硬编码 IP（1min）/ N7 fixtures inType 字典注释（1min）
- GAP-12 并发安全测试底座（2h）/ GAP-13 权限越权测试底座（1h）
- Unit 测试层底座（2-3h）
- audit-classification.md 速查表 12 天未更新（建议明日 B4 修完做审计）
- **P2 ⑤ 7 月 learnings archive 清理**（85 条 7 月 learnings 仍全部在主目录，.archived/ 空。建议明日与 harness 完整性审计一起做，1h+）

---
## 会话收尾（2026-08-02 session-wrap #10）

**本次主要工作**：
- P0 清理（TS6133 1025 处）→ 脚本 bug 破坏 297 文件 → **安全回退到 ee3bc37**（Batch 1-11 稳定点）
- 3 条 learnings 沉淀（脚本安全 / TS noUnusedLocals / vue-tsc allowJs）
- `/evolve` 跨多批：8 月 17 条 + 7 月 17 条 learnings 合并到规则（16 个规则文件，63% 引用率）
- Revert 远程的 P0 清理 commits（ddd3f21 + eaafe98）

**关键决策**：
- **P0 清理回退**：脚本破坏文件 > 修复收益，立即 git reset --hard 是安全网
- **`_` 前缀无效**：TS noUnusedLocals 不支持（仅 ESLint 支持），直接删除或 `@ts-expect-error`
- **`/evolve` 分批**：每批 ≤20 条，避免单次 commit 太大

**累计修复**（保留）：
- 综合质量 100/100 GO
- TS 错误 1810 → 742（净修 408 个，开启 strict 检查后）
- API 测试 12/12 PASS，E2E 17/20，冒烟 4/4

**遗留**（暂缓）：
- 1025 个 TS6133 历史遗留（按 learnings 暂不做）
- 38 条 7 月 learnings 未进规则（DB/SQL、Java、前端、工作流、环境、其他）
- P0 批次管理（行锁 + FIFO + warehouse_id 冲突）：5-8h 估时

## 工作流阶段追踪

| 字段 | 值 | 说明 |
|------|-----|------|
| phase | idle | 测试体系v2+黄金模板体系交付；盘点单4bug待修（用户明天试新流程） |
| last_verify | 2026-07-29 | 两轮全量零失败+E2E 12/12+Gallery控件12/12 |
| last_test | 2026-07-29 | 链路18/18+16/16，API 124+用例，模板变体验收零占位符 |
| pending_step | 盘点单4bug修复 | 显示ID/账面取值/审核未生效/明细过多（用新标准修+补E2E完整流） |
| shelved | DB密码环境变量化 / PD-DVST-001残留 / purchase链路排期 | 见下 |
| shelved | DB密码硬编码环境变量化 | jeecg-codegen/jeecg-onlchart 技能 5 处 -uroot -proot（P1低危，用户决定暂搁） |
| shelved | PD-DVST-001 测试盘点单残留 | 已审核无红冲接口，用户联系管理员DB手工删（SQL已给）；V2考虑加"作废"状态 |

## 会话收尾（2026-08-02 session-wrap #7）
- /delegate 3 轮调优：agent 统一 pi、worker 工作流对齐 v4.0、preamble 加 build/push 钩子
- auto-delegate.sh 脚本（拓扑序+git 兜底+僵死重派）
- 3 个新命令：/vue-audit（黄金模板 UX 审计 14 项）、/vue-migrate（半自动改造）、post-merge-check.sh（git pull 自动 verify）
- deploy-quality-gate.md / debugging.md / code-style.md 3 处规则反哺
- 5 条 learnings 沉淀：V8 漏 commit / Vue SFC parser 行号误导 / m2 缓存 / update-begin 不对账 / 部署重置状态
- 重大修复：服务端部署 8 次失败 → 排查 4 小时 → 根因 5 个 untracked 文件 + m2 缓存 → commit + 推送后部署成功
- 删除 MesSalesOutboundServiceImpl L336 重复 update-end（4 年历史 bug 1 行修复）
- L2 验证 V10.0.0 shelfLife / unitPrice / expiryDate / taxRate 字段全部 API 透出正常
- learnings 累计 96 条（今日 +5）

## 会话收尾（2026-07-29 session-wrap #6）
- /business-description 命令+技能落地：按需翻译技术语言→业务语言，双文件架构符合 skill-command-boundary
- /strict 深度探索→判定不可行回退：AI监督AI是死循环，结果验证>过程验证（新 insight 写入 learnings + 关键规则第5条）
- orca-review 流程修复：必须先 terminal list 查热 Claude 终端复用，不可直接 create（新 learning）
- 全闭环：/learn → /auto-learn → /evolve，learnings +2，反哺 frontend.md/debugging.md/CLAUDE.md 4处规则
- learnings 累计 72 活跃 + 24 归档

## 会话收尾（2026-07-28 session-wrap #4）
- 方案B+A+闭环：其它入库成本联动移动平均+台账差异列，/verify 全场景过→提交a33628a→部署→deploy-verify PASS
- 第11步验收：mes_admin 非admin账号接口权限 5/5 OK（本地+服务器）
- 清理僵尸命令：/test-loop 删除（项目无JUnit/Vitest套件，纯模板占位）
- harness 测试盘点：/test-api 实测能跑(14用例)，/test-e2e 缺依赖，/gen-tests 覆盖式慎用
- E2E 环境修复：harness npm ci + playwright install chromium
- /test-all mes 其它入库：新建 API 9用例+E2E 1用例；发现服务器前端旧版（bundle grep 铁证）→重新部署后全绿
- E2E 登录公共化：helpers/auth.ts 双层包装注入；顺手修复3老用例（checkbox/确 认空格/脆弱500断言）→全量 12/12
- /update-graph：图谱 25436节点/161772边，基线 e5061fb
- learnings +3：token双层包装、antd-playwright六坑、bundle grep部署验证法

## 会话收尾（2026-07-28 session-wrap #3）
- 死循环排查：DeepSeek代理空回复循环（非harness问题），顺带修复6个钩子协议问题（exit1→2/stderr/additionalContext/stub过滤/GBK/PIPESTATUS/true≠True）
- python3 stub 全链清理：4钩子+11处skill文档（含jimubi 13处三级探测链）+compat-check防回归规则#13
- pre-commit-check：WARNINGS累加器+裸echo发射（8处提醒可达）+L52阻断抹除bug+║n字面量bug
- Orca误报排查：jsonl时间线取证定位python3 stub，修复+清除preview泄漏
- 评审P1/P2清零：nul/gitignore/CLAUDE.md断链已修复，methodology-index+harness-check清单同步
- 自主学习闭环：/learn×3 + /auto-learn + 固化 hook-authoring.md 规则
- Harness使用指南（笔记空间）补自主学习进化场景
- learnings 累计 64 活跃(+7)+24归档，规则 14+1，harness 健康度：hooks语法/MEMORY链接/settings 全过

## 会话收尾（2026-07-24 session-wrap #2）
- /delegate 工作流三轮迭代修复：orca-review强制触发+verify不卡死+worker_done必发
- /new-terminal 命令修复：记忆卡片加入会话上下文 + terminal send→--inject注入
- /cleanup-context 模板重构
- 采购模块增强：明细子表展开(3模块) + 入库单明细自动加载 + 审核按钮 + 仓库URL修复 + 关联采购订单编号查询
- 部署事故修复：MesCustomerController方法冲突
- learnings 累计 73 条(+4)，规则覆盖率 100%
- harness 健康度 40/40
- 待用户手工验证：16条测试用例（笔记空间/03测试/）

## 历史状态（2026-07-19）
- 活跃项目：MES
- Phase 2 Step 1 + Step 2 完成
- 4个业务模块全部完成审计+库存联动

## 本次完成（2026-07-18~19）

### Step 1 补课
- 7个状态流转API + 6列金额字段 + 价格自动带出
- 前端批量操作栏（checkbox勾选+顶部按钮）

### Step 2 库存闭环
- 新建库存基础设施（实体/Mapper/Service，FOR UPDATE+UPSERT+台账）
- 4模块集成：销售出库/采购收货/生产领料/完工入库 audit端点+库存联动
- 铁拳团审计 → 3P0修复

### 工程规范
- docs/迁移到hermes/，补建INDEX.md，规范覆盖率100%
- harness-check自检同步，速查表追加新模式

## 待推进
- Step 3: 会计科目+应收应付+凭证生成
- 前端列表totalAmount列展示

## 经验记录
- 2026-07-18: calcTotal必须在save之前调用，否则totalAmount不持久化
- 2026-07-18: useListPage的rowSelection需tableProps+BasicTable prop双配置
- 2026-07-19: auditWithGuard必须先于stockOut执行（先改状态再扣库存）


## 会话收尾（2026-07-28 session-wrap #4）
- V9.8.0 其它出入库：brainstorm→plan→双轮orca评审(8+11遗漏全采纳)→22文件→curl全链路实测→/visual-check→部署→deploy-verify PASS
- 指南重写：交付主线12步落地（笔记空间 Harness使用指南.md）
- /verify 证据缺失升级为硬阻断（+--no-verify逃生门+netstat -ano修复——该门控Windows上从未生效）
- learnings +2: netstat-tlnp静默死亡 / HTTP200包404
- 待办：明日非admin账号验证→通知客户

## 会话收尾（2026-07-30 session-wrap #7）
- 黄金模板对齐第1弹：其它出入库（入库+出库）8前端文件，10 模式补齐模式8 Alert（库存减少/增加文案）+ 状态tag颜色
- bug修复：其它出库audit未按物料当前movingAvgCost锁定金额→账实偏差 17.78；audit()强制读取+持久化锁定，unaudit 红冲用同一锁定值
- 领域建模首次建立：CONTEXT-MAP.md + stock/CONTEXT.md v1.3（27术语，3次修订）+ ADR 0001（出库金额锁定）
- 黄金模板对齐第2弹：销售链路（订单/发货单/出库）14文件（13+shared/statusColor.ts），三模块分表状态颜色映射+Alert响应式文案（_dictText fallback ID）+ 页面间跳转3个
- 评审5项调整全采纳：searchForm补下拉/Alert用响应式数据/分模块映射表/保留3个列表跳转（去掉2个详情回溯）/加shared工具
- 全闭环：/learn → /auto-learn → /evolve，learnings +2，反哺 frontend.md 字典章节+ audit-classification.md 速查表 (+1 行)
- git push：6 commit 已上 origin main

## 会话收尾（2026-07-31 session-wrap #8）
- 黄金模板对齐第3弹：采购链路（申请/订单/收货）16文件（13前端改+1新建shared+2后端Entity补@Dict）
- 评审7项调整全采纳：2字段补@Dict(阻塞#1)/order 4部分到货cyan/修复dictCode错误/补状态下拉/保留3跳转/补rowSelection+批量审核
- 状态机发现：status=6"已关闭"是正常业务终态（green），与销售订单对称——避免用default（灰）误表异常
- 领域建模首次建立采购子域：CONTEXT.md 14术语+3套状态机表+业务对偶（入库重算vs出库不重算）
- 跨链路@Dict一致性扫描learning：销售链路4字段全有@Dict、采购链路2字段漏掉——黄金模板对齐前必做
- /learn + /evolve：audit-classification.md 速查表 +1 行（38 行）
- 全闭环：3 commit + 1 evolve commit + 1 learning commit，全部推送 origin main

## 2026-07-31 Phase 3 部分进度（待续）
- ✅ 完工入库集成：material.batch_enabled=1 时强制创建批次
- ⏳ 采购收货集成：可选创建批次（明天续）
- ⏳ 生产领料集成：选批次出库（明天续）
- ⏳ 销售出库集成：选批次出库（明天续）
- ⏳ Phase 3 整体验证（明天续）

## 待办 (pending-items)
- **2026-07-31** 采购收货集成批次（material.batch_enabled=1 时 createBatch）
- **2026-07-31** 生产领料集成批次（audit 时 stockOutFifo）
- **2026-07-31** 销售出库集成批次（audit 时 stockOutFifo + 不动 ADR 0001 锁定成本逻辑）
- **2026-07-31** Phase 3 完整回归测试（playwright + 集成）
- **2026-07-31** /learn 提取批次管理学习

## 历史关键决策（Phase 1+2 已完成）
- 4 制造子模块黄金模板对齐（bom/order/picking/completion，17 文件）
- 批次管理 4 子模块（master/inventory/ledger/traceability，41 文件）
- MesMenuRegistry 增 4 项菜单（mes_batch_*）
- 关键修正：warehouse_id NOT NULL 改为可空（批次创建时无仓库）

## 2026-07-31 批次管理 /verify 收尾
- 后端 100% 验证通过（14/14）
- 前端代码修复 + commit 完成（Vue 引号 bug）
- 前端 UI 视觉确认遗留（orca 浏览器卡 loading 30s+，未真正视觉确认）
- 截图 4 张存档 hermes/visual-baselines/batch-{master,inventory,ledger,traceability}/2026-07-30/
- 遗留原因：JeecgBoot 整体打包大 + orca 嵌入浏览器首次加载慢

## 待办 (pending-items)
- 2026-07-31 批次管理前端 4 页面 UI 视觉确认（orca 卡 loading 重新截图）

## 2026-07-31 session-wrap #9
- 批次管理 3 Phase 全部完成（4 制造子模块对齐 + 4 批次子模块建设 + 4 集成点整合）
- /verify: 后端 100% 通过（14/14），前端代码 + bug 修复完成，UI 视觉确认遗留（orca 卡 loading）
- /learn + /evolve: 新增 2 条 learning（Vue 引号 / 降级策略），反哺 frontend.md + audit-classification.md（39 行）
- /pre-commit-gate: 🟢 PASS

## 历史关键决策（批次管理全程）
- ADR 路径被评审报告（PASS），设计原则采纳
- 批次号生成规则：BT-{物料ID前6位}-{YYYYMMDD}{4位序号}
- 状态机：在用(1)/冻结(2)/已耗尽(3)/过期(4)；过期用 red
- 降级策略：物料 batch_enabled=0 不创建批次（防数据库膨胀）
- 不动 ADR 0001：销售出库仍按物料移动平均成本锁定，批次链路独立
- Phase 3 关键 bugfix: warehouse_id NOT NULL 改为可空 / receivableService.save try-catch 保护

## 待办 (pending-items)
- **2026-07-31** 批次管理前端 4 页面 UI 视觉确认（orca 卡 loading 重新截图）
- **2026-07-31** Phase 3 完整回归测试（playwright + 集成端到端）

## 2026-07-31 Hermes 终审（tiequan-audit）
- Hermes（Orca Worker 派发，MiniMax-M3 引擎）完成 MES 批次管理完整优化审计
- 报告：hermes/reviews/2026-07-31/orca-review-mes-batch-management-final.md
- 整体判定：🟡 WARN
- 报告范围：66 文件，+2415/-62

## P0 必修（跨 sprint 处理）
//update-begin---author:pi---date:2026-08-02---for: 校正 P0 状态——三条实际全部已修，progress.md 描述与代码不符---
- ~~P0-1: c_mes_batch_ledger.warehouse_id NULL 冲突~~ → ✅ 已修（V8.0.0 MesBatchServiceImpl createBatchWithManualNo 不再写 warehouse_id='' ledger，update-end L107-113 注释）
- ~~P0-2: MesBatchInventoryServiceImpl.stockIn 无 selectForUpdate~~ → ✅ 已修（V8.0.0.2 MesBatchInventoryServiceImpl:30 baseMapper.selectForUpdate(batchId, warehouseId)）
- ~~P0-3: FIFO 扣减无行锁~~ → ✅ 已修（V8.0.0.3 MesBatchInventoryServiceImpl:61 baseMapper.selectFifoByMaterialForUpdate(materialId, warehouseId)）

## P0 真实状态（commit c4bc65e 共识 5/5）
- ✅ P0-1：批次号并发 → MesMaterialMapper.selectByIdForUpdate 物料行锁 + 当日 LIKE+ORDER BY DESC+1
- ✅ P0-2：LedgerMapper 缺 SQL → @Select 注解补 selectByBatchId / selectByBiz
- ✅ P0-3：生产领料幻扣 → auditWithGuard 先状态后 stockOut
- ✅ P0-4：批次 4 页面缺 getExportUrl → 4 个 *.api.ts 已补，3 个 Controller 已加 /exportXls
- ✅ P0-5：批次成本落 c_mes_batch_ledger 决议（不再双源）
//update-end---author:pi---date:2026-08-02---for: 校正 P0 状态---

## P1 警告（下次迭代）
- P1-1: 批次号 count(*)+1 并发撞 uk_batch_no_del
- P1-2: 销售出库 audit 应收 customer_id NOT NULL 治本
- P1-3: 销售 cancel 不回滚批次库存
- P1-4: stockIn 创建新行主档同步（隐式 bug）

## P2 建议
- FIFO 索引 (material_id, warehouse_id, qty, create_time)
- warehouse_id NULL 防御校验
- master/index.vue 模板 status fallback 缺陷

## 待办 (pending-items)
- 2026-07-31 批次管理前端 4 页面 UI 视觉确认（orca 卡 loading 重新截图）
- 2026-07-31 Phase 3 完整回归测试
- **2026-07-31 [P0 必修] 批次库存行锁 + FIFO 行锁 + warehouse_id NULL 冲突（5-8h 估时）** ← **2026-08-02 校正：3 项全部已在 V8.0.0 阶段修完（commit c4bc65e），无未完 P0**
- **2026-07-31 [P1 警告] 批次号并发安全 + 应收治本 + 销售 cancel 回滚（8-12h 估时）**

## 2026-08-02 session #10 /evolve 批 3（数据库/SQL 11 条 learnings）

- 合并到 `code-style.md`（9 条）：dict-annotation-parity-check, dict-item-insert-ignore-duplicates, dict-text-only-on-list, jsearchselect-dict-format, mysql-hex-encoding-check, new-project-sql-gap, tablelogic-resurrection, docker-mysql-backtick, wsl-mysql-port-fight
- 合并到 `design.md`（1 条）：table-dict-bypasses-tablelogic
- 合并到 `boundary.md`（1 条）：claude-code-sandbox-git-push
- commit: 2934082
- 验证：`mvn compile` SUCCESS（9 模块），basic.test.js 14/14 通过
- /evolve 累计：批 1（12 条 8 月）+ 批 2（8 月 5 条）+ 批 3（11 条 7 月 DB/SQL）= 已合并 28 条 learnings 到规则

## 2026-08-02 22:11-22:33 /delegate v5 端到端首跑

- 任务：采购入库 Bug#1（选订单回填供应商）+ Bug#2（子表列宽）
- commit 链：17c9de7（worker 修）+ d71d03f（协调者回退冗余字段）
- v5 优化首跑成功：22 分钟端到端
- learning：`.claude/memory/learnings/2026-08-02-delegate-v5-end-to-end.md`
- 教训：轮询脚本 grep false alarm（应匹配 commit hash 而非 message）/ 协调者必须 /verify 兜底（worker 误读"可选"为"应该加"）

## 2026-08-02 22:00-23:00 采购入库页 Bug 修复 + 本地环境调试

### 本次完成
- 修复采购入库页 2 个 Bug（选订单回填供应商 + 子表列宽）—— commit 17c9de7
- 回退冗余 DTO orderNo 字段 —— commit d71d03f
- /delegate v5 优化首次端到端跑通 —— learning: 2026-08-02-delegate-v5-end-to-end
- 日期控件修复（先 a-date-picker getPopupContainer 3 次失败，5a142cb 改 input，28a7ed0 revert 回到 CompletionReceiptDrawer 一致写法）
- 本地环境调试：Vite 7 dev 模式日期 bug → pnpm build + preview 绕过；preview 加 proxy 到 localhost:8080
- 当前状态：所有日期控件正常

### 关键决策
- 保留 worker 修复（17c9de7）—— 用户确认选订单回填 + 列宽有效
- 5a142cb 改 input type="date" 用户实测失败（v-if isBatchOn 渲染问题）—— 28a7ed0 revert 回到 a-date-picker 写法（与 CompletionReceiptDrawer 一致）
- vite.config.ts preview proxy 配置保留 —— 本地开发必备

### 待手工操作
- commit vite.config.ts preview proxy 修复（待用户决定 commit message）
- /evolve 批 4（7 月剩余 ~17 条 learnings 诊断/审计/E2E 域）

# Harness 工程进度

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

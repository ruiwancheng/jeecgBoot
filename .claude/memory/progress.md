# Harness 工程进度

## 工作流阶段追踪

| 字段 | 值 | 说明 |
|------|-----|------|
| phase | harness-infra | 测试基础设施 + 工程规范建设 |
| last_verify | 2026-07-14 | 36/36 用例通过 |
| last_test | 2026-07-14 | 单元 36 + E2E 3 全部 |
| pending_step | 产品/物料模块 | PEND-001 折扣率机制待产品模块完成 |

## 当前状态
- 最后更新：2026-07-14
- 活跃项目：MES（mes）
- 仓库管理：负责人/联系电话/停用启用/权限/校验
- 库位管理：网格坐标模型（区域+通道+货架）/权限/校验

## 本次完成

### 前端测试基础设施
- MSW API 模拟层（server + warehouse handlers，8 个端点）
- 数据工厂（warehouse.ts，createWarehouse/createWarehouseList）
- Playwright Page Object Model（base.page + warehouse.page，15 个方法）
- 仓库模块 API 单元测试（11 用例）
- vitest + MSW 集成（setupFiles 自动启停）

### Harness 工程规范建设
- 新增 engineering-artifacts.md 规则（hermes/harness 目录结构+命名规范）
- CLAUDE.md 规则索引 8→15 条补全
- .gitignore 选择性追踪 INDEX.md 协调文件
- 入库 3 个技能 + 2 个审计规则 + 鹰眼团全量测试

### 前端测试扫描能力
- 新建 github_frontend_test_scan.py
- 核心发现：Vue + Ant Design Vue 全球无测试案例

### github-harness-scan Token 重跑
- 15 个新报告入库，piomin/claude-ai-spring-boot 对标 JeecgBoot

### 项目清理
- 删除 6 个临时文件，_app.config.js 加入 .gitignore

## 关键决策
- 库位退回网格坐标模型（放弃四级层级）
- 权限体系 perms 字段必须与 id 同值
- 部署流程不依赖 SQL 迁移自动执行
- GitHub 扫描必须带 Token（无 Token 限流不可行）
- Vue 测试生态无现成模式可抄，JeecgBoot 鹰眼团走在业界前沿
- Harness 规则是 AI 行为唯一控制面——所有客户端 AI 通过规则统一

## 待推进
- PEND-001：客户等级折扣率机制（依赖产品/物料模块）
- 客户模块补 @RequiresPermissions
- 库存模块建成后补删除/停用前的库存校验
- 产品/物料模块开发

## 经验记录
- 2026-07-14: Shiro 权限匹配 perms 列非 id 列
- 2026-07-14: a-form-item 不被 unplugin-vue-components 自动导入
- 2026-07-14: SQL 迁移不能依赖部署流程自动执行
- 2026-07-14: GitHub API 无 Token 限流 60次/小时，扫描必须带 Token
- 2026-07-14: .gitignore 目录级 ignore 后无法 ! 恢复内部文件，需逐层 un-ignore
- 2026-07-14: Vue 3 + Ant Design Vue 全球无测试案例，测试模式需自建

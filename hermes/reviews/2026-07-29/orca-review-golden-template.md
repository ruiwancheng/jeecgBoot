# Orca 评审：前端黄金模板体系 plan

> 评审对象：`hermes/reviews/2026-07-29/golden-template-review-input.md`
> 评审日期：2026-07-29
> 评审依据：现有 OtherInDrawer/OtherOutDrawer/StocktakeDrawer 的 10 个 UX 模式、MaterialSelectModal 组件、/new-module 生成命令、frontend.md 规范

---

## 一、通过 ✅

### 1.1 从 3 个手工页面提炼 10 个 UX 模式 — 诊断准确 ✅

对照 OtherInDrawer / OtherOutDrawer / StocktakeDrawer 三份源码，10 个模式全部可识别到具体行号：

| # | 模式 | OtherInDrawer | OtherOutDrawer | StocktakeDrawer |
|---|------|:--:|:--:|:--:|
| 1 | 搜索区字典下拉+ApiSelect | data.ts L18-19 | data.ts L18-19 | data.ts L18-19 |
| 2 | 复选框+批量审核(状态守卫) | index.vue L11-12 | index.vue L11-12 | — 盘点没有批量 |
| 3 | 明细子表展开行 | OtherInItemsSubTable | OtherOutItemsSubTable | — 盘点在 Drawer 内 |
| 4 | 抽屉+自动编码(bizCodeMap) | Drawer L53-54 | Drawer L53-54 | Drawer L74-75 |
| 5 | 明细行编辑 | Drawer L41-46 | Drawer L41-46 | Drawer L56-63 |
| 6 | 批量添加物料+成本预填 | Drawer L62-69 | Drawer L62-69 | — 盘点不需要 |
| 7 | 审核/反审核/删除状态机 | index.vue L67-72 | index.vue L67-72 | index.vue L36-41 |
| 8 | Alert 口径提示 | — | — | Drawer L4-5 (snapshotTime) |
| 9 | 差异红标高亮 | — | — | Drawer L23 (color:#f5222d) |
| 10 | popConfirm+操作列守卫 | index.vue L69 | index.vue L69 | index.vue L38 |

全部 10 个模式在源码中都有对应实现，提炼准确。✅

### 1.2 /new-page 命令 + 模板占位符生成 — 方向正确 ✅

当前 `/new-module` 只是一个**检查清单驱动的生成命令**（读模板文件→替换→输出文件清单），没有固化体验优化。`/new-page` 补充了"生成即含优化"的理念，是正确的方向。

### 1.3 Gallery 展示页 — 实用 ✅

让非技术人员能预览模板效果，不需要部署到后端就能看到 10 个模式的样子。这个想法在"售前演示 + 培训 + 决策"三个场景都有实际价值。

### 1.4 frontend.md 补 UI 基线清单 ✅

规则文件中固化 UX 检查清单，铁拳团审计时按清单查漏。这种"规则驱动"而非"记忆驱动"的做法正确。

---

## 二、遗漏 ⚠️

### 2.0（待评审问题逐答）

#### 问题 1：占位符规范 — 怎么定最稳？

**结论：用双花括号 + 统一前缀，限定 3 个核心占位符。不碰 case 变体。**

**为什么要避免 case 变体：**

```
{{MODULE}} → 全大写（包路径: project-mes）
{{Module}} → 大驼峰（类名: Stocktake）
{{module}} → 小驼峰（变量名: stocktake）
```

三套占位符看似灵活，实际带来了 3 个问题：
1. **误替换**：{{MODULE}} 是 "STOCK" → 把注释中的 "MODULE" 也换了
2. **占位符数量膨胀**：N 个占位符 × 3 种 case = 3N → 维护成本
3. **替换脚本复杂**：需要知道每个占位符的 case 语义

**最稳方案：5 个核心占位符，case 派生由脚本自动处理**

| 占位符 | 含义 | 示例替换 |
|--------|------|---------|
| `{{BIZ}}` | 业务名（kebab-case） | `transfer-in` |
| `{{BIZ_NAME}}` | 业务中文名 | `调拨入库` |
| `{{MOD}}` | 模块路径（目录层级） | `stock/transfer-in` |
| `{{PAGE_COMPONENT}}` | Vue 组件名（PascalCase） | `MesTransferIn` |
| `{{API_PREFIX}}` | 后端 API 前缀 | `/mes/stock/transferIn` |

**替换脚本自动派生 case 变体**（而非模板里写多套）：

```typescript
// Case 派生规则（统一在替换脚本中）
const derivations = {
  '{{PAGE_COMPONENT}}':        PascalCase,  // MesTransferIn
  '{{MENU_ID}}':               snake_case,  // mes_transfer_in
  '{{PERM_PREFIX}}':           colon_case,  // mes:transferIn:
  '{{TABLE_NAME}}':            snake_case,  // c_mes_transfer_in
  '{{BIZ_CODE_PREFIX}}':       UPPER_SNAKE, // TI
  '{{DICT_CODE_PREFIX}}':      snake_case,  // mes_transfer_in_type
};
```

模板文件里只用 5 个核心占位符，case 变体在脚本中派生。模板不包含 `{{Module}}`、`{{module}}`、`{{MODULE}}` 三种形式——只含 `{{PAGE_COMPONENT}}`，脚本将其转换为所需的 case。

**为什么 5 个够用：** 从 OtherIn/Out 的 5 个文件（index/Drawer/ItemsTable/api/data）统计，所有需要替换的位置都可以映射到这 5 个占位符或其派生。

**占位符命名约束：**
- 全大写 + 下划线分隔（`{{PAGE_COMPONENT}}` 而非 `{{PageComponent}}`）
- 因为模板是纯文本替换，占位符本身的外观与被替换内容无关——`{{BIZ}}` 本身不需要是 kebab-case，它是被替换的锚点
- 前缀区分用途：`BIZ_*` = 业务字段，`PAGE_*` = 前端组件名，`PERM_*` = 权限码

#### 问题 2：Gallery 纯前端假数据 vs 接真实 Demo 实体？

**结论：两层——核心组件用真实数据（读 `c_mes_material`），布局框架用假数据。**

**MaterialSelectModal 问题分析：**

查看源码 `MaterialSelectModal.vue`——它是一个**独立的 Modal 组件**，内部调 `queryMaterialList` API。如果 Gallery 页用它但后端连不上 → API 挂 → 弹窗打不开 → 展示失败。

但这恰恰是**Gallery 页应有的行为**——因为最终生成页面**真的要调这个 API**。如果弹窗依赖真实后端，用户点"选择物料"按钮时能看到真实的物料列表，而非 fake data。

**两层方案：**

| 层 | 内容 | 数据源 | 为什么 |
|----|------|--------|--------|
| **布局层**（列表页+搜索区+抽屉框架） | BasicTable、BasicForm、BasicDrawer 的展示 | 纯前端假数据 | 不依赖后端即可展示列/搜索框/抽屉布局 |
| **组件层**（MaterialSelectModal / JDictSelectTag / ApiSelect） | 弹窗、下拉、选择器 | **真实 API**（如果后端在线） | 这些是独立组件，调自己的 API 拿数据——Gallery 只是容器 |

**实现方式：**

Gallery 页本身是 `BasicTable` + 假数据的列表页。点击行打开 `Drawer` 时使用**实际的 Drawer 组件**（`OtherInDrawer.vue` 导入），但 drawer 内的 `items` 等动态数据用 `defineExpose` 的方式注入假数据。`MaterialSelectModal` 的 API 调用保留——如果后端在线，弹窗展示的物料列表是真实的；如果后端离线，弹窗显示"加载失败"（也是真实的用户体验）。

```
Gallery 页 = 
  ├─ 列表框架（假数据：columns + pagination_total=999）
  ├─ 搜索区（假数据：3 个下拉有默认选中值）
  ├─ 抽屉打开（真实 Drawer 组件 import）
  │   ├─ 主表字段（假数据注入到 setFieldsValue）
  │   └─ 明细子表（假数据注入到 items.value）
  ├─ MaterialSelectModal（真实组件 import，调真实 API）
  └─ 批量审核（假数据注入到 selectedRows）
```

**这不是"无后端依赖" vs "有后端依赖"的二元选择**——Gallery 可以**优雅降级**：有后端→展示真实交互；无后端→展示布局+假数据。前端组件本身就是真实代码的直接引用，Gallery 页的价值不在于"要不要后端"，而在于"能不能看到模板渲染后的样子"。

#### 问题 3：一个模板全包 vs 分单表版/主子表版？

**结论：分两个模板——单表版和主子表版。现有 `/new-module` 已经分了。**

理由：

| 模式 # | 单表版需要？ | 主子表版需要？ |
|---------|:--:|:--:|
| 1 搜索区字典+ApiSelect | ✅ | ✅ |
| 2 复选框+批量审核 | ✅ | ✅ |
| 3 明细子表展开行 | ❌ 单表无子表 | ✅ |
| 4 抽屉+自动编码 | ✅ | ✅ |
| 5 明细行编辑(物料+数量+单价) | ❌ | ✅ |
| 6 批量添加物料弹窗+成本预填 | ❌ | ✅ |
| 7 审核/反审核/删除状态机 | ✅ | ✅ |
| 8 Alert 口径提示 | 🟡 按需 | ✅ |
| 9 差异红标高亮 | ❌ | ✅（只算差值） |
| 10 popConfirm+操作列守卫 | ✅ | ✅ |

单表版 = 模式 1,2,4,7,10（5 个模式）
主子表版 = 全部 10 个

单表版不加载明细相关代码（更轻），主子表版全量加载。两个模板共用 `_shared` partial（搜索区/抽屉框架/编码接线/状态按钮），各自叠加特有模式。

**"简单页面被迫背重模式"的解决：** 单表版模板只含 5 个模式（不加载明细），用户生成代码后按需添加。
- 如果需求是"仓库管理" → 单表版 — 有搜索/复选框/状态按钮/编码 = 够了
- 如果需求是"调拨入库" → 主子表版 — 全量 10 个模式

#### 问题 4：模板放 `harness/templates/` vs `src/views/` 下？

**结论：放 `harness/templates/mes-doc-page/`，不放在 `src/views/`。**

理由：

1. **模板含占位符不能直接编译** — 放在 `src/` 下 TypeScript 编译会报错（`{{PAGE_COMPONENT}}` 不是有效的组件名）。勉强修复（`// @ts-nocheck` 或忽略编译）会污染构建流程。

2. **模板是源文件，不是构建产物也不是可运行代码** — `harness/` 专门收 AI 生成的一次性产物和模板，正合适。Gallery 页是**独立的可运行页面**（放在 `src/views/project/mes/dev/template-gallery/`），它 `import` 模板文件做展示，但不是直接 `import .vue` 文件——而是 `fetch()` 模板文件内容然后以纯文本展示（像代码段预览）。

3. **Gallery 展示页不 import 模板文件，而是 import 真实组件**：

```typescript
// Gallery.vue
import OtherInDrawer from '/@/views/project/mes/stock/other-in/OtherInDrawer.vue';  // 真实组件
// 模板文件内容用 fetch 获取后在 <pre><code> 中展示
const templateSource = await fetch('/harness/templates/mes-doc-page/drawer.vue.template').then(r => r.text());
```

Gallery 的核心价值是**用真实组件展示交互效果**——不是展示模板文件本身。模板文件是代码生成的源，Gallery 是代码生成的效果预览。

**两处代码：**
- `harness/templates/mes-doc-page/` — 模板源（含 `{{BIZ}}` 等占位符，`/new-page` 复制后替换）
- `src/views/project/mes/dev/template-gallery/` — Gallery 展示页（不含占位符，import 真实组件，演示数据硬编码在页面）

#### 问题 5：/new-page vs /new-module 的边界？

**结论：把 `/new-page` 的设计吞到 `/new-module` 中，不另建命令。**

| 维度 | 当前 /new-module | 改进后的 /new-module |
|------|:--:|------|
| 触发词 | "新建模块"、"创建模块" | 同上 + "新建页面"（别名） |
| 模板来源 | 手工记忆（单表=仓库/供应商，主子表=销售订单） | **黄金模板文件**（harness/templates/） |
| 前端生成 | 基本布局（无 UX 优化） | **10 模式内置**（列表页含批量审核、抽屉含编码接线、明细含物料选择+自动算金额） |
| 后端生成 | Entity+Mapper+Service+Controller | 不变 |
| SQL 生成 | 建表+字典+角色绑定 | 不变 + 自动计算编码规则注册 |

**为什么要合并：**

1. **避免命令混乱** — `/new-module` 和 `/new-page` 并存，用户不知道何时用哪个："我要加一个调拨入库功能——是 /new-module 还是 /new-page？"
2. **前端和后端从来不是分开的** — 新增一个业务页面必然需要后端实体（至少一个表）。`/new-page` 如果只生成前端 → 用户还要手动补后端 → 不如一个命令做全套
3. **单命令驱动策略选择** — `/new-module` 自动识别需求范围（单表 vs 主子表），然后选对应模板

**`/new-module` 输入改进后的体验：**
```
用户：/new-module stock transfer-in 调拨入库
AI：   分析需求 → 主子表类型
       从黄金模板生成：
         ✅ SQL: db/V9.x.0__mes_transfer_in.sql (建表+字典+编码)
         ✅ 后端: Entity×2/Mapper×2/Service×2/Controller×1
         ✅ 前端: index/Drawer/ItemsTable/api/data (10模式内置)
         ✅ 注册: MenuRegistry+bizCodeMap+路由+权限码
         ✅ 测试: API 业务流+E2E 业务流 (三件套)
```

`/new-module` 前端部分指向同一套黄金模板（单表版或主子表版），一处维护。`/new-page` 不作为独立命令存在——它是 `/new-module` 的增强版。

#### 问题 6：有没有遗漏？

**有。以下 3 个重要维度当前 plan 未提及：**

##### 遗漏 A：🔴 P1 — 模板版本演进与已生成页面的同步

模板改了（如增加第 11 个模式"导出按钮自动带筛选条件"），之前生成的 5 个页面需要手动同步。

**机制：**
- 模板文件头用注释记录版本号：`<!-- @template-version: 2.1.0 -->`
- 生成的页面头也记录：`<!-- @generated-from: harness/templates/mes-doc-page/master-detail.vue.template @version: 2.0.0 -->`
- 新增命令 `/diff-template`：对比所有生成页面的版本 vs 当前模板版本，输出差异摘要

| 页面 | 生成模板 | 生成版本 | 当前模板版本 | 状态 |
|------|---------|:--:|:--:|:--:|
| 其它入库 | master-detail | 2.0.0 | 2.1.0 | ⚠️ 模板已升级 |
| 盘点单 | master-detail | 2.1.0 | 2.1.0 | ✅ 最新 |

- **不自动更新已生成页面**（风险太大），但提供"升级指引"：列出模板在 2.0→2.1 之间的变更（diff），供人决策

##### 遗漏 B：🔴 P1 — i18n 国际化

当前 3 个实践页面（OtherIn/Out/Stocktake）**完全没有 i18n**。所有中文文本硬编码在模板中。JeecgBoot 平台有 `src/locales/lang/zh-CN/` + `en/` 两层国际化支持，但 MES 项目从未用过。

**建议：** 黄金模板**先用硬编码中文**（V1），不要求 i18n 完整覆盖。但：
- 在模板中标注出需要国际化的文本位置（注释标记 `<!-- i18n -->`）
- frontend.md 补一条"新增页面时无需 i18n，平台层统一处理，但文本存放到中文 locale 文件"

**为什么 V1 不追求 i18n：** MES 项目目前只有中文用户，i18n 过度设计会增加模板复杂度（每个标签都要变成 `{{ $t('xxx') }}`），对交付速度无益。

##### 遗漏 C：🟡 P2 — 权限码和菜单注册的自动化程度

当前 `/new-module` 只输出"需注册的菜单和权限码"清单，用户需要手动加到 `MesMenuRegistry.java` + `mes.ts` 路由。模板可以生成注册代码段，但需要人工粘贴。考虑：

- 模板输出时**直接操作注册文件**：读 `MesMenuRegistry.java` → 在正确位置插入新菜单代码块。
- 这需要模板了解 `MesMenuRegistry` 的结构（菜单分块注释：`// ==================== 仓储管理 ====================`），确定插入位置。
- 如果结构变（如新增一个分区），模板需要适配。

**建议：** V1 先不自动注册（人工粘贴），但模板生成的注册代码段用明确的注释包围（`// ==== GENERATED: transfer-in ====`），MesMenuRegistry 中的插入位置自动检测。

##### 遗漏 D：🟡 P3 — 单表版模板的"向主子表升级"路径

用户开始创建了一个单表页面（仓库管理），后来需求变→需要加明细（物料清单）。没有从单表→主子表的升级指引。

**建议：** 模板目录加一个 `upgrade-guide.md`，记录"单表版缺什么 vs 主子表版"的 diff。

---

## 三、建议 💡

### 3.1 模板文件结构

```
harness/templates/mes-doc-page/
  ├── _shared/                       # 两版共用 partial
  │   ├── search-schema.ts.template   # 搜索表单配置
  │   ├── code-hookup.ts.template     # 编码接线+getNextCode
  │   ├── status-actions.ts.template  # 审核/反审核按钮+popConfirm
  │   └── drawer-frame.ts.template    # BasicDrawer 框架骨架
  ├── single-table/                   # 单表版
  │   ├── index.vue.template
  │   ├── drawer.vue.template
  │   ├── api.ts.template
  │   └── data.ts.template
  ├── master-detail/                  # 主子表版（继承单表版 + 子表模式）
  │   ├── index.vue.template
  │   ├── drawer.vue.template
  │   ├── items-sub-table.vue.template
  │   ├── api.ts.template
  │   └── data.ts.template
  └── README.md                       # 占位符规范 + case 派生规则 + 版本号
```

### 3.2 模板命名约定

- `.vue.template`：Vue 单文件组件模板
- `.ts.template`：TypeScript 文件模板
- 占位符全部大写+下划线（`{{BIZ}}`、`{{PAGE_COMPONENT}}`）

### 3.3 Gallery 页的 10 个模式展示方式

Gallery 页 = 左侧菜单（10 个模式）+ 右侧展示区。点击模式 2「复选框+批量审核」→ 展示一个真实的列表页片段（`BasicTable` + 假数据 + 单选/多选状态切换）。

实现：
```vue
<!-- src/views/project/mes/dev/template-gallery/index.vue -->
<template>
  <a-layout>
    <a-layout-sider>
      <a-menu @click="selectMode">
        <a-menu-item v-for="m in modes" :key="m.id">{{ m.title }}</a-menu-item>
      </a-menu>
    </a-layout-sider>
    <a-layout-content>
      <component :is="currentDemo" />
    </a-layout-content>
  </a-layout>
</template>
```

10 个 demo 组件各自 import 真实组件（`OtherInDrawer`、`MaterialSelectModal`、`BasicForm` 等），用假数据填充。其中 `MaterialSelectModal` 调真实 API——这是预期行为（展示真实交互）。

### 3.4 frontend.md 补「单据页 UX 基线」内容

建议格式——不是罗列 10 个模式的名称，而是**可审计的检查清单**：

```markdown
## 单据页 UX 基线（新增单据页时逐项核对）

### 列表页
- [ ] 搜索栏有字典下拉（JDictSelectTag）+ 仓库下拉（ApiSelect）
- [ ] 复选框可用（rowSelection），批量审核/反审核按钮有状态守卫
- [ ] 操作列按钮按 status 动态显示（草稿=编辑+删除，已审核=空）

### 抽屉页
- [ ] 新增时自动获取编码（getNextCode + MES_BIZ_CODE），失败回退手工输入
- [ ] 明细行：物料选择（JMaterialSelect）+ 数量输入 + 单价输入 + 金额自动算
- [ ] 选物料时自动预填移动平均成本（onMaterialChange）
- [ ] 提交 confirmLoading，防止重复点击

### 主子表
- [ ] 子表有展开行组件（ItemsSubTable），列含物料名称/规格/数量/单价/金额
- [ ] 批量添加物料弹窗（MaterialSelectModal，mode="multiple"）

### 状态机
- [ ] 审核/反审核/删除有 popConfirm
- [ ] 已审核后编辑和删除按钮隐藏
```

### 3.5 黄金模板的验证标准

生成一个现有模块（如"其它入库"）的变体（如"调拨入库"），和手工写的 OtherIn 对比——模板生成的代码与手工写的差异应该是**只换占位符、不丢功能**。

验收标准：
1. `/new-module stock transfer-in 调拨入库` 生成全部文件
2. `mvn compile` + `pnpm build` 无报错
3. 生成的 Drawer 中 `MaterialSelectModal` 正常工作（依赖后端在线）
4. `MesMenuRegistry` 注册的菜单在系统菜单中可见
5. 列表页能打开、搜索能搜、复选框能选、批量审核能提交

---

## 评审总结

| 维度 | 结论 |
|------|------|
| 10 模式提炼准确性 | ✅ 全部 10 个在源码中可精确定位 |
| 占位符规范 | ⚠️ 需修正 — 5 个核心占位符 + case 派生由脚本处理（不写多套占位符） |
| Gallery 数据方案 | ⚠️ 分层 — 布局假数据 + 组件真实 API 调用（优雅降级） |
| 单模板 vs 两模板 | 分单表版/主子表版两个（5/10 模式），共用 _shared partial |
| 模板路径 | `harness/templates/mes-doc-page/` 不放在 src（占位符不可编译） |
| /new-page vs /new-module | **合并** — /new-module 升级吞掉 /new-page 设计，不另建命令 |
| 遗漏 | 3 个 P1（模板版本演进/权限注册自动化/i18n 策略）+ 3 个 P2-P3（升级路径/Gallery组件引用/验收标准） |

**总体判定：方向正确，10 个模式提炼准确。关键修正：5 个核心占位符 + 脚本 case 派生（非多套变体）、Gallery 两层数据（框架假数据+组件真 API）、/new-page 吞入 /new-module 避免命令混乱、补充模板版本演进 + 注册自动化 + i18n 策略 3 个遗漏维度。**

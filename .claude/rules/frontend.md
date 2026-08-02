---
name: frontend
description: 前端组件规范——表单、表格、路由、字典
glob: "**/*.{vue,ts}"
version: 1.0
---

# 前端组件规范

## 页面结构
- 列表页：`<BasicTable>` + `useListPage` Hook
- 详情/编辑：`BasicDrawer` + `BasicForm`
- 搜索：`searchFormSchema` 在 `.data.ts` 定义
- **Hook 配对：** `BasicDrawer` → `useDrawer()`，`BasicModal` → `useModal()`。混用会报 `setModalProps is not a function` 错误

## 表单
- 搜索区：3-4 字段一行（`span: 6`）
- 详情区：2 列布局
- 必填字段 `required: true`

## 字典
- 平台字典：`JDictSelectTag` + `dictCode`
- 表字典：`@Dict(dictTable, dicText, dicCode)`
- **`_dictText` 仅 list 接口带出**：JeecgBoot 平台的 DictAspect 字典填充切面只对 `*Controller.list` 这类分页查询生效；自定义 `*Service.queryWithItems` 走 MyBatis Plus `selectById`，绕过切面，不返回 `_dictText`。前端响应式关联文案（Drawer Alert 等）必须 fallback：`const ref = record.xId_dictText || record.xId;`。不相信 Claude 评审“自动带出”的结论，必须实测两个接口。← 2026-07-30 销售链路对齐踩坑

## 路由
- 一级菜单 `LAYOUT` + `redirect`
- 子页面懒加载 `() => import('/@/views/...')`
- 项目页面加前缀 `/project/{项目名}/`
- **新增 Vue 组件后必须重启 Vite**（`import.meta.glob` 缓存）
- **改后端代码 `mvn install` 永远不用 `-q`**——必须看到 `BUILD SUCCESS` 输出（`-q` 静默失败极坑）。改完同时按"诊断：改了代码后端没生效"流程核验 class mtime + 进程 PID
- **菜单 404 排查：** 先查 `sys_permission.is_route` 是否为 1。`is_route=0` 时前端不生成路由，直接返回 404。其次查 `parent_id` 是否指向正确的父菜单
- **静态路由 404 排查：** permissionGuard 登录后按后端菜单权限重建可访问路由表，**没有菜单支撑的静态路由（routes/modules 里注册了的）会被移除** → 新页面 404 第一怀疑菜单注册（MesMenuRegistry），不是路由本身（实证：2026-07-29 Gallery）

## 路由匹配
- 数据库菜单 url 和前端路由 path 必须一致
- **层级必须对应：** 数据库菜单中每一层 `component=layouts/default/index` 的父级，前端路由必须有一层 `component: LAYOUT` + `children` 对应。缺失中间层会报"路径不存在"404
- 新增 Vue 组件后必须重启 Vite（`import.meta.glob` 缓存）

## 组件常见坑

| 组件 | 问题 | 正确处理 |
|------|------|----------|
| `Tabs` / `TabPane` | `unplugin-vue-components` 不自动导入 `TabPane`，页面白屏 | 显式 `import { Tabs } from 'ant-design-vue'`，模板用 `<Tabs.TabPane>` |
| `Form.Item` / `a-form-item` | `unplugin-vue-components` 不自动导入子组件，**静默不渲染无报错** | 用纯 HTML `<span>`+`<a-select>` 替代，或显式 `import { Form } from 'ant-design-vue'` 用 `<Form.Item>` |
| `Switch` | 返回 `boolean`，后端 `Integer` 字段反序列化报错 | `componentProps: { checkedValue: 1, unCheckedValue: 0 }`，`defaultValue: 0` |
| `JSwitch` | `checkedValue/unCheckedValue` **不生效**——JSwitch 内部按 `props.options[0/1]` emit 值（默认 `['Y','N']`），传到后端 `Integer` 字段报 "Cannot deserialize String "Y"" | 用 `options: ['1','0']` + `labelOptions: ['是','否']`。同时列表 `customRender` 用 `Number(text) === 1` 防御性兼容字符串/数字（2026-08-01 物料页 batchEnabled 踩坑） |
| `DatePicker` | 返回 dayjs 对象，JSON 序列化后后端解析失败 | `componentProps: { valueFormat: 'YYYY-MM-DD HH:mm:ss' }` |
| `JSearchSelect` | 传 `dictTable/dictText/dictCode` 三个属性，下拉无数据 | 用 `dict: 'table,text,code'` 合写格式 |
| `JSearchSelect` + `dict="c_mes_*,text,value"` | 平台字典原始SQL不经MyBatis-Plus → 下拉数据与列表必不一致（del_flag未过滤、数据源未路由）| 改用 `ApiSelect` + 目标Controller的`/selectPage`端点。禁止在MES项目中使用表字典模式 |
| `useTable` | `immediate: false` 导致 Tab 内子表首次不加载数据 | 配合 `v-if` 判断父组件已传参后，设为 `immediate: true` |
| `BasicTable` rowSelection | 复选框列不显示，`useListPage` 内部不传递 rowSelection | 手动 `reactive` 创建 `rowSelection` 对象（含 `type:'checkbox'` + `onChange`），`selectedRowKeys` 用 `reactive` 非 `ref`，绑 `:rowSelection` 在 BasicTable 上 |
| `userStore.getUserInfo` | getter 是计算属性，加 `()` 静默失败返回空 | Pinia getters 作属性访问：`userStore.getUserInfo?.realname`，不加 `()` |

## 接口
- `defHttp.get/post/put/delete`
- DELETE 请求必须加 `{ joinParamsToUrl: true }`，否则参数在请求体，后端 `@RequestParam` 收不到
- **长文本接口必须 `successMessageMode:'none'`**：defHttp 全局拦截器对 `success && message` 自动弹顶部通栏横幅，长文本（审核摘要、批量结果）会向右溢出滚动。调用时加 `{ successMessageMode: 'none' }`，由页面自行展示。判断信号：顶部出现通栏长文本横幅=拦截器弹的，去 api.ts 加 'none'（实证：2026-07-29 盘点审核滚动）
- 路径枚举在 `.api.ts`

### 标准下拉函数（ApiSelect 专用，强制）

**强制要求**：新建基础模块的 `xxx.api.ts` 时，**必须**按以下模式补全 `queryXxxSelect` 函数，即使暂无页面引用。否则下游业务模块用 `ApiSelect` 引用时下拉会报 `SyntaxError: does not provide an export named 'queryXxxSelect'`。

**模板代码**（照搬 customer/warehouse 标准）：

```typescript
/** 下拉选择（ApiSelect专用，替代平台字典 c_mes_xxx） */
export async function queryXxxSelect(params?: any) {
  const res = await defHttp.get({ url: Api.selectPage, params });
  return res || [];
}
```

**5 行约束**：

- 函数名：`queryXxxSelect`（Xxx = 实体名 PascalCase，如 Material、Customer、Warehouse）
- 必须 `async function`（**禁止**箭头函数，与其他模块风格不一致）
- 参数：`params?: any`（ApiSelect 传 `keyword`/`pageNo`/`pageSize`）
- 必须 `return res || []`（兜底空数组，避免 ApiSelect 拿到 undefined 报错）
- 必须调用 `Api.selectPage`（已在 enum 中定义：`selectPage = '/mes/basic/xxx/selectPage'`）

**完整对照表**（保持一致）：

| 实体 | 函数 | 后端接口 | 前端导出位置 |
|------|------|---------|------------|
| 客户 | `queryCustomerSelect` | `/mes/customer/selectPage` | `basic/customer/customer.api.ts` |
| 仓库 | `queryWarehouseSelect` | `/mes/basic/warehouse/selectPage` | `basic/warehouse/warehouse.api.ts` |
| 供应商 | `querySupplierSelect` | `/mes/purchase/...` | `purchase/apply/apply.api.ts` |
| 科目 | `querySubjectSelect` | `/mes/finance/...` | `finance/subject/subject.api.ts` |
| 物料 | `queryMaterialSelect` | `/mes/basic/material/selectPage` | `basic/material/material.api.ts` |

**预防清单**（新建 `xxx.api.ts` 时）：

1. 复制 `customer.api.ts` 完整结构作为模板
2. 补全 CRUD（query/list/add/edit/delete）
3. **必须**补 `queryXxxSelect`（即使暂无页面引用）
4. 补 `getExportUrl` / `getImportUrl`（如需 Excel 导入导出）
5. 补 `saveOrUpdate` / `queryByIds`（批量操作辅助）

**调试信号**（前端报以下错误 100% 是 api.ts 漏写）：

- 控制台 `does not provide an export named 'queryXxxSelect'` → 立即补全
- `grep -rn "queryXxxSelect" src` 找不到导出但找到引用 → 漏写
- 后端已有 `selectPage` 接口但前端无对应函数 → 漏写

**实证**：2026-07-31 批次主档打开报错根因。`material.api.ts` 漏写 `queryMaterialSelect` 函数，导致 `master.data.ts` 和 `inventory.data.ts` 编译失败。补全 +7 行（含 update-begin/end 标记）即可修复。

## 单据自动编码（编码规则接线模式）

新单据页面需要自动编号时，按标准三步（来源：2026-07-21 编码规则绑定，10 个单据页已验证）：

1. **统一映射**：`basic/codeRule/bizCodeMap.ts` 的 `MES_BIZ_CODE` 常量加映射，禁止页面硬编码 `'SO'` 类字符串
2. **Drawer 接线**：`useDrawerInner` 内 `if (!unref(isUpdate))` 分支调 `getNextCode(MES_BIZ_CODE.XXX)` → `setFieldsValue({ code })`，外层 try/catch 静默回退手工输入（不阻塞开单）
3. **配套数据**：SQL 补规则（INSERT IGNORE 固定 id）+ 规则实体 `@Dict` 注解 + 字典 `mes_code_biz_type`

- **Vue 模板属性禁用半角引号**：写含引号的中文 Alert/文案时不能用 `message="点击"查看"按钮"`，会触发 Vite 编译错误 "Attribute name cannot contain U+0022 (")"。**用「」中文方括号或全角引号替代**（如 `message="点击「查看追溯」按钮"`）。判错信号：/verify 截 Playwright 截图卡 loading、`cat /tmp/jeecg-local-frontend.log | grep ERROR` 报 attribute 错误。← 2026-07-31 批次管理 traceability 模块踩坑

已知行为（设计取舍）：打开弹窗即占号，取消不归还 → 单号允许跳号。

## E2E 测试规范（来源：2026-07-28 harness E2E 体系建设）

### 登录注入（标准姿势，必须复用 helper）

JeecgBoot token 是**双层包装**，直接 `setItem('Access-Token'/'TOKEN__', token)` 无效（路由守卫读不到→跳登录页并清 token）：

```
localStorage['<prefix>COMMON__LOCAL__KEY__']
= { value: { TOKEN__: { value: token, time, expire } }, time, expire }
  └─ 外层 storageCache 包装       └─ 内层 Persistent 包装（getLocal 读 .value）
```

- **统一用** `harness/e2e/mes/helpers/auth.ts` 的 `loginViaApi(page, path?)`（含 token 缓存 + 登录竞态自动重试），禁止各 spec 重复写注入逻辑
- prefix 运行时动态查找 `keys.find(k => k.includes('COMMON__LOCAL__KEY__'))`（服务器是 DOCKER 环境，勿硬编码 PRODUCTION）

### antd 组件操作六坑

1. **抽屉 vs 背后搜索区**：列表页搜索表单与抽屉表单有同名 select，必须作用域限定 `.ant-drawer:has-text("标题")` 再操作，否则点中背后被遮罩元素
2. **select 点击目标**：点 `.ant-select-selector`（不是根 div 也不是 `-selection-wrap`）；选项用 `.ant-select-item-option`，动画期 `waitForTimeout(400)`，必要时 `force: true`
3. **字典下拉首项是"全部"（空值）**：点 first 会回显但表单值为空→提交校验失败，用 `.nth(1)`
4. **按钮两汉字有空格**：ant 自动加空格（"确 认"/"搜 索"），`has-text("确认")` 匹配不到，用 `getByRole('button', { name: '确 认' })`；且 `has-text` 是**子串匹配**（"审核"会误中"反审核"），按钮状态断言必须加 `exact: true`
5. **单选/多选不同**：MaterialSelectModal single=radio，multiple=checkbox，写选择器前先看 mode
6. **抽屉默认带空明细行**：OtherInDrawer 初始化已有一行，再"添加行"产生空行导致静默保存失败；**保存结果别信 toast，用 API 查落库断言**（`list?code=xxx`）

### 存量 E2E 修复顺序（登录闸门原则）

登录是闸门：登录注入不通时所有用例都死在第一步，下游漂移被掩盖。**先修通公共登录 → 全量跑暴露真失败（失败数"变多"是好转）→ 逐个修内容漂移**。失败全在同一步→查登录/导航；失败分散→内容漂移。

## 单据页 UX 基线（2026-07-29 黄金模板配套，新增单据页逐项核对）

模板源：`harness/templates/mes-doc-page/`（单表版 5 模式 / 主子表版 10 模式）。铁拳团产品 agent 按本清单审计新页面。

### 列表页
- [ ] 搜索栏有字典下拉（JDictSelectTag），涉及仓库的有 ApiSelect 下拉
- [ ] 复选框可用（rowSelection），批量审核/反审核按钮有状态守卫（全选同状态才可用）
- [ ] 操作列按钮按 status 动态显隐（草稿=编辑+删除，已审核=空）
- [ ] 主子表有展开行组件（ItemsSubTable：物料编码/规格/数量/单价/金额）

### 抽屉页
- [ ] 新增时自动获取编码（getNextCode + MES_BIZ_CODE），失败回退手工输入不阻塞
- [ ] 明细行：JMaterialSelect 选物料 + 数量/单价 InputNumber + 金额自动算
- [ ] 选物料自动预填移动平均成本（onMaterialChange → unitCost）
- [ ] 批量添加物料弹窗（MaterialSelectModal mode="multiple"，同样预填成本）
- [ ] 提交时 confirmLoading 防重复点击
- [ ] 有口径/快照类业务规则时顶部 Alert 说明

### 状态机
- [ ] 删除有 popConfirm；审核/反审核有确认
- [ ] 已审核单据编辑/删除入口隐藏

### 展示值
- [ ] 物料列显示编码/名称，**禁止裸 ID**（testing.md 断言锚点 #4）
- [ ] 差异/异常值红标高亮（#f5222d 加粗）

## /evolve 增量规则（2026-08-02）

### TS noUnusedLocals 不支持 `_` 前缀豁免（ts-no-unused-locals-vs-eslint）

| 规则 | `_` 前缀豁免 | 配置 |
|------|:--:|------|
| TS `noUnusedLocals` | ❌ | 不支持 |
| TS `noUnusedParameters` | ❌ | 不支持 |
| ESLint `@typescript-eslint/no-unused-vars` | ✅ | `varsIgnorePattern: '^_'` |

**触发场景**：想保留未用变量改名为 `_X` 豁免 TS6133 → **不工作**。

**正确做法**：
1. 直接删除未使用变量（最干净）
2. 必须保留：`// @ts-expect-error — 未使用但保留`
3. 关闭规则（最后手段）：`tsconfig.json` 设 `noUnusedLocals: false`

详见 `learnings/2026-08-02-ts-no-unused-locals-vs-eslint.md`。

### vue-tsc 2.x + allowJs 默认行为（vue-tsc-default-allowjs）

升级 vue-tsc 到 2.2.x 后**默认行为变化**：
- 1.x：宽松，忽略 .js exclude 错误
- 2.x：严格，会处理未 exclude 的 .js

**minified SDK 误报**（如 `src/components/onlinePreview/open-jssdk.es.js`）：
- tsconfig `"exclude": ["**/*.js"]` 在 vue-tsc 2.x **不可靠**
- `grep "\.js("` 错误日志可快速发现

**解决**：
```json
// tsconfig.json
{ "compilerOptions": { "allowJs": false } }
```

或具体文件加 exclude（可靠）：
```json
"exclude": ["**/*.js", "src/specific.js"]
```

详见 `learnings/2026-08-02-vue-tsc-default-allowjs.md`。

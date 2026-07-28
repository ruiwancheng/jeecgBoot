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

## 路由
- 一级菜单 `LAYOUT` + `redirect`
- 子页面懒加载 `() => import('/@/views/...')`
- 项目页面加前缀 `/project/{项目名}/`
- **新增 Vue 组件后必须重启 Vite**（`import.meta.glob` 缓存）
- **菜单 404 排查：** 先查 `sys_permission.is_route` 是否为 1。`is_route=0` 时前端不生成路由，直接返回 404。其次查 `parent_id` 是否指向正确的父菜单

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
| `DatePicker` | 返回 dayjs 对象，JSON 序列化后后端解析失败 | `componentProps: { valueFormat: 'YYYY-MM-DD HH:mm:ss' }` |
| `JSearchSelect` | 传 `dictTable/dictText/dictCode` 三个属性，下拉无数据 | 用 `dict: 'table,text,code'` 合写格式 |
| `JSearchSelect` + `dict="c_mes_*,text,value"` | 平台字典原始SQL不经MyBatis-Plus → 下拉数据与列表必不一致（del_flag未过滤、数据源未路由）| 改用 `ApiSelect` + 目标Controller的`/selectPage`端点。禁止在MES项目中使用表字典模式 |
| `useTable` | `immediate: false` 导致 Tab 内子表首次不加载数据 | 配合 `v-if` 判断父组件已传参后，设为 `immediate: true` |
| `BasicTable` rowSelection | 复选框列不显示，`useListPage` 内部不传递 rowSelection | 手动 `reactive` 创建 `rowSelection` 对象（含 `type:'checkbox'` + `onChange`），`selectedRowKeys` 用 `reactive` 非 `ref`，绑 `:rowSelection` 在 BasicTable 上 |
| `userStore.getUserInfo` | getter 是计算属性，加 `()` 静默失败返回空 | Pinia getters 作属性访问：`userStore.getUserInfo?.realname`，不加 `()` |

## 接口
- `defHttp.get/post/put/delete`
- DELETE 请求必须加 `{ joinParamsToUrl: true }`，否则参数在请求体，后端 `@RequestParam` 收不到
- 路径枚举在 `.api.ts`

## 单据自动编码（编码规则接线模式）

新单据页面需要自动编号时，按标准三步（来源：2026-07-21 编码规则绑定，10 个单据页已验证）：

1. **统一映射**：`basic/codeRule/bizCodeMap.ts` 的 `MES_BIZ_CODE` 常量加映射，禁止页面硬编码 `'SO'` 类字符串
2. **Drawer 接线**：`useDrawerInner` 内 `if (!unref(isUpdate))` 分支调 `getNextCode(MES_BIZ_CODE.XXX)` → `setFieldsValue({ code })`，外层 try/catch 静默回退手工输入（不阻塞开单）
3. **配套数据**：SQL 补规则（INSERT IGNORE 固定 id）+ 规则实体 `@Dict` 注解 + 字典 `mes_code_biz_type`

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
4. **按钮两汉字有空格**：ant 自动加空格（"确 认"/"搜 索"），`has-text("确认")` 匹配不到，用 `getByRole('button', { name: '确 认' })`
5. **单选/多选不同**：MaterialSelectModal single=radio，multiple=checkbox，写选择器前先看 mode
6. **抽屉默认带空明细行**：OtherInDrawer 初始化已有一行，再"添加行"产生空行导致静默保存失败；**保存结果别信 toast，用 API 查落库断言**（`list?code=xxx`）

### 存量 E2E 修复顺序（登录闸门原则）

登录是闸门：登录注入不通时所有用例都死在第一步，下游漂移被掩盖。**先修通公共登录 → 全量跑暴露真失败（失败数"变多"是好转）→ 逐个修内容漂移**。失败全在同一步→查登录/导航；失败分散→内容漂移。

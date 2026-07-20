# Online 表单路由缓存配置

## 概述

Online 表单挂载到菜单后，可开启路由缓存（keepAlive），避免切换 Tab 时页面重新加载。
路由分两种：**动态路由**（系统菜单配置，默认）和**静态路由**（前端代码写死）。

> **默认不开启缓存路由**（keepAlive=false）。仅当用户明确要求开启缓存时才设置 keepAlive=true 并执行 Step 3-4。

---

## 识别 Online 表单菜单

当用户要求对某个菜单开启路由缓存时，先查询菜单信息，如果其 URL 匹配以下 4 种模式之一，则为 Online 表单菜单，**必须走本文档的完整 4 步流程**：

| URL 模式 | 说明 |
|:---|:---|
| `/online/cgformList/{id}` | 默认主题（单表/normal） |
| `/online/cgformErpList/{id}` | ERP 主题（一对多） |
| `/online/cgformInnerTableList/{id}` | 内嵌子表主题（一对多） |
| `/online/cgformTabList/{id}` | TAB 主题（一对多） |

> 仅在**设置路由缓存**时需要走此流程，其他菜单操作（创建、改名等）不需要。

---

## API 操作流程（4 步）

### Step 1：获取 Online 表单预览地址

通过 headId 拼出预览路径：
- 单表/默认主题：`online/cgformList/{headId}`
- ERP主题：`online/cgformErpList/{headId}`
- 内嵌子表主题：`online/cgformInnerTableList/{headId}`
- TAB主题：`online/cgformTabList/{headId}`
- 树主题：`online/cgformTreeList/{headId}`

### Step 2：创建/更新业务菜单

在系统菜单中为该 Online 表单创建菜单（或更新已有菜单）：
- **访问路径（url）**：Step 1 获取的预览地址
- **前端组件（component）**：填 `1` 作为占位
- **组件名称（componentName）**：根据 URL 路径自动推导（见下方映射规则）
- **是否缓存路由（keepAlive）**：`true`

### Step 3：判断路由类型（动态 or 静态）

查询系统菜单**第二层级**（parentId 非空的一级子菜单），检查是否存在 `online/cgformList/:` 开头的通配路由：

```
GET /sys/permission/list
→ 遍历 children，查找 url 匹配 online/cgformList/: 或 online/cgformErpList/: 等模式
```

- **找到** → Online 使用**动态路由**（菜单中配置），继续 Step 4
- **未找到** → Online 使用**静态路由**（前端代码内置），**停止**，需改前端代码（见下方「静态路由配置」）

### Step 4：设置 AUTO 菜单的组件名称和缓存

找到 Step 3 中匹配到的 AUTO 菜单（如「AUTO在线表单」），**必须传完整参数**进行编辑：

> **关键：** `sys/permission/edit` 接口需要传所有字段，不能只传部分字段，否则会导致丢失配置。先从 Step 3 的查询结果中获取 AUTO 菜单的完整信息，再修改 `componentName` 和 `keepAlive`。

```json
PUT /sys/permission/edit
{
  "id": "<AUTO菜单ID>",
  "menuType": 1,
  "name": "AUTO在线表单",
  "url": "/online/cgformList/:id",
  "component": "super/online/cgform/auto/default/OnlineAutoList",
  "componentName": "OnlineAutoList",
  "icon": null,
  "sortNo": 25,
  "route": true,
  "hidden": true,
  "hideTab": false,
  "keepAlive": true,
  "alwaysShow": false,
  "internalOrExternal": false,
  "parentId": "<父菜单ID>"
}
```

**AUTO 菜单的固有属性（不可随意修改）：**
- `menuType`: `1`（子菜单）
- `route`: `true`
- `hidden`: `true`（AUTO菜单默认隐藏）
- `component`: 实际组件路径（非占位 "1"）
- `parentId`: 上级菜单ID（「在线开发」目录）

**各 AUTO 菜单 component 路径：**

| AUTO 菜单 | component |
|:---|:---|
| AUTO在线表单 | `super/online/cgform/auto/default/OnlineAutoList` |
| AUTO在线ERP表单 | `super/online/cgform/auto/erp/CgformErpList` |
| AUTO在线一对多内嵌 | `super/online/cgform/auto/innerTable/OnlCgformInnerTableList` |
| AUTO在线Tab风格 | `super/online/cgform/auto/tab/OnlCgformTabList` |
| AUTO树表单列表 | `super/online/cgform/auto/tree/DefaultOnlineList` |

---

## URL 路径 → 组件名称映射规则

根据预览地址中的路径关键词自动推导组件名称：

| URL 路径包含 | 组件名称（componentName） | 对应 AUTO 菜单 |
|:---|:---|:---|
| `cgformList` | `OnlineAutoList` | AUTO在线表单 |
| `cgformErpList` | `CgformErpList` | AUTO在线ERP表单 |
| `cgformInnerTableList` | `OnlCgformInnerTableList` | AUTO在线一对多内嵌 |
| `cgformTabList` | `OnlCgformTabList` | AUTO在线Tab风格 |
| `cgformTreeList` | `DefaultOnlineList` | AUTO树表单列表 |

> **推导逻辑**：从 URL 中提取路径关键词（cgformList / cgformErpList / ...），匹配上表得出 componentName。无需关心主题模板配置。

---

## 静态路由配置

适用于 Step 3 判断为静态路由的场景（菜单中没有 `online/cgformList/:` 通配路由）。

- **文件位置**：`src/views/super/online/cgform/router/cgformRouter.ts`
- 在 `registerCgformRouter` 方法中添加 `keepAlive: true`

此场景无法通过 API 完成，需要修改前端代码并重新构建。

---

## 主题模板对照表（参考）

| 主题模板 | 组件名称 | URL 路径关键词 |
|:---:|:---:|:---:|
| 默认主题（normal） | `OnlineAutoList` | cgformList |
| ERP主题（一对多） | `CgformErpList` | cgformErpList |
| 内嵌子表主题（一对多） | `OnlCgformInnerTableList` | cgformInnerTableList |
| TAB主题（一对多） | `OnlCgformTabList` | cgformTabList |
| 树主题 | `DefaultOnlineList` | cgformTreeList |

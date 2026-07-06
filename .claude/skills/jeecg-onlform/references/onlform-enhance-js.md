# Online 表单 JS 增强参考

> **重要：JS 增强代码会被后端预处理 + `new Function` 包装成对象方法：**
> 1. **不能在外部声明独立的 `function`！** 所有函数必须以 `var fn = function(){}` 形式声明在事件处理方法内部（闭包中）
> 2. **多个方法之间必须用逗号 `,` 分隔！** 如 `onlChange(){...},loaded(){...}`，缺少逗号会报 `SyntaxError: Unexpected identifier`
> 3. **写完 JS 增强后必须自行校验语法**，可在浏览器控制台用 `new Function('...')` 测试
> 4. **顶层事件方法和 `return {}` 里的字段处理器必须用「对象方法简写」`name(){...}`，绝对不能写成 `name: function(){...}`！**
>    后端用正则把简写形式转成 `name: function(that, event){...}` 并注入 `that`（表单上下文）和 `event`（事件对象）两个参数；写成 `name: function(){...}` 不会被匹配 → `event` 退化成 `window.event`（DOM 事件，没有 `.row/.value/.column`）→ 运行时报 `Cannot read properties of undefined (reading 'xxx')`。
>    闭包里的 helper 用 `var fn = function(){}` 不受此限。排查：调 `GET /online/cgform/api/getFormItem/{headId}` 看 `enhanceJs` 字段，确认字段处理器被转成了 `name:function(that,event){...}`。
>
> ```js
> // ❌ 错误：独立 function 在对象外部，运行时找不到
> function helper() { ... }
> onlChange() { return { field() { helper() } } }
>
> // ❌ 错误：字段处理器写成 name: function(){}，event 不会被注入 → event.row 为 undefined
> ai_sub_table_onlChange() { return { field: function(){ var r = event.row /* 报错 */ } } }
>
> // ✅ 正确：事件方法 + 字段处理器都用简写，helper 在闭包内用 var
> ai_sub_table_onlChange() {
>   var helper = function(that, event) { ... }
>   return { field(){ helper(this, event) } }
> }
> ```

### JS 增强分两个 Tab（form 和 list）

**form（表单JS增强）** — 写在 `cgJsType="form"` 中：

| 事件/函数 | 触发时机 | 必须返回 |
|---------|---------|---------|
| `loaded()` | 表单渲染完成、数据赋值后 | 无 |
| `beforeSubmit(row)` | 表单提交前 | Promise（resolve 放行，reject 拦截） |
| `onlChange()` | 主表/单表字段值变化 | 对象 `{字段名(){ ... }}` |
| `{子表名}_onlChange()` | 子表字段值变化 | 对象 `{字段名(){ ... }}` |
| `setup()` | 页面渲染时自动执行 | 无 |
| `{buttonCode}()` | form 样式按钮触发 | 无 |

**判断当前操作模式：**
- `this.isUpdate?.value === true` → 编辑
- `this.isDetail?.value === true` → 详情
- 否则 → 新增

**list（列表JS增强）** — 写在 `cgJsType="list"` 中：

| 事件/函数 | 触发时机 | 必须返回 |
|---------|---------|---------|
| `{buttonCode}()` | button 样式按钮触发（无参数） | 无 |
| `{buttonCode}(row)` | link 样式按钮触发（**参数名必须是 row**） | 无 |
| `beforeEdit(row)` | 列表编辑前 | Promise |
| `beforeDelete(row)` | 列表删除前 | Promise |

### onlChange 事件对象 (event)

**主表/单表 onlChange 事件：**

| 属性 | 说明 |
|------|------|
| `event.value` | 当前控件值 |
| `event.row` | 当前表单数据（编辑时有 id） |
| `event.column` | 当前列配置（`event.column.key` 获取字段名） |

**子表 子表名_onlChange 事件（一对多）：**

| 属性 | 说明 |
|------|------|
| `event.value` | 当前控件值（**刚改字段的新值，必须用它**） |
| `event.row` | 当前行数据（`event.row.id` 获取行 ID） |
| `event.column` | 当前列配置（`event.column.key` 获取字段名） |
| `event.target` | 子表 table 对象（用于 `triggleChangeValues` 第三个参数） |
| `event.type` | 控件类型 |

> ⚠️ **取值时机陷阱：** 在子表 `字段名(){...}` 处理器里，`event.row.字段名`（即刚刚被编辑的那个字段）**可能还是旧值/空值**——change 事件触发的那一刻新值尚未回写到 `event.row`，可靠的新值在 `event.value`。
> **规则：刚改的字段读 `event.value`，行内其它字段才读 `event.row.xxx`。** 否则会出现"单步永远凑不齐多个字段值、计算条件永远不成立、界面没反应也不报错"的现象。
> 例：`数量` 变化时算 `小计 = 单价 × 数量` → 用 `event.row.unit_price` 和 `event.value`；`单价` 变化时同理换成 `event.value` 和 `event.row.qty`。

**子表 子表名_onlChange 事件（一对一）：**

| 属性 | 说明 |
|------|------|
| `event.value` | 当前控件值 |
| `event.row` | 当前子表表单数据 |
| `event.column` | 列配置 |
| `event.target` | 子表表单对象 |

> **限制：ERP 主题（themeTemplate=erp）下 `子表名_onlChange` 不生效！** 仅 normal/tab/innerTable 主题支持子表值变化监听。

### 表单 API (this.xxx)

**属性（ref 对象需 `.value` 取值）：**

| 属性 | 说明 |
|------|------|
| `this.loading` | 是否加载中（ref 对象） |
| `this.isUpdate` | 是否编辑模式（ref，`this.isUpdate.value === true`） |
| `this.onlineFormRef` | 主表/单表表单 ref 对象 |
| `this.refMap` | 子表表单/table 的 ref 对象 map（key=子表名） |
| `this.subActiveKey` | 子表激活的 tab 索引（ref，从 `'0'` 开始） |
| `this.sh` | 单表/主表字段显隐状态对象 |
| `this.submitFlowFlag` | 提交后是否自动发起流程（ref） |
| `this.subFormHeight` | 一对一子表表单高度（ref，无需手动设置） |
| `this.subTableHeight` | 一对多子表 table 高度（ref，无需手动设置） |
| `this.tableName` | 当前表名（ref） |
| `this.$nextTick` | Vue3 nextTick |

**方法：**

| 方法 | 说明 |
|------|------|
| `this.setFieldsValue({field: value})` | 设置主表/单表字段值 |
| `this.getFieldsValue()` | 获取主表/单表所有字段值 |
| `this.triggleChangeValue(field, value)` | 设置单个字段值 |
| `this.triggleChangeValues(values, id?, target?)` | 设置字段值（不传 id/target 改主表，传则改子表指定行） |
| `this.changeOptions(field, [{value,text}])` | 改变单表/主表下拉选项（注意：options 格式是 `{text,value}` 不是 `{label,value}`） |
| `this.changeSubTableOptions(表名, 字段, options)` | 改变一对多子表下拉选项 |
| `this.changeSubFormbleOptions(表名, 字段, options)` | 改变一对一子表下拉选项 |
| `this.changeRemoteOptions({field,dict,label,type?,subTableName?})` | 改变下拉搜索数据源 |
| `this.addSubRows(表名, [{...}])` | 添加子表行 |
| `this.clearSubRows(表名)` | 清空子表数据 |
| `this.clearThenAddRows(表名, [{...}])` | 清空后添加子表行 |
| `this.getSubTableInstance(表名)` | 获取子表实例（可调用 `getTableData()` 等） |
| `this.updateSchema({field, componentProps})` | 动态更新字段属性（如 `{disabled: true}`） |
| `this.executeMainFillRule()` | 重新触发主表/单表的填值规则 |
| `this.executeSubFillRule(表名, event)` | 重新触发子表当前行的填值规则 |
| `this.submitFormAndFlow()` | 提交表单并发起流程 |
| `this.onlineFormValueChange(field, value, otherValues)` | hook 模式下表单值变化回调（替代 onlChange） |

### 字段显隐/禁用控制

| 语法 | 说明 |
|------|------|
| `this.sh.字段名 = false` | 隐藏字段（仍在表单中） |
| `this.sh.字段名_load = false` | 不加载字段（从 DOM 移除） |
| `this.sh.字段名_disabled = true` | 禁用字段（v3.6.4+） |

### 列表 API (this.xxx)

**属性：**

| 属性 | 说明 |
|------|------|
| `this.selectedRows` | 已选行数据数组 |
| `this.selectedRowKeys` | 已选行 ID 数组 |
| `this.queryParam` | 查询表单的查询条件 |
| `this.acceptHrefParams` | 获取地址栏上的条件参数 |
| `this.currentPage` | 当前页数（默认 1） |
| `this.pageSize` | 每页条数（默认 10） |
| `this.total` | 总条数 |
| `this.currentTableName` | 当前表名 |
| `this.description` | 当前表描述 |
| `this.ID` | 当前表的配置 ID（headId） |
| `this.sortField` | 排序字段（默认 `'id'`） |
| `this.sortType` | 排序类型（默认 `'asc'`） |
| `this.hasChildrenField` | 树形列表的「是否有子节点」字段名 |
| `this.loading` | 是否加载中（ref，v3.8.0+） |

**方法：**

| 方法 | 说明 |
|------|------|
| `this.loadData()` | 重新加载列表数据 |
| `this.clearSelectedRow()` | 清除选中的行 |
| `this.getLoadDataParams()` | 获取所有查询条件（含查询表单、高级查询、地址栏参数、分页、排序） |
| `this.isTree()` | 判断当前表是否是树（返回布尔值） |
| `this.openCustomModal(options)` | 打开自定义弹窗 |
| `this.acceptHrefParams` | 获取 URL 参数 |

### openCustomModal 弹窗参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `title` | string | 弹窗标题（默认"自定义弹框"） |
| `width` | number | 弹窗宽度（默认 600） |
| `row` | object | 数据对象（Link 按钮必须传 row 参数） |
| `formComponent` | string | 自定义 vue 组件路径（如 `demo/hello/index.vue`） |
| `requestUrl` | string | 请求 URL |
| `hide` | string[] | 隐藏的字段名数组（与 show 互斥） |
| `show` | string[] | 只显示的字段名数组（优先于 hide） |

### JS 增强常用模式总结

**1. 联动下拉（onlChange + loaded）：** 字段A变化时改变字段B的下拉选项
```javascript
onlChange(){ return { fieldA(){ this.changeOptions('fieldB', options); } } }
loaded(){ if(this.isUpdate.value){ /* 根据已有值恢复options */ } }
```

> ⚠️ **`changeOptions` 与 `dictField` 互斥（必须注意）：**
> 如果某个 `list` 字段的选项**完全由 JS 的 `changeOptions` 控制**，必须把该字段的 `dictField`/`dictTable`/`dictText` 全部清空。
> 原因：框架在下拉打开时会重新从字典查询选项并覆盖 JS 设置的选项，导致联动失效（无论选什么值，始终显示字典中的全量选项）。
> **修复方式：** 用 `action=edit` + `modifyFields` 把 hobby 等字段的三个 dict 字段都置为空字符串，再重新同步数据库。

**2. 子改主（子表值变化汇总到主表）：**
```javascript
// 关键：① 处理器用简写 name(){}（不能 name: function(){}）；② 刚改的字段读 event.value，其它读 event.row；③ getValues(callback) 取子表数据；④ 不传 id/target = 改主表
子表名_onlChange(){
  // helper 用 var 声明在闭包内
  var sumToMain = function(formApi){
    formApi.getSubTableInstance('子表名').getValues((err, values) => {
      if (!values) return
      var total = 0
      for (var i = 0; i < values.length; i++) total += Number(values[i].subtotal || 0)
      formApi.triggleChangeValues({ money: total.toFixed(2) })  // 不传 id/target = 改主表
    })
  }
  var calcRow = function(formApi, ev, price, num){
    if (price === '' || price == null || isNaN(price) || num === '' || num == null || isNaN(num)) return
    formApi.triggleChangeValues({ subtotal: (Number(price) * Number(num)).toFixed(2) }, ev.row.id, ev.target)
    formApi.$nextTick(() => sumToMain(formApi))
  }
  return {
    // price 刚改 → 用 event.value；num 取行内现值 event.row.num
    price(){ calcRow(this, event, event.value, event.row.num) },
    num(){   calcRow(this, event, event.row.price, event.value) },
    // 行内 subtotal 变化（手填或被自动算出）→ 重算主表汇总
    subtotal(){ sumToMain(this) }
  }
}
```
> **注意**：① 获取子表数据用 `getValues(callback)` 不是 `getTableData()`；获取一对一子表用 `getFieldsValue()`。② `getSubTableInstance(表名)` 若不可用可退化为 `this.refMap[表名].value[0]`（同样有 `.getValues(cb)`）。③ `triggleChangeValues` 改子表必须传 `event.row.id` 和 `event.target`，改主表则两者都不传。

**3. 字段显隐/禁用（onlChange + loaded）：** 根据条件动态控制字段
```javascript
this.sh.fieldName_load = false;     // 不加载（从DOM移除）
this.sh.fieldName = false;          // 隐藏（仍在DOM中）
this.sh.fieldName_disabled = true;  // 禁用（不可编辑）
```

**4. 提交校验（beforeSubmit）：** 表单提交前拦截校验
```javascript
beforeSubmit(row){
  return new Promise((resolve, reject) => {
    if(row.amount > 100000) reject('金额不能超过10万！');
    else resolve();
  })
}
```

**5. 列表操作拦截（beforeEdit + beforeDelete）：** 写在 list 增强中
```javascript
beforeEdit(row){
  return new Promise((resolve, reject) => {
    if(row.status == '2') reject('已通过的记录不允许编辑！');
    else resolve();
  })
}
```

**6. 新增默认值（loaded）：** 新增时自动填充字段
```javascript
loaded(){
  this.$nextTick(()=>{
    if(!this.isUpdate.value){
      this.setFieldsValue({ status: '0', create_date: new Date().toISOString().slice(0,10) });
    }
  })
}
```

**7. 主改子下拉搜索（changeRemoteOptions）：** 主表值变化动态改变子表下拉搜索数据源（v3.6.4+）
```javascript
onlChange(){
  return {
    fieldA(){
      var val = event.value
      // 单表/主表
      this.changeRemoteOptions({ field: 'fieldB', dict: 'sys_user where status=1,realname,username', label: 'realname' })
      // 一对一子表
      this.changeRemoteOptions({ field: 'fieldB', dict: '...', label: '...', type: 'subForm', subTableName: '子表名' })
      // 一对多子表（注意：一对多仅过滤本地已加载选项，不发远程请求）
      this.changeRemoteOptions({ field: 'fieldB', dict: '...', label: '...', type: 'subTable', subTableName: '子表名' })
    }
  }
}
```
> dict 格式：`"表名 where 条件,显示字段,值字段"`

**8. 主改子下拉选项（changeSubTableOptions/changeSubFormbleOptions）：**
```javascript
onlChange(){
  return {
    fieldA(){
      // 改一对多子表下拉
      this.changeSubTableOptions('子表名', '字段名', [{label:'选项1',value:'1'},{label:'选项2',value:'2'}])
      // 改一对一子表下拉
      this.changeSubFormbleOptions('子表名', '字段名', [{label:'选项1',value:'1'}])
    }
  }
}
```

**9. 系统变量获取（hook 写法）：** 在按钮 hook 中获取用户/租户/角色信息
```javascript
btnCode_hook(){
  import {useUserStore} from "@/hooks/useUserStore"
  const userStore = useUserStore()
  const userInfo = userStore.getUserInfo   // 用户信息
  const tenantId = userStore.getTenant     // 租户ID
  const roleList = userStore.getRoleList   // 角色列表
  const token = userStore.getToken         // Token
}
```

**10. 消息提示（useMessage）：** 仅在自定义按钮中支持
```javascript
btnCode_hook(){
  import {useMessage} from "@/hooks/useMessage"
  const {createMessage, createConfirm, createSuccessModal} = useMessage()
  createMessage.success('操作成功')
  createConfirm({ title:'确认', content:'确定删除？', iconType:'warning', onOk(){} })
}
```

**11. 详情弹窗 JS 增强：** 仅支持 `loaded`、`setFieldsValue`、`getFieldsValue`、`sh.字段名` 显隐控制，不支持完整表单 API。

**12. 自定义弹窗组件要求（openCustomModal + formComponent）：**
- Props 接收：`row`（行数据）、`url`（提交URL）
- 必须 export `handleSubmit()` 函数
- 关闭弹窗：`emit('close')`

**13. 表描述命名规范：** 用 `JS增强@功能名(具体说明)` 格式，如 `JS增强@联动下拉(性别联动爱好)`，方便识别表的用途。

### HTTP 请求 API

JS 增强中每个事件方法内部自动注入了以下变量（从闭包中获取）：

| 变量 | 说明 | 用法 |
|------|------|------|
| `getAction` | GET 请求 | `getAction(url, param).then(res => {...})` |
| `postAction` | POST 请求 | `postAction(url, param).then(res => {...})` |
| `putAction` | PUT 请求 | `putAction(url, param).then(res => {...})` |
| `deleteAction` | DELETE 请求 | `deleteAction(url, param).then(res => {...})` |
| `useMessage` | 消息提示 | `var msg = useMessage(); msg.createMessage.success('操作成功')` |

> **⚠️ 保留变量名（禁止在 JS 增强中重新声明）：** `getAction`、`postAction`、`putAction`、`deleteAction`、`useMessage`、`token`。
> 需要存储 Token 时，使用 `userToken`、`accessToken` 等替代名。

### Hook 语法（支持 import）

按钮编码 + `_hook` 后缀，支持 import 导入模块：
```javascript
buttonCode_hook(){
  import {useUserStore} from "@/hooks/useUserStore"
  const {createMessage} = useMessage()
  const userStore = useUserStore()
  const userToken = userStore.getToken   // ← 不能写 const token，会报重复声明
  createMessage.info(userToken)
}
```

可用 import：`useUserStore`（用户/租户/角色/Token 信息）、`getToken/getTenantId/getLoginBackInfo`（v2025-07-21+）
> **注意：** `useMessage` 无需 import，已注入外层作用域，强行 import 会抛 `SyntaxError: Identifier 'useMessage' has already been declared`。

### JS 增强 API（保存/查询）

| 操作 | 方法 | URL |
|------|------|-----|
| 查询表单JS增强 | GET | `/online/cgform/head/enhanceJs/{headId}?type=form` |
| 查询列表JS增强 | GET | `/online/cgform/head/enhanceJs/{headId}?type=list` |
| 新增JS增强 | POST | `/online/cgform/head/enhanceJs/{headId}` |
| 更新JS增强 | PUT | `/online/cgform/head/enhanceJs/{headId}` |

**GET 返回格式：**
```json
{"id": "xxx", "cgJs": "onlChange(){...}", "cgformHeadId": "xxx", "cgJsType": "form"}
```

**POST/PUT 入参：**
```json
{"cgJs": "JS代码", "cgformHeadId": "xxx", "cgJsType": "form"}
```
更新时加 `"id": "已有记录id"`。

**保存流程：** 先 GET 查询，有 id 则 PUT，无则 POST。

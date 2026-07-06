# Online 表单增强功能参考

## JS 增强参考

> **重要：JS 增强代码会被 `new Function` 包装成对象方法：**
> 1. **不能在外部声明独立的 `function`！** 所有函数必须以 `var fn = function(){}` 形式声明在事件处理方法内部（闭包中）
> 2. **多个方法之间必须用逗号 `,` 分隔！** 如 `onlChange(){...},loaded(){...}`，缺少逗号会报 `SyntaxError: Unexpected identifier`
> 3. **写完 JS 增强后必须自行校验语法**，可在浏览器控制台用 `new Function('...')` 测试
>
> ```js
> // ❌ 错误：独立 function 在对象外部，运行时找不到
> function helper() { ... }
> onlChange() { return { field() { helper() } } }
>
> // ✅ 正确：在事件方法内部用 var 声明
> ai_sub_table_onlChange() {
>   var helper = function(that, event) { ... }
>   return { field(that, event) { helper(that, event) } }
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
| `event.value` | 当前控件值 |
| `event.row` | 当前行数据（`event.row.id` 获取行 ID） |
| `event.column` | 当前列配置（`event.column.key` 获取字段名） |
| `event.target` | 子表 table 对象（用于 `triggleChangeValues` 第三个参数） |
| `event.type` | 控件类型 |

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

**2. 子改主（子表值变化汇总到主表）：**
```javascript
// 关键：用 getValues(callback) 获取子表数据，用 this 访问主表
子表名_onlChange(){
  return {
    price(){
      // 1. 修改当前行小计
      var row = event.row
      this.triggleChangeValues({ subtotal: (row.price * row.num).toFixed(2) }, row.id, event.target)
      // 2. 汇总到主表（必须用 getValues 回调）
      this.getSubTableInstance('子表名').getValues((err, values) => {
        var total = 0
        for (var i = 0; i < values.length; i++) {
          total += values[i].price * values[i].num
        }
        this.triggleChangeValues({ money: total })  // 不传id/target = 改主表
      })
    }
  }
}
```
> **注意**：获取子表数据用 `getValues(callback)` 不是 `getTableData()`。获取一对一子表用 `getFieldsValue()`。

**2. 字段显隐/禁用（onlChange + loaded）：** 根据条件动态控制字段
```javascript
this.sh.fieldName_load = false;     // 不加载（从DOM移除）
this.sh.fieldName = false;          // 隐藏（仍在DOM中）
this.sh.fieldName_disabled = true;  // 禁用（不可编辑）
```

**3. 提交校验（beforeSubmit）：** 表单提交前拦截校验
```javascript
beforeSubmit(row){
  return new Promise((resolve, reject) => {
    if(row.amount > 100000) reject('金额不能超过10万！');
    else resolve();
  })
}
```

**4. 列表操作拦截（beforeEdit + beforeDelete）：** 写在 list 增强中
```javascript
beforeEdit(row){
  return new Promise((resolve, reject) => {
    if(row.status == '2') reject('已通过的记录不允许编辑！');
    else resolve();
  })
}
```

**5. 新增默认值（loaded）：** 新增时自动填充字段
```javascript
loaded(){
  this.$nextTick(()=>{
    if(!this.isUpdate.value){
      this.setFieldsValue({ status: '0', create_date: new Date().toISOString().slice(0,10) });
    }
  })
}
```

**6. 主改子下拉搜索（changeRemoteOptions）：** 主表值变化动态改变子表下拉搜索数据源（v3.6.4+）
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

**7. 主改子下拉选项（changeSubTableOptions/changeSubFormbleOptions）：**
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

**8. 系统变量获取（hook 写法）：** 在按钮 hook 中获取用户/租户/角色信息
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

**9. 消息提示（useMessage）：** 仅在自定义按钮中支持
```javascript
btnCode_hook(){
  import {useMessage} from "@/hooks/useMessage"
  const {createMessage, createConfirm, createSuccessModal} = useMessage()
  createMessage.success('操作成功')
  createConfirm({ title:'确认', content:'确定删除？', iconType:'warning', onOk(){} })
}
```

**10. 详情弹窗 JS 增强：** 仅支持 `loaded`、`setFieldsValue`、`getFieldsValue`、`sh.字段名` 显隐控制，不支持完整表单 API。

**11. 自定义弹窗组件要求（openCustomModal + formComponent）：**
- Props 接收：`row`（行数据）、`url`（提交URL）
- 必须 export `handleSubmit()` 函数
- 关闭弹窗：`emit('close')`

**12. 表描述命名规范：** 用 `JS增强@功能名(具体说明)` 格式，如 `JS增强@联动下拉(性别联动爱好)`，方便识别表的用途。

### HTTP 请求 API

JS 增强中每个事件方法内部自动注入了以下变量（从闭包中获取）：

| 变量 | 说明 | 用法 |
|------|------|------|
| `getAction` | GET 请求 | `getAction(url, param).then(res => {...})` |
| `postAction` | POST 请求 | `postAction(url, param).then(res => {...})` |
| `putAction` | PUT 请求 | `putAction(url, param).then(res => {...})` |
| `deleteAction` | DELETE 请求 | `deleteAction(url, param).then(res => {...})` |
| `useMessage` | 消息提示 | `var msg = useMessage(); msg.createMessage.success('操作成功')` |

> **来源**：JS 增强被包装为 `OnlineEnhanceJs(getAction, postAction, deleteAction)` 函数，每个事件方法（onlChange/loaded 等）执行时会从 `this._getAction` 等解构出这些变量，可直接在事件函数体内使用。

> **⚠️ 保留变量名（禁止在 JS 增强中重新声明）：** `getAction`、`postAction`、`putAction`、`deleteAction`、`useMessage`、`token`。
> 这些名称已被运行时注入到作用域，重新声明（`const token = ...` 等）会抛出 `SyntaxError: Identifier 'xxx' has already been declared`。
> 需要存储 Token 时，使用 `userToken`、`accessToken` 等替代名。

### Hook 语法（支持 import）

按钮编码 + `_hook` 后缀，支持 import 导入模块：
```javascript
buttonCode_hook(){
  // useMessage 已由外层运行时注入，_hook 内直接调用即可，无需 import
  // token 是保留变量名，存 Token 时用 userToken 等替代
  import {useUserStore} from "@/hooks/useUserStore"
  const {createMessage} = useMessage()
  const userStore = useUserStore()
  const userToken = userStore.getToken   // ← 不能写 const token，会报重复声明
  createMessage.info(userToken)
}
```

可用 import：`useUserStore`（用户/租户/角色/Token 信息）、`getToken/getTenantId/getLoginBackInfo`（v2025-07-21+）
> **注意：** `useMessage` 无需 import，它已注入外层作用域，在 `_hook` 内直接 `useMessage()` 调用即可。若强行 `import {useMessage}`，会抛出 `SyntaxError: Identifier 'useMessage' has already been declared`。

---

## Java 增强参考

### 配置类型

| 类型 | 内容填写 | 说明 |
|------|---------|------|
| `spring` | @Component 注解值 | Spring Bean 名称 |
| `class` | 完整类路径 | 全限定类名 |
| `http` | 请求 URL | POST 接口地址 |

> **重要限制：http 类型不支持导入增强！** 导入增强只能使用 `spring` 或 `class` 方式。

### 各 buttonCode 支持的 cgJavaType

| buttonCode | spring | class | http | 说明 |
|-----------|--------|-------|------|------|
| `add/edit/delete` | ✅ | ✅ | ✅ | 表单操作增强 |
| `query/export` | ✅ | ✅ | ✅ | 列表/导出增强 |
| `import` | ✅ | ✅ | ❌ | **导入只支持 spring 和 class** |

### Java 增强保存 API body 格式

```json
// spring 方式（适用于所有 buttonCode，导入必须用此方式）
{
  "buttonCode": "add",
  "event": "start",
  "cgJavaType": "spring",
  "cgJavaValue": "springKeyAddEnhance",
  "activeStatus": "1"
}

// class 方式
{
  "buttonCode": "edit",
  "event": "start",
  "cgJavaType": "class",
  "cgJavaValue": "org.jeecg.modules.demo.online.enhance.JavaClassEditEnhance",
  "activeStatus": "1"
}

// http 方式（适用于 add/edit/delete/query/export，导入不支持）
{
  "buttonCode": "query",
  "event": "end",
  "cgJavaType": "http",
  "cgJavaValue": "/demo/online/enhance/queryMask",
  "activeStatus": "1"
}

// 导入增强（只支持 spring 和 class）
{
  "buttonCode": "import",
  "event": "start",
  "cgJavaType": "spring",
  "cgJavaValue": "importScoreEnhance",
  "activeStatus": "1"
}
```

| 字段 | 说明 | 可选值 |
|------|------|--------|
| `buttonCode` | 绑定按钮 | `add`/`edit`/`delete`/`import`/`export`/`query`/自定义按钮编码 |
| `event` | 事件时机 | `start`=开始(操作前), `end`=结束(操作后) |
| `cgJavaType` | 增强类型 | **`spring`**=Spring Bean名, **`class`**=全限定类名, **`http`**=HTTP接口地址 |
| `cgJavaValue` | 增强内容 | Bean名/类路径/HTTP接口地址 |
| `activeStatus` | 是否生效 | `"1"`=有效, `"0"`=无效 |

> **极重要（实测验证 2026-03-31）：**
> - `cgJavaType` 的正确值是 **`spring`、`class`、`http`**（不是 `spring-key`/`java-class`/`http-api`）
> - 前端 UI 显示为 spring-key/java-class/http-api，但 API 保存和 DB 存储值必须是 `spring`/`class`/`http`
> - 保存 API 会**实时校验** Bean/Class 是否存在，后端未加载对应类时会报"类实例化失败"——必须先部署 Java 代码、重启后端，再配置增强
> - 如果传了 `spring-key`/`java-class`/`http-api`，API 不报错也能保存，但**运行时不会触发增强**（静默失败，无报错日志）

### 接口说明

| 场景 | 实现接口 | 方法签名 |
|------|---------|---------|
| 新增/编辑/删除 | `CgformEnhanceJavaInter` | **`void execute(String tableName, JSONObject json)`** |
| 查询/导出 | `CgformEnhanceJavaListInter` | `void execute(String tableName, List<Map<String,Object>> data)` |
| 导入 | `CgformEnhanceJavaImportInter` | `EnhanceDataEnum execute(String tableName, JSONObject json)` |

> **注意（实测验证）：** `CgformEnhanceJavaInter.execute` 返回值是 **`void`**（不是 `int`），写成 `int` 会编译报错。

### 导入增强返回值

| 枚举值 | 说明 |
|--------|------|
| `EnhanceDataEnum.ABANDON` (0) | 丢弃该行 |
| `EnhanceDataEnum.INSERT` (1) | 插入新记录 |
| `EnhanceDataEnum.UPDATE` (2) | 更新已有记录（需在 json 中设置 id） |

### HTTP-API 增强参数

**表单类**：`{tableName, record}` → 返回 `Result`（success=false 回滚操作）
**列表类**：`{tableName, dataList}` → 返回 `Result`（success=true 时 result 为转换后数据）

> http-api 的 URL 支持相对路径（如 `/demo/online/cgform/enhanceJavaHttp`），系统会自动拼接 baseUrl。也支持完整 URL（`http://...`）。

### 导入增强 Spring Bean 示例

导入增强必须实现 `CgformEnhanceJavaImportInter` 接口（包路径 `org.jeecg.modules.online.cgform.enhance`），该接口在 `hibernate-re` JAR 中（Online 模块的加密包）。

**Maven 依赖（demo 模块需添加）：**
```xml
<dependency>
    <groupId>org.jeecgframework.boot3</groupId>
    <artifactId>hibernate-re</artifactId>
    <version>3.9.1-beta</version>
    <scope>provided</scope>
</dependency>
```

**Java 实现示例：**
```java
import org.jeecg.modules.online.cgform.enhance.CgformEnhanceJavaImportInter;
import org.jeecg.modules.online.cgform.enums.EnhanceDataEnum;
import org.jeecg.modules.online.config.exception.BusinessException;
import org.springframework.stereotype.Component;

@Component("importCheckBean")  // spring-key 的值
public class ImportCheckEnhance implements CgformEnhanceJavaImportInter {
    @Override
    public EnhanceDataEnum execute(String tableName, JSONObject json) throws BusinessException {
        // json 是当前行数据，可直接修改（如 json.put("score", 100)）
        String name = json.getString("name");
        if (name == null || name.trim().isEmpty()) {
            return EnhanceDataEnum.ABANDON; // 丢弃该行
        }
        // 修正数据
        Integer score = json.getInteger("score");
        if (score != null && score > 100) {
            json.put("score", 100);
        }
        return EnhanceDataEnum.INSERT; // 新增
    }
}
```

**增强配置：**
```json
{
  "buttonCode": "import",
  "event": "start",
  "cgJavaType": "spring",
  "cgJavaValue": "importCheckBean",
  "activeStatus": "1"
}
```

---

## SQL 增强变量

SQL 增强中可使用以下系统变量：

| 变量 | 说明 |
|------|------|
| `#{id}` | 当前记录 ID |
| `#{fieldname}` | 当前表任意字段值 |
| `#{sys_user_code}` | 当前登录用户账号 |
| `#{sys_user_name}` | 当前登录用户姓名 |
| `#{sys_org_code}` | 当前用户部门编码 |
| `#{sys_date}` | 系统日期 yyyy-MM-dd |
| `#{sys_time}` | 系统时间 yyyy-MM-dd HH:mm |

> 当参数名同时存在于表单值和系统变量中时，表单值优先。

---

## 数据权限变量

Online 数据权限配置中支持的系统变量：

| 变量 | 说明 |
|------|------|
| `#{sys_user_code}` | 当前用户账号 |
| `#{sys_user_name}` | 当前用户姓名 |
| `#{sys_date}` | 系统日期 |
| `#{sys_time}` | 系统时间 |
| `#{sys_org_code}` | 当前用户部门编码 |
| `#{sys_multi_org_code}` | 用户所有组织编码（逗号分隔） |
| `#{tenant_id}` | 当前用户租户ID（v3.4.5+） |

**联合查询数据权限配置（两种方式）：**
1. **直接在子表上配置数据规则** — 找到子表记录 → 权限控制 → 录入数据规则并授权，无需写别名
2. **在主表上配置自定义SQL查询子表字段** — 使用 `USE_SQL_RULES`，SQL 中用别名引用子表字段

别名规则：主表固定 `a`，子表按 `tabOrderNum` 顺序分配 `b`、`c`、`d`...`z`。v3.6.4+ 也可直接使用完整表名。

示例（主表自定义SQL过滤子表字段）：`b.school = '中学'`（b 是 tabOrderNum=1 的子表别名）

---

## 自定义按钮 API

| 操作 | 方法 | URL |
|------|------|-----|
| 批量创建按钮 | POST | `/online/cgform/button/aitest` |
| 查询按钮列表 | GET | `/online/cgform/head/enhanceButton/{headId}` |

**批量创建 body（数组）：**
```json
[
  {"cgformHeadId":"headId","buttonCode":"one","buttonName":"JS按钮","buttonStyle":"button","optType":"js","orderNum":1,"buttonStatus":"1","optPosition":"2"},
  {"cgformHeadId":"headId","buttonCode":"two","buttonName":"Action按钮","buttonStyle":"button","optType":"action","orderNum":2,"buttonStatus":"1","optPosition":"2"}
]
```

**按钮配置字段：**

| 字段 | 说明 | 可选值 |
|------|------|--------|
| `buttonCode` | 按钮编码（必须与 JS 函数名一致） | 自定义，如 `one`、`myBtn` |
| `buttonName` | 按钮名称 | 自定义 |
| `buttonStyle` | 按钮样式/位置 | `button`=列表顶部按钮（与新增/导入/导出同行）, `link`=列表操作列"更多"下拉中, `form`=表单弹窗底部（与确定/关闭同行） |
| `optType` | 按钮类型 | `js`=触发JS函数, `action`=触发后端请求(SQL/Java增强) |
| `orderNum` | 排序号 | 数字 |
| `buttonStatus` | 状态 | `"1"`=激活 |
| `optPosition` | 位置 | `"2"` |

**按钮编码与 JS 函数的对应关系：**
- `buttonStyle="button"` → JS 函数 `buttonCode()` 无参数，在列表 JS 增强中
- `buttonStyle="link"` → JS 函数 `buttonCode(row)` 参数名**必须是 row**，在列表 JS 增强中
- `buttonStyle="form"` → JS 函数 `buttonCode()` 无参数，在表单 JS 增强中

---

## 自定义按钮表达式

按钮样式为 Link（操作列）时，可配置表达式控制按钮显隐。

### 单条件表达式

| 语法 | 说明 | 示例 |
|------|------|------|
| `fieldname#eq#value` | 等于时显示 | `name#eq#scott` |
| `fieldname#ne#value` | 不等于时显示 | `name#ne#scott` |
| `fieldname#empty#true` | 为空时显示 | `name#empty#true` |
| `fieldname#empty#false` | 非空时显示 | `name#empty#false` |
| `fieldname#in#v1,v2` | 在列表中显示 | `name#in#scott,admin` |

### 多条件组合（v3.5.6+）
- OR 逻辑：`name#eq#scott || age#eq#18`
- AND 逻辑：`name#eq#scott && age#eq#18`
- 不支持括号 `()`

---

## 字段超链接 (fieldHref)

fieldHref 配置后字段在列表中显示为超链接，点击跳转。

### 三种跳转方式

| 方式 | 格式 | 示例 |
|------|------|------|
| HTTP/HTTPS | `https://xxx.com` | `https://www.baidu.com` |
| 路由跳转 | 菜单路径 | `/dashboard/analysis` |
| 内部组件 | vue文件路径 | `demo/hello/index.vue` |

### 参数传递
- 格式：`?name=value&age=23`
- **支持变量**：`${field_name}` 取当前行字段值
- 示例：`/online/cgformList/xxx?name=${teacher_name}&age=${age}`
- 特殊占位符：`{{ACCESS_TOKEN}}` 获取当前登录Token（v3.6.3+）

---

## JS/Java/SQL 增强 API

| 操作 | 方法 | URL |
|------|------|-----|
| 查询表单JS增强 | GET | `/online/cgform/head/enhanceJs/{headId}?type=form` |
| 查询列表JS增强 | GET | `/online/cgform/head/enhanceJs/{headId}?type=list` |
| 新增JS增强 | POST | `/online/cgform/head/enhanceJs/{headId}` |
| 更新JS增强 | PUT | `/online/cgform/head/enhanceJs/{headId}` |
| 查询Java增强 | GET | `/online/cgform/head/enhanceJava/{headId}` |
| 新增/更新Java增强 | POST/PUT | `/online/cgform/head/enhanceJava/{headId}` |
| 查询SQL增强 | GET | `/online/cgform/head/enhanceSql/{headId}` |
| 新增/更新SQL增强 | POST/PUT | `/online/cgform/head/enhanceSql/{headId}` |
| 查询自定义按钮 | GET | `/online/cgform/head/enhanceButton/{headId}` |
| 删除SQL增强 | DELETE | `/online/cgform/head/deletebatchEnhanceSql?ids={id1,id2}` |

### SQL 增强 API 数据格式

**保存 SQL 增强 body：**
```json
{
  "buttonCode": "set_pass",
  "cgformHeadId": "headId",
  "cgbSql": "update 表名 set status = '1' where id = '#{id}'",
  "cgbSqlName": null,
  "content": "点击后将状态设为通过"
}
```
更新时需带 `"id": "已有记录id"`。

| 字段 | 说明 |
|------|------|
| `buttonCode` | 关联的自定义按钮编码（按钮 `optType` 必须是 `action`） |
| `cgbSql` | 增强 SQL（支持 `#{id}`、`#{字段名}`、`#{sys_user_code}` 等变量） |
| `cgbSqlName` | SQL 名称（可为 null） |
| `content` | 描述说明 |

- SQL 增强只能绑定 `optType="action"` 的按钮，JS 类型按钮用 JS 增强

### JS 增强 API 数据格式

**GET 返回（查询为空时 success=false）：**
```json
{
  "id": "b481f8751ddd26cd838f2260891e7069",
  "cgJs": "onlChange(){...}",
  "cgformHeadId": "3ff859c9b3a94a7b984d208e47cdce6e",
  "cgJsType": "form",
  "content": null
}
```

**POST/PUT 入参（需包含完整字段）：**
```json
{
  "cgJs": "JS代码字符串",
  "cgformHeadId": "3ff859c9b3a94a7b984d208e47cdce6e",
  "cgJsType": "form"
}
```
更新时还需带上 `"id": "已有记录的id"`。

**cgJsType 取值：** `form`=表单JS增强，`list`=列表JS增强。

**JS 增强代码规范：** 代码中必须写注释，说明每个字段的含义和业务逻辑，方便维护。示例：
```javascript
onlChange(){
  return {
    // gender: 性别字段（字典sex: 1=男, 2=女）
    gender(){
      let value = event.value;
      let options = [];
      if(value == '1'){
        // 男性 → 爱好选项: 篮球/足球/游泳
        options = [{value:'basketball',label:'篮球'},{value:'football',label:'足球'}];
      }else if(value == '2'){
        // 女性 → 爱好选项: 瑜伽/舞蹈/绘画
        options = [{value:'yoga',label:'瑜伽'},{value:'dance',label:'舞蹈'}];
      }
      // hobby: 爱好字段，动态改变下拉选项
      this.changeOptions('hobby', options);
      this.triggleChangeValue('hobby', '');
    }
  }
}
```

**保存流程：** 先 GET 查询，有结果（有 id）则 PUT 更新（带 id），无结果则 POST 新增。

---

## 实战场景：自定义按钮 + SQL增强实现状态切换（已验证）

在列表操作列"更多"下拉中添加按钮，点击后通过 SQL 更新记录状态。

### 完整配置流程

#### Step 1: 创建 link 样式 + action 类型的自定义按钮

```json
// onlform_enhance.py --config
{
  "action": "create_buttons",
  "tableName": "demo_approval",
  "buttons": [
    {"buttonCode": "set_pass", "buttonName": "设为已通过", "buttonStyle": "link", "optType": "action", "orderNum": 1, "exp": "approval_status#ne#2"},
    {"buttonCode": "set_reviewing", "buttonName": "设为审核中", "buttonStyle": "link", "optType": "action", "orderNum": 2, "exp": "approval_status#ne#1"},
    {"buttonCode": "set_pending", "buttonName": "设为待审核", "buttonStyle": "link", "optType": "action", "orderNum": 3, "exp": "approval_status#ne#0"}
  ]
}
```

**关键配置：**
- `buttonStyle: "link"` → 显示在操作列"更多"下拉中
- `optType: "action"` → 触发后端 SQL/Java 增强（不是 JS）
- `exp` → 按钮显隐表达式（`字段名#ne#值` = 不等于时显示）

#### Step 2: 为每个按钮配置 SQL 增强

```json
// onlform_enhance.py --config
{
  "action": "save_sql",
  "tableName": "demo_approval",
  "enhancements": [
    {"buttonCode": "set_pass", "cgbSql": "update demo_approval set approval_status = '2' where id = '#{id}'", "content": "设为已通过"},
    {"buttonCode": "set_reviewing", "cgbSql": "update demo_approval set approval_status = '1' where id = '#{id}'", "content": "设为审核中"},
    {"buttonCode": "set_pending", "cgbSql": "update demo_approval set approval_status = '0' where id = '#{id}'", "content": "设为待审核"}
  ]
}
```

**SQL 增强注意：**
- `buttonCode` 必须与按钮编码一致
- `#{id}` 是当前记录 ID 变量
- SQL 增强只能绑定 `optType="action"` 的按钮
- `enhancements` 是 save_sql 的 key（不是 `sqls`）

---

## 实战场景：beforeEdit + beforeDelete 拦截操作（已验证）

在列表 JS 增强中拦截编辑和删除操作，根据业务条件阻止用户操作。

### 完整配置

```json
// onlform_enhance.py --config
{
  "action": "save_js",
  "tableName": "demo_order_enhance",
  "cgJsType": "list",
  "cgJs": "beforeEdit(row){\n  return new Promise((resolve, reject) => {\n    // order_status: 订单状态（字典approval_status: 0=待审核, 1=审核中, 2=已通过）\n    if(row.order_status == '2'){\n      reject('已通过的订单不允许编辑！');\n    }else{\n      resolve();\n    }\n  })\n},\nbeforeDelete(row){\n  return new Promise((resolve, reject) => {\n    // order_status=2: 已通过的订单不允许删除\n    if(row.order_status == '2'){\n      reject('已通过的订单不允许删除！');\n    // order_amount: 订单金额，超过10000不允许直接删除\n    }else if(parseFloat(row.order_amount) > 10000){\n      reject('金额超过1万的订单不允许直接删除！');\n    }else{\n      resolve();\n    }\n  })\n}"
}
```

**JS 增强模式说明：**

| 函数 | 位置 | 参数 | 返回值 | 用途 |
|------|------|------|--------|------|
| `beforeEdit(row)` | list JS增强 | row=当前行数据 | Promise | resolve 放行编辑，reject 拦截并显示提示 |
| `beforeDelete(row)` | list JS增强 | row=当前行数据 | Promise | resolve 放行删除，reject 拦截并显示提示 |

**常用拦截条件组合：**
```javascript
// 按状态拦截
if(row.status == '2') reject('已通过不允许操作！');

// 按金额拦截
if(parseFloat(row.amount) > 10000) reject('金额超过1万不允许操作！');

// 按创建人拦截（需配合系统变量，JS中无法直接获取当前用户，建议用数据权限替代）

// 多条件组合
if(row.status == '2') reject('已通过不允许删除！');
else if(parseFloat(row.amount) > 10000) reject('金额超过1万不允许直接删除！');
else resolve();
```

**注意事项：**
- `beforeEdit` 和 `beforeDelete` 之间用**逗号**分隔（JS对象方法格式）
- reject 的参数是提示消息字符串，会显示在页面上
- row 对象的字段值都是字符串，数值比较需要 `parseFloat()` 转换
- `cgJsType: "list"` 表示列表JS增强（不是 form）

---

## 实战场景：4种Java增强完整流程（已验证 2026-03-31）

### Java 增强配置的正确步骤

**必须按以下顺序操作，否则 API 保存时会报"类实例化失败"：**

1. **编写 Java 代码**（放在 demo 模块 `online/enhance/` 目录下）
2. **编译打包** `mvn package -Dmaven.test.skip=true`
3. **重启后端**（确保新代码被加载）
4. **通过 API 配置增强**（此时 Bean/Class 校验才能通过）

> 代码位置：`jeecg-boot-module/jeecg-module-demo/src/main/java/org/jeecg/modules/demo/online/enhance/`

### 示例1：spring 方式 — 新增前校验+自动填充

```java
@Slf4j
@Component("springKeyAddEnhance")
public class SpringKeyAddEnhance implements CgformEnhanceJavaInter {
    @Override
    public void execute(String tableName, JSONObject json) throws BusinessException {
        String title = json.getString("title");
        if (title != null && title.contains("测试")) {
            throw new BusinessException("标题不能包含'测试'关键词！");
        }
        String remark = json.getString("remark");
        if (remark == null || remark.trim().isEmpty()) {
            json.put("remark", "由spring增强自动填充");
        }
    }
}
```

**配置：**
```json
{"buttonCode":"add","event":"start","cgJavaType":"spring","cgJavaValue":"springKeyAddEnhance","activeStatus":"1"}
```

### 示例2：class 方式 — 编辑前校验

```java
// 注意：class 方式不需要 @Component 注解
@Slf4j
public class JavaClassEditEnhance implements CgformEnhanceJavaInter {
    @Override
    public void execute(String tableName, JSONObject json) throws BusinessException {
        if ("2".equals(json.getString("status"))) {
            throw new BusinessException("已通过的记录不允许编辑！");
        }
    }
}
```

**配置：**
```json
{"buttonCode":"edit","event":"start","cgJavaType":"class","cgJavaValue":"org.jeecg.modules.demo.online.enhance.JavaClassEditEnhance","activeStatus":"1"}
```

### 示例3：http 方式 — 查询后手机号脱敏

```java
@Slf4j
@RestController("httpApiQueryEnhance")
@RequestMapping("/demo/online/enhance")
public class HttpApiQueryEnhance {
    @PostMapping("/queryMask")
    public Result<?> queryMask(@RequestBody JSONObject params) {
        JSONArray dataList = params.getJSONArray("dataList");
        if (dataList != null) {
            for (int i = 0; i < dataList.size(); i++) {
                JSONObject record = dataList.getJSONObject(i);
                String phone = record.getString("phone");
                if (phone != null && phone.length() >= 11) {
                    record.put("phone", phone.substring(0, 3) + "****" + phone.substring(7));
                }
            }
        }
        Result<?> res = Result.OK(dataList);
        res.setCode(1);
        return res;
    }
}
```

**配置：**
```json
{"buttonCode":"query","event":"end","cgJavaType":"http","cgJavaValue":"/demo/online/enhance/queryMask","activeStatus":"1"}
```

> **http 方式注意：** 查询/导出增强接收 `{tableName, dataList}`，返回 `Result`，`code` 设为 `1` 表示使用转换后的数据。

### 示例4：spring 方式 — 导入数据校验

```java
@Slf4j
@Component("importScoreEnhance")
public class ImportScoreEnhance implements CgformEnhanceJavaImportInter {
    @Override
    public EnhanceDataEnum execute(String tableName, JSONObject json) throws BusinessException {
        String name = json.getString("name");
        if (name == null || name.trim().isEmpty()) {
            return EnhanceDataEnum.ABANDON; // 丢弃该行
        }
        Integer score = json.getInteger("score");
        if (score != null && score > 100) {
            json.put("score", 100); // 修正数据
        }
        return EnhanceDataEnum.INSERT; // 新增
    }
}
```

**配置：**
```json
{"buttonCode":"import","event":"start","cgJavaType":"spring","cgJavaValue":"importScoreEnhance","activeStatus":"1"}
```

### Java 增强关键总结

| 对比项 | spring | class | http |
|--------|--------|-------|------|
| 需要 @Component | ✅ 是 | ❌ 否 | ✅ 是(@RestController) |
| 实现接口 | CgformEnhanceJavaInter | CgformEnhanceJavaInter | 无（自定义 Controller） |
| cgJavaValue 填什么 | Bean 名称 | 全限定类名 | 接口 URL 路径 |
| 支持导入增强 | ✅ | ✅ | ❌ |
| execute 返回值 | void | void | Result（code=1 生效） |
| 抛异常拦截操作 | throw BusinessException | throw BusinessException | return Result.error() |

# Online 表单增强 — SQL / 自定义按钮 / fieldHref / API 速查

## SQL 增强变量

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
1. **直接在子表上配置数据规则** — 无需写别名
2. **在主表上配置自定义SQL查询子表字段** — 使用 `USE_SQL_RULES`，主表别名 `a`，子表按 tabOrderNum 顺序 `b`、`c`...

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

| 字段 | 说明 | 可选值 |
|------|------|--------|
| `buttonStyle` | 按钮位置 | `button`=列表顶部, `link`=操作列"更多"下拉, `form`=表单底部 |
| `optType` | 按钮类型 | `js`=触发JS函数, `action`=触发SQL/Java增强 |

- `buttonStyle="button"` → JS 函数 `buttonCode()` 无参数，在列表增强中
- `buttonStyle="link"` → JS 函数 `buttonCode(row)` 参数名**必须是 row**，在列表增强中
- `buttonStyle="form"` → JS 函数 `buttonCode()` 无参数，在表单增强中

---

## 自定义按钮表达式（Link 样式显隐控制）

| 语法 | 说明 |
|------|------|
| `fieldname#eq#value` | 等于时显示 |
| `fieldname#ne#value` | 不等于时显示 |
| `fieldname#empty#true` | 为空时显示 |
| `fieldname#empty#false` | 非空时显示 |
| `fieldname#in#v1,v2` | 在列表中显示 |

多条件（v3.5.6+）：`name#eq#scott || age#eq#18`（OR）、`name#eq#scott && age#eq#18`（AND），不支持括号。

---

## 字段超链接 (fieldHref)

| 方式 | 格式 | 判断规则 |
|------|------|---------|
| 外链 | `https://xxx.com?id=${id}` | 以 `http://` 或 `https://` 开头 |
| 内部跳转 | `/dashboard/analysis` | 以 `/` 开头 |
| 打开内部组件 | `demo/neibu/index.vue` | 相对路径，**必须含 `.vue` 后缀** |

支持 `${字段名}` 动态注入当前行值，`{{ACCESS_TOKEN}}` 获取 Token（v3.6.3+）。
目标组件用 `useRoute().query` 接收参数。

---

## SQL 增强 API

| 操作 | 方法 | URL |
|------|------|-----|
| 查询SQL增强 | GET | `/online/cgform/head/enhanceSql/{headId}` |
| 新增/更新SQL增强 | POST/PUT | `/online/cgform/head/enhanceSql/{headId}` |
| 删除SQL增强 | DELETE | `/online/cgform/head/deletebatchEnhanceSql?ids={id1,id2}` |

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
更新时需带 `"id": "已有记录id"`。SQL 增强只能绑定 `optType="action"` 的按钮。

---

## 实战场景：自定义按钮 + SQL增强实现状态切换（已验证）

### Step 1: 创建 link + action 按钮

```json
[
  {"cgformHeadId":"headId","buttonCode":"set_pass","buttonName":"设为已通过","buttonStyle":"link","optType":"action","orderNum":1,"buttonStatus":"1","optPosition":"2","exp":"approval_status#ne#2"},
  {"cgformHeadId":"headId","buttonCode":"set_reviewing","buttonName":"设为审核中","buttonStyle":"link","optType":"action","orderNum":2,"buttonStatus":"1","optPosition":"2","exp":"approval_status#ne#1"},
  {"cgformHeadId":"headId","buttonCode":"set_pending","buttonName":"设为待审核","buttonStyle":"link","optType":"action","orderNum":3,"buttonStatus":"1","optPosition":"2","exp":"approval_status#ne#0"}
]
```

### Step 2: 配置 SQL 增强

```json
// POST /online/cgform/head/enhanceSql/{headId}（逐条保存）
{"buttonCode":"set_pass","cgformHeadId":"headId","cgbSql":"update demo_approval set approval_status = '2' where id = '#{id}'","content":"设为已通过"}
{"buttonCode":"set_reviewing","cgformHeadId":"headId","cgbSql":"update demo_approval set approval_status = '1' where id = '#{id}'","content":"设为审核中"}
{"buttonCode":"set_pending","cgformHeadId":"headId","cgbSql":"update demo_approval set approval_status = '0' where id = '#{id}'","content":"设为待审核"}
```

---

## 实战场景：beforeEdit + beforeDelete 拦截操作（已验证）

```javascript
// cgJsType: "list"
beforeEdit(row){
  return new Promise((resolve, reject) => {
    if(row.order_status == '2') reject('已通过的订单不允许编辑！');
    else resolve();
  })
},
beforeDelete(row){
  return new Promise((resolve, reject) => {
    if(row.order_status == '2') reject('已通过的订单不允许删除！');
    else if(parseFloat(row.order_amount) > 10000) reject('金额超过1万的订单不允许直接删除！');
    else resolve();
  })
}
```

注意：`beforeEdit` 和 `beforeDelete` 之间用逗号分隔；row 字段值都是字符串，数值比较需 `parseFloat()`。

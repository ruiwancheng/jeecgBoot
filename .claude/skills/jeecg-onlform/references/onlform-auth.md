# Online 表单权限配置参考

> 从 SKILL.md 提取的权限与授权相关内容。

---

## 权限配置 API

### 字段权限

| 操作 | 方法 | URL |
|------|------|-----|
| 加载字段权限配置 | GET | `/online/cgform/api/authColumn/{cgformId}` |
| 启用/禁用字段权限 | PUT | `/online/cgform/api/authColumn` body: `{cgformId, code, status: 1或0}` |
| 修改可见/可编辑 | POST | `/online/cgform/api/authColumn` body: `{cgformId, code, switchFlag, listShow/formShow/formEditable}` |
| 加载字段权限树 | GET | `/online/cgform/api/authPage/{cgformId}/1` |
| 查角色已授权字段 | GET | `/online/cgform/api/roleAuth?roleId={roleId}&cgformId={cgformId}&type=1&authMode=role` |
| 保存字段权限 | POST | `/online/cgform/api/roleColumnAuth/{roleId}/{cgformId}` body: `{authId: "[\"id1\",\"id2\"]", authMode: "role"}` |

**switchFlag 与 POST body 格式**：
```json
// switchFlag=1: 控制列表可见
{"cgformId":"xxx", "code":"field", "switchFlag":1, "listShow":true/false, "formShow":false, "formEditable":false}

// switchFlag=2: 控制表单可见
{"cgformId":"xxx", "code":"field", "switchFlag":2, "listShow":false, "formShow":true/false, "formEditable":false}

// switchFlag=3: 控制表单可编辑
{"cgformId":"xxx", "code":"field", "switchFlag":3, "listShow":false, "formShow":false, "formEditable":true/false}
```
每次调用只改对应 switchFlag 的布尔值，其余传 false。

**authMode**: `"role"` / `"depart"` / `"user"`

### 按钮权限

| 操作 | 方法 | URL |
|------|------|-----|
| 加载按钮权限配置 | GET | `/online/cgform/api/authButton/{cgformId}` |
| 启用按钮 | POST | `/online/cgform/api/authButton` |
| 禁用按钮 | PUT | `/online/cgform/api/authButton/{id}` |
| 加载按钮权限树 | GET | `/online/cgform/api/authPage/{cgformId}/2` |
| 保存按钮权限 | POST | `/online/cgform/api/roleButtonAuth/{roleId}/{cgformId}` body: `{authId: "[\"id1\"]", authMode: "role"}` |

**内置按钮编码**: `add, edit, detail, delete, batch_delete, export, import, query, reset, aigc_mock_data, bpm, super_query, form_confirm`
**page**: 3=列表按钮, 5=表单按钮

### 数据权限

| 操作 | 方法 | URL |
|------|------|-----|
| 加载数据权限规则 | GET | `/online/cgform/api/authData/{cgformId}` |
| 新增规则 | POST | `/online/cgform/api/authData` |
| 更新规则 | PUT | `/online/cgform/api/authData` |
| 删除规则 | DELETE | `/online/cgform/api/authData/{id}` |
| 加载有效规则树 | GET | `/online/cgform/api/validAuthData/{cgformId}` |
| 保存数据权限 | POST | `/online/cgform/api/roleDataAuth/{roleId}/{cgformId}` body: `{authId: "[\"id1\"]", authMode: "role"}` |

**数据规则格式**:
```json
{
  "cgformId": "form_id",
  "ruleName": "规则名称",
  "ruleColumn": "字段名",
  "ruleOperator": "=",
  "ruleValue": "#{sys_user_code}",
  "status": 1
}
```

**ruleOperator 完整列表（按字段类型分组）：**

| 运算符 | 说明 | 适用字段类型 |
|--------|------|------------|
| `=` | 等于 | 所有类型 |
| `!=` | 不等于 | 所有类型 |
| `IN` | 包含（列表） | 所有类型 |
| `LIKE` | 模糊匹配（包含） | 文本类型 |
| `RIGHT_LIKE` | 右模糊（以…开头） | 文本类型 |
| `LEFT_LIKE` | 左模糊（以…结尾） | 文本类型 |
| `>` | 大于 | 数字/日期类型 |
| `>=` | 大于等于 | 数字/日期类型 |
| `<` | 小于 | 数字/日期类型 |
| `<=` | 小于等于 | 数字/日期类型 |
| `EMPTY` | 为空 | 所有类型 |
| `NOT_EMPTY` | 不为空 | 所有类型 |
| `USE_SQL_RULES` | 自定义SQL | 特殊（ruleColumn 必须为空） |

**自定义 SQL 规则**（ruleOperator=`USE_SQL_RULES`）：
- `ruleColumn` 设为空字符串
- `ruleValue` 填 SQL 片段（不含 WHERE 关键字）
- 主表别名 `a`，子表 `b,c,d...`，v3.6.4+ 也可用完整表名
- 示例：`a.sys_org_code = #{sys_org_code}` 或 `create_by = #{sys_user_code}`

**常用规则示例**：
```json
// 只看自己创建的数据
{"ruleName":"仅自己的数据","ruleColumn":"create_by","ruleOperator":"=","ruleValue":"#{sys_user_code}","status":1}

// 只看本部门数据（RIGHT_LIKE 会匹配本部门及所有子部门）
{"ruleName":"本部门数据","ruleColumn":"sys_org_code","ruleOperator":"RIGHT_LIKE","ruleValue":"#{sys_org_code}","status":1}

// 按业务字段过滤（如：只看在职员工，status字段=1）
{"ruleName":"仅在职员工","ruleColumn":"work_status","ruleOperator":"=","ruleValue":"1","status":1}

// 自定义SQL：多部门
{"ruleName":"多部门数据","ruleColumn":"","ruleOperator":"USE_SQL_RULES","ruleValue":"sys_org_code IN (#{sys_multi_org_code})","status":1}
```

> **典型数据规则组合场景**：可以同时创建多条规则，授权时选择性组合。例如创建"仅自己的数据"、"仅本部门数据"、"仅在职员工"三条规则，给不同角色/部门/用户授权不同组合。

---

## 字段权限树结构（authPage 返回）

每个启用的字段有 3 个控制开关（勾选=受控需授权，不勾选=不控制所有人可访问）：

| switchFlag | 含义 | 勾选效果 | 不勾选效果 |
|-----------|------|---------|----------|
| 1 | 列表可见 | 只有授权的人在列表能看到 | 所有人在列表都能看到 |
| 2 | 表单可见 | 只有授权的人在表单能看到 | 所有人在表单都能看到 |
| 3 | 表单可编辑 | 只有授权的人在表单能编辑 | 所有人在表单都能编辑 |

**只有勾选的控制项才会出现在权限树中**，通过 `page` + `control` 区分：

| page | control | 含义 |
|------|---------|------|
| 3 | 5 | **列表可见** |
| 5 | 5 | **表单可见** |
| 5 | 3 | **表单可编辑** |

**权限项是扁平列表**（无父子嵌套），同一字段的多个权限项有相同的 `code` 但不同的 `id`。

---

## 三种权限的逻辑区别（极重要！）

| 权限类型 | 勾选/启用含义 | 授权效果 | 未授权效果 |
|---------|-------------|---------|----------|
| **字段权限** | 勾选 = **受控**（需授权才能访问） | 被授权的人**能**看到/编辑 | 未授权的人**看不到** |
| **按钮权限** | 启用 = **受控**（需授权才能看到） | 被授权的人**能**看到按钮 | 未授权的人**看不到**按钮 |
| **数据权限** | 启用 = **规则生效** | 被授权的人**只能看到**符合规则的数据 | 未授权的人**不受此规则限制** |

**关键区别：**
- 字段权限/按钮权限：**不授权 = 被限制**（看不到/用不了）
- 数据权限：**授权 = 被限制**（只能看到规则匹配的数据），不授权反而没限制

**数据权限是"谁勾选谁生效"**：给张三勾选了"f_list=1"的规则，张三就只能看到 f_list=1 的数据；其他未勾选的人不受限制，能看到全部数据。

---

## 权限配置自动化流程

```
1. 启用字段/按钮权限 → PUT authColumn/POST authButton（status=1）
2. 查角色ID → GET /sys/role/list
3. 加载权限树 → GET authPage/{cgformId}/{type}
4. 查角色已授权 → GET roleAuth?roleId=&cgformId=&type=&authMode=
5. 保存授权 → POST roleColumnAuth/roleButtonAuth/roleDataAuth
   body: {authId: "[\"id1\",\"id2\"]", authMode: "role|depart|user"}
```

---

## 典型场景：只有张三能编辑，其他人都能看

```python
# 1. 取消列表可见和表单可见的控制（不勾选 → 所有人都能看）
req('/online/cgform/api/authColumn',
    {'cgformId':H, 'code':'f_text', 'switchFlag':1, 'listShow':False, ...})
req('/online/cgform/api/authColumn',
    {'cgformId':H, 'code':'f_text', 'switchFlag':2, 'formShow':False, ...})

# 2. 保留表单可编辑的控制（勾选 → 需授权）
req('/online/cgform/api/authColumn',
    {'cgformId':H, 'code':'f_text', 'switchFlag':3, 'formEditable':True, ...})

# 3. 权限树中只剩1个"表单可编辑"权限项，只授权给张三
req(f'/online/cgform/api/roleColumnAuth/{ZHANGSAN_ID}/{cgformId}',
    {'authId': json.dumps([FORM_EDITABLE_ID]), 'authMode': 'user'})
```

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

---

## 实战经验：按钮权限 + 字段权限完整流程

### 按钮权限（如：新增按钮只给某部门）

```
# Step 1: 查询已开启的按钮权限列表
GET /online/cgform/api/authButton/{cgformId}?pageNo=1&pageSize=10
# 返回 { buttonList: [...未启用], authList: [...已启用] }

# Step 2: 启用按钮权限控制（POST，需要完整字段）
POST /online/cgform/api/authButton
{
  "id": "已有记录id（新建可不传）",
  "code": "add",
  "page": 3,
  "cgformId": "headId",
  "type": 2,
  "control": 5,
  "status": 1
}
# 注意：type 必须是整数 2，不能是字符串 "add"

# Step 3: 授权给部门
POST /online/cgform/api/roleButtonAuth/{departId}/{cgformId}
{"authId":"[\"按钮权限记录id\"]","authMode":"depart"}
```

**内置按钮编码**: `add, edit, detail, delete, batch_delete, export, import, query, reset, aigc_mock_data, bpm, super_query, form_confirm`

### 字段权限（如：某字段只给某角色可见可编辑）

```
# Step 1: 启用字段权限
PUT /online/cgform/api/authColumn
{"cgformId":"xxx","code":"field_name","status":1}

# Step 2: 勾选控制项（列表可见/表单可见/表单可编辑）
POST /online/cgform/api/authColumn
# switchFlag=1 列表可见
{"cgformId":"xxx","code":"field_name","switchFlag":1,"listShow":true,"formShow":false,"formEditable":false}
# switchFlag=2 表单可见
{"cgformId":"xxx","code":"field_name","switchFlag":2,"listShow":false,"formShow":true,"formEditable":false}
# switchFlag=3 表单可编辑
{"cgformId":"xxx","code":"field_name","switchFlag":3,"listShow":false,"formShow":false,"formEditable":true}

# Step 3: 获取字段权限树中的权限项ID
GET /online/cgform/api/authPage/{cgformId}/1
# 返回每个勾选项的 id（同一字段可能有3个id，对应3个switchFlag）

# Step 4: 授权给角色/部门/用户
POST /online/cgform/api/roleColumnAuth/{targetId}/{cgformId}
{"authId":"[\"id1\",\"id2\",\"id3\"]","authMode":"role"}
# authMode: "role"=角色授权, "depart"=部门授权, "user"=用户授权
```

### 验证权限

```
# 查看某角色/部门/用户已授权的字段权限
GET /online/cgform/api/roleAuth?roleId={targetId}&cgformId={cgformId}&type=1&authMode=role

# 查看某角色/部门/用户已授权的按钮权限
GET /online/cgform/api/roleAuth?roleId={targetId}&cgformId={cgformId}&type=2&authMode=depart
```

### 关键注意事项

1. **按钮启用必须带完整字段**：`id, code, page, cgformId, type(整数2), control(整数5), status(整数1)`
2. **字段权限是"受控"逻辑**：勾选=需授权才能访问，未授权的人看不到
3. **按钮权限是"受控"逻辑**：启用=需授权才能看到，未授权的人看不到按钮
4. **authMode 三种**：`role`(角色)、`depart`(部门)、`user`(用户)，targetId 对应不同实体的 ID
5. **authId 格式**：JSON 字符串化的数组，如 `"[\"id1\",\"id2\"]"`
6. **重新授权会覆盖**：同一 targetId + cgformId 的授权是全量覆盖，不是增量追加。需要补充权限时必须把已有和新增的 authId 合并后一起提交

---

## 实战经验：三种授权模式完整示例

> 以下是经过验证的完整授权流程，涵盖角色/部门/用户三种 authMode 的字段权限+按钮权限+数据权限组合授权。

### 权限项 ID 查询方法

授权前必须先查出各权限项的 ID，通过 authPage 接口获取：

```bash
# 字段权限树（type=1）
GET /online/cgform/api/authPage/{cgformId}/1
# 返回格式：[{id, code, page, control, title}, ...]
# 同一字段有最多3个ID，通过 page+control 区分：
#   page=3,control=5 → 列表可见
#   page=5,control=5 → 表单可见
#   page=5,control=3 → 表单可编辑

# 按钮权限树（type=2）
GET /online/cgform/api/authPage/{cgformId}/2
# 返回格式：[{id, code, page, control}, ...]

# 数据权限有效规则
GET /online/cgform/api/validAuthData/{cgformId}
# 返回格式：[{id, ruleName, ruleColumn}, ...]
```

### 按角色授权（authMode=role）

```bash
# 查角色ID
GET /sys/role/list?roleName=管理员&pageNo=1&pageSize=5

# 字段权限：月薪+入职日期 全部可见可编辑（6个权限项ID）
POST /online/cgform/api/roleColumnAuth/{roleId}/{cgformId}
{"authId":"[\"月薪列表可见ID\",\"月薪表单可见ID\",\"月薪表单可编辑ID\",\"入职日期列表可见ID\",\"入职日期表单可见ID\",\"入职日期表单可编辑ID\"]","authMode":"role"}

# 按钮权限：导入+查询
POST /online/cgform/api/roleButtonAuth/{roleId}/{cgformId}
{"authId":"[\"importID\",\"queryID\"]","authMode":"role"}

# 数据权限：仅在职员工
POST /online/cgform/api/roleDataAuth/{roleId}/{cgformId}
{"authId":"[\"规则ID\"]","authMode":"role"}
```

### 按部门授权（authMode=depart）

```bash
# 查部门ID（推荐：关键词模糊搜索，取返回列表第一条的 id）
GET /sys/sysDepart/searchBy?keyWord={URL编码关键词}&orgCategory=1,2,3,4
# 注意：queryTreeList / queryDepartTreeSync 只返回有限层级，关键词不完全匹配时会漏掉目标部门，不推荐用于按名称查 ID

# 字段权限：入职日期仅表单可见+可编辑（不含列表可见）
POST /online/cgform/api/roleColumnAuth/{departId}/{cgformId}
{"authId":"[\"入职日期表单可见ID\",\"入职日期表单可编辑ID\"]","authMode":"depart"}

# 按钮权限：仅查询
POST /online/cgform/api/roleButtonAuth/{departId}/{cgformId}
{"authId":"[\"queryID\"]","authMode":"depart"}

# 数据权限：本部门+在职员工（多条规则组合）
POST /online/cgform/api/roleDataAuth/{departId}/{cgformId}
{"authId":"[\"本部门规则ID\",\"在职规则ID\"]","authMode":"depart"}
```

### 按用户授权（authMode=user）

```bash
# 查用户ID
GET /sys/user/list?username=jeecg&pageNo=1&pageSize=5

# 字段权限：月薪+入职日期 列表可见+表单可编辑（不含表单可见）
POST /online/cgform/api/roleColumnAuth/{userId}/{cgformId}
{"authId":"[\"月薪列表可见ID\",\"月薪表单可编辑ID\",\"入职日期列表可见ID\",\"入职日期表单可编辑ID\"]","authMode":"user"}

# 按钮权限
POST /online/cgform/api/roleButtonAuth/{userId}/{cgformId}
{"authId":"[\"queryID\"]","authMode":"user"}

# 数据权限
POST /online/cgform/api/roleDataAuth/{userId}/{cgformId}
{"authId":"[\"在职规则ID\"]","authMode":"user"}
```

### 字段权限精细控制速查

根据需求选择要授权的权限项 ID 组合：

| 需求描述 | 需要授权的权限项 |
|---------|----------------|
| 列表可见+表单可见+表单可编辑（全权限） | page=3/control=5 + page=5/control=5 + page=5/control=3 |
| 仅列表可见（表单中看不到） | page=3/control=5 |
| 列表可见+表单可见但不可编辑 | page=3/control=5 + page=5/control=5 |
| 仅表单可见+可编辑（列表不显示） | page=5/control=5 + page=5/control=3 |
| 仅表单可编辑（列表不显示、表单也看不到，但编辑时能改） | page=5/control=3 |
| 无权限（不授权该字段的任何ID） | 不包含该字段的任何 ID |

---

## 联合查询数据权限配置

> **前提条件：** 主表必须启用联合查询（`extConfigJson` 中 `joinQuery=1`），且主题风格为 normal 或 tab（ERP/innerTable 不支持联合查询）。

### 两种配置方式

#### 方式一：在子表上直接配置数据规则

直接在子表的 headId 上创建普通数据规则，无需写表别名。

**适用场景：** 规则只涉及单个子表的字段，逻辑简单。

```json
// POST /online/cgform/api/authData
// 在子表 headId 上配置
{
  "cgformId": "{子表headId}",
  "ruleName": "只查学校为中学的数据",
  "ruleColumn": "school",
  "ruleOperator": "=",
  "ruleValue": "中学",
  "status": 1
}
```

授权时也是基于子表 headId：
```
POST /online/cgform/api/roleDataAuth/{roleId}/{子表headId}
{"authId":"[\"规则ID\"]","authMode":"role"}
```

#### 方式二：在主表上配置自定义 SQL 查询子表字段

在主表 headId 上使用 `USE_SQL_RULES`，SQL 中通过**表别名**引用子表字段。

**适用场景：** 规则涉及多表联合条件、复杂 SQL 逻辑。

```json
// POST /online/cgform/api/authData
// 在主表 headId 上配置
{
  "cgformId": "{主表headId}",
  "ruleName": "自定义SQL-只查学校为中学",
  "ruleColumn": "",
  "ruleOperator": "USE_SQL_RULES",
  "ruleValue": "b.school = '中学'",
  "status": 1
}
```

授权时基于主表 headId：
```
POST /online/cgform/api/roleDataAuth/{roleId}/{主表headId}
{"authId":"[\"规则ID\"]","authMode":"role"}
```

### 表别名规则

| 表 | 别名 | 说明 |
|----|------|------|
| 主表 | `a` | 固定 |
| tabOrderNum=1 的子表 | `b` | 按序号分配 |
| tabOrderNum=2 的子表 | `c` | 按序号分配 |
| tabOrderNum=N 的子表 | 第 N+1 个字母 | 依次 `b,c,d...z` |

- **v3.6.4+**：也可直接使用完整表名代替别名，如 `demo_join_school.school = '中学'`
- `ruleColumn` 在自定义 SQL 方式下必须设为**空字符串**

### 完整示例（主子表结构）

```
主表 demo_join_main (tableType=2, joinQuery=1)
  ├── 字段: name(名称), age(年龄)
  ├── 子表1 demo_join_school (一对多, tabOrderNum=1) → 别名 b
  │     └── 字段: school(学校), phone(联系方式)
  └── 子表2 demo_join_info (一对一, tabOrderNum=2) → 别名 c
        └── 字段: nation(民族), place(籍贯)
```

**更多自定义 SQL 示例：**
```sql
-- 过滤子表1字段（等于）
b.school = '中学'

-- 过滤子表1字段（IN 多值匹配）
b.goods_name IN ('苹果','香蕉','葡萄')

-- 过滤子表2字段
c.nation = '汉族'

-- 同时过滤主表和子表
a.age > 20 AND b.school = '中学'

-- 使用系统变量
a.create_by = #{sys_user_code} AND b.school IN ('中学','大学')

-- 使用 LIKE
b.school LIKE '%中%'

-- v3.6.4+ 用完整表名
demo_join_school.school = '中学'
```

### 已有主子表后续开启联合查询 + 配置数据权限的完整流程

适用于建表时未开启联合查询，后续需要启用并配置子表字段过滤的场景：

```bash
# Step 1: 查询当前 extConfigJson（保留原值）
GET /online/cgform/head/list?tableName={表名}&copyType=0&pageNo=1&pageSize=1

# Step 2: 修改 joinQuery=1（仅改这一个字段，其余保持原值）
PUT /online/cgform/head/edit
{"id":"{headId}","extConfigJson":"{...\"joinQuery\":1,...}"}

# Step 3: 在主表上创建自定义SQL数据规则（b=tabOrderNum=1的子表别名）
POST /online/cgform/api/authData
{"cgformId":"{主表headId}","ruleName":"规则名","ruleColumn":"","ruleOperator":"USE_SQL_RULES","ruleValue":"b.goods_name IN ('苹果','香蕉','葡萄')","status":1}

# Step 4: 查询规则ID
GET /online/cgform/api/validAuthData/{主表headId}

# Step 5: 授权给角色
POST /online/cgform/api/roleDataAuth/{roleId}/{主表headId}
{"authId":"[\"规则ID\"]","authMode":"role"}
```

### 两种方式对比

| 对比项 | 方式一（子表直接规则） | 方式二（主表自定义SQL） |
|--------|---------------------|----------------------|
| 配置位置 | 子表 headId | 主表 headId |
| ruleOperator | 普通运算符(=, LIKE等) | `USE_SQL_RULES` |
| ruleColumn | 填子表字段名 | 空字符串 |
| 复杂度 | 简单，单字段条件 | 灵活，支持多表联合条件 |
| 授权位置 | 子表权限树 | 主表权限树 |

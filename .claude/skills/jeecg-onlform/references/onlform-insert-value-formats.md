---
name: Online表单插入全字段数据的经验
description: 插入数据时各控件类型的值格式和特殊字段的处理方式
type: feedback
---

Online 表单通过 API 插入数据时，各控件类型的值格式和特殊字段处理：

**Why:** 全组件表插入数据时，图片/文件/联动等字段容易留空，需要知道正确的值格式。

**How to apply:**

## 各控件类型的值格式

| 控件 | 值格式 | 示例 |
|------|--------|------|
| text/password/textarea | 字符串 | `"张三"` |
| int | **数字**（不是字符串） | `33` |
| BigDecimal | **数字**（不是字符串） | `35000` 或 `15800.50` |
| date | `yyyy-MM-dd` | `"1994-03-15"` |
| datetime | `yyyy-MM-dd HH:mm:ss` | `"2026-03-30 09:00:00"` |
| time | `HH:mm:ss` | `"08:00:00"` |
| radio/list | 字典 value 值 | `"1"` (sex 字典 1=男) |
| checkbox | 字典 value 逗号分隔 | `"2,3,4"` (hobby 字典) |
| list_multi | 值逗号分隔 | `"重要,紧急"` |
| switch | checkedValue/unCheckedValue | `"Y"` 或 `"N"` |
| image | 文件URL或路径 | `"https://static.jeecg.com/temp/xxx.png"` |
| file | 文件URL或路径 | 同 image |
| sel_user | 用户账号 username | `"admin"` |
| sel_depart | 部门 ID | `"1958496243038556161"` |
| pca | **区编码**（不是斜杠分隔！） | `"330102"` |
| umeditor | HTML 字符串 | `"<h3>标题</h3><p>内容</p>"` |
| markdown | Markdown 文本 | `"## 标题\n- 列表"` |
| sel_search | 字典表存储字段值 | `"admin"` |
| cat_tree | `sys_category.id`（节点主键），多选逗号分隔。查询方式见下方 | `"1183693424827564034"` |
| sel_tree | 树表的 ID 列值（dictText 中第1个字段） | `"1183693491043041282"` |
| link_table | 关联记录 ID | `"2038505679320702978"` |
| link_table_field | 不持久化，编辑时系统自动回填引用值 | `"北京科技有限公司"` |
| popup | popup 存储值 | `"admin"` |
| popup_dict | popup 字典存储值 | `"admin"` |
| link_down | 联动选中的 key 值（来自 dictTable JSON 配置的 key 字段） | `"1183693424827564034"` |

## pca 省市区存储格式（重要！）

pca 的存储值取决于字段的**显示级别**配置（fieldExtendJson 的 displayLevel）：

| 显示级别 | displayLevel | 存储值 | 示例 |
|---------|-------------|--------|------|
| 省市区（默认） | `"all"` | 区编码 | `"330102"` |
| 省 | `"province"` | 省编码 | `"330000"` |
| 市 | `"city"` | 市编码 | `"330100"` |
| 区 | `"region"` | 区编码 | `"330102"` |

**注意：存储的始终是最末级的编码值，不是用斜杠分隔的多级编码！**

## cat_tree 分类字典树 — 查询节点 ID 的两种方式

插入 cat_tree 字段需要先获取节点 ID（`sys_category.id`），有两种查询方式：

**方式一：通过分类编码模糊查询（推荐，获取根节点 ID）**
```
GET /sys/category/rootList?column=createTime&order=desc&pageNo=1&pageSize=10&code=*B02*
```
返回分类字典列表，从中拿到目标节点的 `id`。

**方式二：加载树子节点（获取某节点下的子节点）**
```
GET /sys/category/loadTreeData?pid={父节点ID}&pcode=0&condition=
```
- `pid` = 父节点 ID（根节点时传分类字典的 ID）
- `pcode` = 加载根节点时传类型编码（如 `B02`），加载子节点时传 `0`
- 返回 `[{key, title, leaf, ...}]`，`key` 即为节点 ID

**完整流程示例（重要！必须严格按步骤来）：**
```bash
# 1. 查询分类编码对应的根节点 ID
GET /sys/category/rootList?code=*B02*  → 拿到 B02 的 id（如 1183693424827564034）

# 2. 用根节点 ID 作为 pid，加载子节点（pcode 传 0！）
GET /sys/category/loadTreeData?pid=1183693424827564034&pcode=0&condition=
→ 返回 B02 的直接子节点（如 上衣、裤子）

# 3. 如需更深层子节点，继续用子节点 key 作为 pid 查询
GET /sys/category/loadTreeData?pid={子节点key}&pcode=0&condition=

# 4. 插入数据时用目标节点的 key 作为 category 字段值
```

**易错点：不要用 `loadTreeData?pid=0&pcode=B02` 的返回值！**
该接口返回的是所有根级分类，不是 B02 的子节点。必须先拿到 B02 的 id，再用 `pid={B02的id}&pcode=0` 加载其子节点。

## 编辑时的 `_dictText` 后缀字段

编辑接口（PUT）返回的数据中会包含系统自动翻译的 `_dictText` 后缀字段：
- `ref_record_dictText` — link_table 关联记录的显示文本
- `popup_dict_val_dictText` — popup_dict 的显示文本
- `ref_field` — link_table_field 自动回填引用值

这些字段由系统自动生成，插入时不需要传。

## 特殊字段处理

1. **image/file**: 不能通过 API 上传文件内容，但可以直接填入已有的文件 URL 路径（如系统已有的图片地址）
2. **link_down 联动**: 父级和子级都存储 key 值（通常是 ID），子级字段类型是 text 不是 link_down
3. **link_table_field**: `dbIsPersist=0`，不持久化到数据库，但编辑时系统会自动从关联记录回填值
4. **popup/popup_dict**: 存储的是 dictField 对应的值，不是显示文本
5. **checkbox**: 存储的是字典 value 逗号分隔（如 `"2,3,4"`），不是字典文本
6. **int/BigDecimal**: 传数字类型（`33`），不要传字符串（`"33"`）
7. **pca**: 传最末级编码（`"330102"`），不要传斜杠分隔的多级编码

## 默认值表达式解析（插入数据时）

前端默认值表达式在新增时由前端自动解析，但通过 API 插入数据时需要手动解析。
使用 `scripts/onlform_defval.py` 工具解析：

```python
from onlform_defval import resolve_single, resolve_default_values, init_api
init_api(api_base, token)

# 单个解析
val = resolve_single('#{date}', 'string', 'date')        # → '2026-03-30'
val = resolve_single('#{sysUserCode}', 'string', 'text')  # → 'admin'
val = resolve_single('{{+new Date()}}', 'string', 'text') # → '1774866000000'
val = resolve_single('${shop_order_num}', 'string', 'text') # → 调API获取流水号
val = resolve_single('100', 'number', 'text')             # → 100 (数字)
```

### 表达式解析规则（来源：FieldDefVal.ts）

| 表达式 | 解析方式 | Python 等价 |
|--------|---------|------------|
| `#{date}` | `dayjs().format('YYYY-MM-DD')` | `datetime.now().strftime('%Y-%m-%d')` |
| `#{time}` | `dayjs().format('HH:mm:ss')` | `datetime.now().strftime('%H:%M:%S')` |
| `#{datetime}` | `dayjs().format('YYYY-MM-DD HH:mm:ss')` | `datetime.now().strftime('%Y-%m-%d %H:%M:%S')` |
| `#{sysUserCode}` | `userInfo.username` | 调 `/sys/user/getUserInfo` 取 username |
| `#{sysUserName}` | `userInfo.realname` | 调 API 取 realname |
| `#{sysOrgCode}` | `userInfo.orgCode` | 调 API 取 orgCode |
| `#{sysUserId}` | `userInfo.id` | 调 API 取 id |
| `{{expr}}` | `new Function(expr)` 执行 | Python `eval` 模拟 |
| `${code}` | `PUT /sys/fillRule/executeRuleByCode/{code}` | 调后端 API |
| number 类型 | `Number.parseFloat(value)` | `float(value)` |

### 日期 picker 转换（date 控件 + picker 扩展）

| picker | 前端存储格式 | 转换为 | 示例 |
|--------|------------|--------|------|
| year | 年份 | `YYYY-01-01` | `2026-01-01` |
| month | 年-月 | `YYYY-MM-01` | `2026-03-01` |
| week | 年-周 | 该周周一的日期 | `2026-03-24` |
| quarter | 年-季度 | 季度第一天 | `2026-01-01`(Q1) |

### 混用规则
- `#{}` 和 `{{}}` **可以混用**（如 `#{sysUserName}-#{date}`）
- `${}` 填值规则**不能与 `#{}` 或 `{{}}` 混用**
- `${}` 一个字段只能写一个

## 插入/编辑 API
```
新增: POST /online/cgform/api/form/{headId}?tabletype=1
编辑: PUT  /online/cgform/api/form/{headId}?tabletype=1  (body 需含 id 字段)
```
新增直接传 JSON body；编辑需先 GET 获取原记录再合并修改字段。

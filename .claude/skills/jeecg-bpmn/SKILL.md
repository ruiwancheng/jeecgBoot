---
name: jeecg-bpmn
description: Use when user asks to create/generate/edit/modify a BPM workflow, design a Flowable BPMN process, or says "创建流程", "生成流程", "新建流程", "设计流程", "画流程", "审批流程", "工作流", "BPM", "BPMN", "create flow", "create process", "new workflow", "generate workflow". Also triggers when user describes an approval chain like "先经理审批再HR审批" or mentions process nodes like "开始→审批→网关→结束". Also triggers for OA application creation: "创建OA应用", "创建审批单", "创建报销单", "创建请假单", "做一个OA表单带流程", "一键创建表单和流程", "create OA app", "create approval form with workflow". Also triggers for ANY operation on existing processes: "编辑流程", "修改流程", "删除监听器", "添加监听器", "删除节点", "添加节点", "修改节点", "配置节点", "流程中的", "edit process", "modify process", "delete listener", "add listener", "remove listener", "add node", "delete node", "configure node". Key rule: whenever user mentions a specific process name (like "网关测试") with any modification intent, this skill MUST be invoked FIRST before any manual API exploration.
---

# JeecgBoot BPM 流程自动生成器

将自然语言的流程描述转换为 Flowable BPMN 2.0 XML，并通过 API 在 JeecgBoot 系统中自动创建流程。

## 临时配置文件规则（强制）

所有传给脚本的 `--config <xxx.json>` 必须写到 **`{系统临时目录}/{SKILL_NAME}/`** 下，由操作系统自动清理；skill 与脚本均不主动删除该目录或文件。

```python
import tempfile, os, json

SKILL_NAME = "jeecg-bpmn"               # 技能名称
skill_dir = os.path.join(tempfile.gettempdir(), SKILL_NAME)
os.makedirs(skill_dir, exist_ok=True)          # 确保目录存在，不主动检查

config_path = os.path.join(skill_dir, 'sk_audit_create.json')   # 示例文件名
with open(config_path, 'w', encoding='utf-8') as f:
    json.dump(cfg, f, ensure_ascii=False, indent=2)
```

`tempfile.gettempdir()` 自动适配：Windows `%TEMP%`、Linux `/tmp`、macOS `/var/folders/.../T`（注意 macOS 并非 `/tmp`）。  
文件名建议使用 **`<表名>_<步骤>.json`**（如 `sk_audit_create.json`），无需重复技能前缀，因路径已包含技能名称，便于排错。

** 禁止：**

- 写到 `<skill>/tmp/` 或当前工作目录（污染 skill / 用户项目）
- 硬编码 `/tmp`、`C:\Temp` 或任何固定路径（不跨平台）
- 每步完成后主动 `rm` / `Remove-Item`（操作系统会清理，属多余 tool call）
- 主动 `os.path.exists()` 检查（其本身即为一次 tool call）  
  （使用 `os.makedirs(…, exist_ok=True)` 满足需求，不算主动检查）

**临时文件可能被操作系统异步清理**，但仍遵循 **乐观调用 + 报错补救**：仅当脚本返回 `FileNotFoundError` 或 `配置文件不存在` 时，使用相同内容、**在相同的 `{系统临时目录}/{SKILL名称}/` 路径下重写**（重写前仍需 `os.makedirs(skill_dir, exist_ok=True)` 确保目录存在），切勿更换路径或回退至 skill 目录。

## 介绍组件时的完整性要求

> **重要：** 当用户要求介绍流程设计器各组件时，必须包含以下内容，不可遗漏：
>
> 1. **会签节点**：串行/并行两种模式；全部通过/一人通过/半数通过/按比例/自定义 5种通过规则；指定人员/角色/审批角色/部门/岗位/职级/表单字段/流程变量 8种审批人类型
> 2. **条件表达式**：系统内置流程变量（`result`、`applyUserId`、`applyDate` 等）；13种条件运算符；多条件组合用法（AND/OR）
> 3. **监听器**：执行监听器/任务监听器/全局事件监听器三种类型；系统预置监听器（ProcessEndListener必需、TaskSkipApprovalListener、TaskCreatedAutoSubmitListener等）；taskExtendJson 节点行为控制字段说明

## 性能规范与已验证规律

> **⚠️ 禁止预防性读取参考文档。** 执行任务前不要为了"以防万用"而读取 references/ 下的文档。只在遇到具体问题时按需读取，且使用 offset/limit 指定行范围。
>
> **⚠️ 对外部 API 响应结构，先用小脚本探测，再写主逻辑。** 但下方速查表中**已验证的数据不需要重新探测**。
>
> **⚠️ 用不熟悉的 Python 模块前，必须先 `dir()` 查 exports。** 但下方速查表中**已验证的模块不需要重新 dir()**。
>
> **⚠️ 禁止对 API 响应的 `result` 直接做 `[:]` 切片。** JeecgBoot API 的 `result` 格式不统一：分页接口返回 dict `{"records": [...], "total": N}`，全量接口返回 list `[...]`，写操作返回 string。对 dict 做切片 → `KeyError: slice(None, 5, None)`。**强制规则：取值前必须根据「API 响应速查」表确定 result 类型，分页接口统一用 `.get('result', {}).get('records', [])`，全量接口用 `isinstance(result, list)` 判后再切片。**

### 模块导入（固定模式，直接复用）

```python
import os, pathlib, sys
_SKILLS_DIR = pathlib.Path.home() / '.claude' / 'skills'
sys.path.insert(0, str(_SKILLS_DIR / 'jeecg-desform' / 'scripts'))  # desform_creator, desform_utils
sys.path.insert(0, str(_SKILLS_DIR / 'jeecg-bpmn'    / 'scripts'))  # bpmn_creator, bpmn_oa
sys.path.insert(0, str(_SKILLS_DIR / 'jeecg-system'  / 'scripts'))  # system_utils
os.chdir(str(_SKILLS_DIR / 'jeecg-bpmn' / 'scripts'))
import desform_utils as du; du.init_api(API_BASE, TOKEN)  # ⚠ 必须初始化，否则 ValueError: unknown url type
import desform_creator as dc  # 无需初始化
import bpmn_creator as bc     # 无需初始化，各函数直接传 api_base/token
# system_utils 需要: from system_utils import init_api, ...; init_api(API_BASE, TOKEN)
```

### 函数返回值速查

| 函数 | 返回类型 | 正确取值 |
|------|---------|---------|
| `dc.create_form(...)` | tuple `(form_id, title_field_model)` | `result[0]` |
| `dc.get_form_id(code)` | tuple `(form_id, index)` | `result[0]` |
| `bc.get_desform_fields(api_base, token, code)` | dict `{label: {model, key, type}}` | `fields.get('薪资', {}).get('model')` |
| `bc.authorize_form(...)` | dict（**不是** tuple） | `r = bc.authorize_form(...)` |
| `du.get_form_fields(code)` | list `[{name, model, type}]` | 返回表单字段列表。**注意：不存在 `du.get_form_detail()`** |

### API 响应速查

| API / 操作 | 返回值 | 正确取值 |
|-----------|--------|---------|
| `saveProcess` | dict | `result['obj']` 含新ID（编辑时可能 null，按 processKey 查）。路径：`/act/designer/api/saveProcess`，Content-Type：`application/x-www-form-urlencoded` |
| `extActProcess/queryById` | dict | `result` 含流程全字段；`result['processXml']` 为 **base64 编码**的 XML，需 `base64.b64decode().decode('utf-8')` |
| `sys/sysDepart/add` | `result=null` | 新建后用 `queryDepartAndPostTreeSync` 全量查找 |
| `approvalRole/rootList` | `result.records[]`（**不是**裸数组） | `r['result']['records']`，每条 `{id, name, type, pid}` |
| `approvalRole/childList?pid=xxx` | `result.records[]`（**不是**裸数组） | `r['result']['records']` |
| `approvalRole/group/add` | `result="添加成功！"`（字符串，不是 ID） | 创建后调 `rootList` 按 name 查 ID |
| `approvalRole/role/add` | `result="添加成功！"`（字符串，不是 ID） | 创建后调 `childList` 按 name 查 ID |
| `sys/position/list` | `result.records[]` | 每条 `{id, name, code}`，用于 deptPosition 审批人 |
| `query_approval_roles()` | `{'roles': [...], 'persons': [...]}` | 用 `find_approval_role(keyword)` |
| `query_dept_positions()` | depart 树节点（`departName` 不是 `name`） | 过滤 `orgCategory=='3'` |

### 关键函数签名

| 函数 | 签名 |
|------|------|
| `du.create_form` | `(name, code, widgets, title_index=0, layout='auto', ...)` |
| `bc.edit_node_config` | `(api_base, token, process_id, node_code, node_settings)` |
| `bc.set_node_field_permissions` | `(api_base, token, process_id, node_code, form_code, field_permissions, form_type='2')` |

### 其他关键规律

- `dc.DIVIDER/USER/MONEY` 等常量**是函数不是字符串**，创建 widget 用 `dc.build_widget({'type':'money', 'name':'金额', 'required': True})`
- `build_widget` 对**所有控件类型都强制要求 `name` 字段**（含 divider：`{'type': 'divider', 'name': '---', 'text': '标题'}`）
- `build_widget` 合法 `type` 清单：基础 `input textarea number integer money date time switch slider rate color` / 选择 `radio select checkbox` / 系统 `select-user select-depart select-depart-post phone email area-linkage org-role` / 文件 `file-upload imgupload hand-sign` / 高级 `auto-number formula barcode location table-dict select-tree link-record link-field capital-money text-compose ocr map summary editor markdown` / OA `oa-approval-comments` / 布局 `tabs grid card divider text buttons`
- DesForm 字段在 `design["list"]` 下（不是 `design["fields"]`），嵌套结构需递归提取：
  ```python
  def find_fields(node, results):
      if isinstance(node, dict):
          if node.get('type') not in ('grid','text','') and node.get('model'):
              results.append(node)
          for v in node.values(): find_fields(v, results)
      elif isinstance(node, list):
          for item in node: find_fields(item, results)
  fields = []; find_fields(design, fields)
  ```
- `userTask` 含会签时 XML 子元素顺序：`extensionElements` → `incoming`/`outgoing` → `multiInstanceLoopCharacteristics`（顺序错报 `cvc-complex-type.2.4.a`）
- 条件表达式必须调 `bc.build_condition_b64()`，手写格式：外层**数组** `[{"logic":"and","conditions":[...]}]`，`flowUtil.evaluateExpression` 需**三参数** `(execution, 'b64', 'and')`
- 手工分支 + 网关组合 → 自动使用水平多行布局（`_detect_horizontal_multirow`），`W_GAP=60, MAIN_CY=330, LOWER_CY=540`
- **包含网关（inclusiveGateway）带 default flow 时**：default flow 从 split 直达 join（无中间节点），`_detect_parallel_blocks` 已支持空链检测，`calc_layout` 只对非空分支做水平展开（已修复，此前空链导致检测失败、分支垂直堆叠重叠）
- 子流程必须先于表单创建，否则表单关联冲突（修复：DELETE 子流程 formId 再重新 link_form）
- `bpmn_oa.py` 支持 `subprocess` 键一键创建子流程，自动填充 `calledElement`
- 手写子流程必须加 `"isSubProcess": True`（`bpmn_oa.py` 的 `_setup_oa_subprocess` 已自动设置）
- **system_utils 函数**：查岗位 `query_dept_positions(dept_id=None)` / 查角色 `find_approval_role(keyword)` 返回 dict 或 None / 岗位列表 `GET /sys/position/list` / **不存在** `/sys/position/rank/list` `/sys/duty/list`
- **不存在的 API（禁止尝试）**：`queryDepartTreeSync?pid=xxx` `queryIdTree` `queryTreeList` `queryMyDept` `loadNodeGroupData?groupType=deptPosition` `queryByKeywords` `sysDepart/list` `recycleBin/*`
- **审批角色查找或创建模式**（防重复 + 获取真实 ID）：
  ```python
  def find_or_create_approval_role(name, grp_id):
      def query_id():
          r = api_get(f'/sys/approvalRole/childList?pid={grp_id}')
          return next((c['id'] for c in r.get('result',{}).get('records',[]) if c['name']==name), None)
      rid = query_id()
      if not rid:
          api_post('/sys/approvalRole/role/add', {'name': name, 'pid': grp_id})
          rid = query_id()
      return rid
  ```
- **`bc.edit_node_config` 不更新 `nodeConfigJson`（已踩坑）**：该函数只做 `node.update(settings)` 后 PUT，**不同步 `nodeConfigJson` 字段**。前端读 `nodeConfigJson.formEditStatus` 时仍为 false，导致可编辑节点实际不可编辑。**凡需设置 `formEditStatus=1` 的节点，必须手动同步更新 `nodeConfigJson`**，正确写法：
  ```python
  def fix_node_form_edit(api_base, token, process_id, node_code, url):
      """设 formEditStatus=1 并同步 nodeConfigJson（edit_node_config 不做这步）"""
      r = bc.api_request(api_base, token,
          f'/act/process/extActProcessNode/list?processId={process_id}&pageNo=1&pageSize=50',
          method='GET')
      for node in (r.get('result') or {}).get('records', []):
          if node.get('processNodeCode') == node_code:
              node['formEditStatus'] = '1'
              node['modelAndView'] = url
              node['modelAndViewMobile'] = url
              try:
                  cfg = json.loads(node.get('nodeConfigJson') or '{}')
              except Exception:
                  cfg = {}
              cfg['formEditStatus'] = True          # ← 关键：必须同步
              node['nodeConfigJson'] = json.dumps(cfg, ensure_ascii=False)
              return bc.api_request(api_base, token,
                  '/act/process/extActProcessNode/edit', data=node, method='PUT')
  ```
  > `set_draft_nodes_editable` 已内置此逻辑；只有直接调 `edit_node_config` 设 formEditStatus 时需要用上述替代函数。
- **子流程节点禁止使用 `draft=True`（已踩坑）**：在被 `callActivity` 调用的子流程中，任何节点都不能设 `draft=True`。原因：`draft=True` 会为节点添加 `TaskCreatedAutoSubmitListener`，callActivity 启动子流程时该监听器立即自动提交任务，此时子流程 execution 仍处于中间态，写入 `ACT_RU_VARIABLE` 时 `EXECUTION_ID_` 无效，触发 FK 约束失败（`ACT_FK_VAR_EXE`）。子流程中需要表单可编辑的节点，改用 `fix_node_form_edit` 显式设置 `formEditStatus=1` 即可。

### 规则3：URL 中含中文参数必须用 urllib.parse.quote 编码（⚠️ 强制）

```python
# ✅ 正确
import urllib.parse
keyword = urllib.parse.quote('安全评审')
url = f'{API_BASE}/sys/approvalRole/search?keyword={keyword}'
# 或用 urlencode：params = urllib.parse.urlencode({'keyword': '安全评审'})
```

### 规则4：独立的系统数据查询必须合并到单个脚本一次执行（⚠️ 强制）

不要分多轮 Bash 调用执行独立查询，合并到一个脚本里一次运行。

### 规则5：部门/岗位查询只能用 queryDepartAndPostTreeSync（⚠️ 强制）

```python
req = urllib.request.Request(f'{API_BASE}/sys/sysDepart/queryDepartAndPostTreeSync', headers=HEADERS)
result = json.loads(urllib.request.urlopen(req).read().decode())['result'] or []
def flatten(nodes, acc=None):
    if acc is None: acc = []
    for n in (nodes or []):
        if isinstance(n, dict):
            acc.append(n)
            flatten(n.get('children', []), acc)
    return acc
all_nodes  = flatten(result)
depts      = [n for n in all_nodes if str(n.get('orgCategory','')) == '2']
positions  = [n for n in all_nodes if str(n.get('orgCategory','')) == '3']
```

### 规则6：DesForm 表单编码被回收站占用时直接换编码（⚠️ 强制）

`desform/add` 返回 `"该code已存在"` 但 `desform/list` 查不到 → 回收站占用。直接加后缀 `_v2`，禁止尝试 recycleBin API（均 404）。

### 规则7：含 `${...}` 的 Python 脚本禁止用 `python -c "..."` 执行（⚠️ 强制）

**现象：** `bash: bad substitution`，Python 根本没启动。

**根因：** bash 双引号内的 `${...}` 会被当作 shell 变量展开。Python f-string 中的 `f'${{{model}}}'`（生成 DesForm URL 占位符如 `${BPM_DES_DATA_ID}`）触发 bash 的非法变量名错误。

**强制规则：凡是脚本含 `${` 的，必须写入 `.py` 文件再执行，不得用 `-c "..."`。**

```bash
# ❌ 错误 —— bash 会展开 ${...}，报 bad substitution
python -X utf8 -c "
...
f'${{{model}}}提交的申请'
"

# ✅ 正确 —— 写文件，bash 不解析文件内容
# Write tool 写入 C:\Users\25067\tmp_script.py，然后：
powershell -Command "& python -X utf8 C:\Users\25067\tmp_script.py"
powershell -Command "Remove-Item 'C:\Users\25067\tmp_script.py'"
```

### 规则8：Scenario A 子流程创建后必须立即删除其表单绑定（⚠️ 强制）

**现象：** 主流程 `link_form` 报 `"编码重复或表名已被授权流程！"`。

**根因：** `bpmn_oa._setup_oa_subprocess` 内部会将主流程的 `form_code` 关联到子流程（`extActProcessForm`），后端对 `relationCode` 有唯一约束，导致主流程随后绑定同一表单失败。

**强制规则：** 调用 `_setup_oa_subprocess` 后，主流程 `link_form` 前，必须先删除子流程的表单绑定：

```python
# _setup_oa_subprocess 执行完之后立即执行：
import urllib.parse as _up
q = _up.urlencode({'processId': sub_pid, 'pageNo': 1, 'pageSize': 10})
sub_forms = bc.api_request(API_BASE, TOKEN,
    f'/act/process/extActProcessForm/list?{q}', method='GET')
for rec in (sub_forms.get('result') or {}).get('records', []):
    bc.api_request(API_BASE, TOKEN,
        f'/act/process/extActProcessForm/delete?id={rec["id"]}', method='DELETE')
# 之后再 link_form 到主流程
```

> 此步骤不影响子流程运行——Scenario A 子流程通过 `JG_SUB_MAIN_PROCESS_ID` 共享主流程数据，无需自己独立绑定表单。

### 规则9：API 响应遍历前必须做类型检查（⚠️ 强制）

**现象：** `'str' object has no attribute 'get'` 或 `KeyError: 0`，程序崩溃。

**根因：** 部分 API 的 `result` 字段结构不固定，可能是 `dict`（含 `records` 键）、裸 `list`、或 `str`。直接用 `[0]` 或 `.get()` 导致类型错误。

**强制规则：凡是遍历 API 响应 `result` 的，必须先 `isinstance` 检查和 `print(type(result))` 确认结构。**

```python
# ❌ 错误 —— 假设 result 一定是 list
for item in r['result']:  # 实际是 dict，抛出 KeyError
    print(item['name'])

# ✅ 正确 —— 先查验结构再遍历
result = r.get('result', [])
if isinstance(result, dict):
    records = result.get('records', [])
elif isinstance(result, list):
    records = result
else:
    records = []
for item in records:
    print(item.get('name'))
```

### 规则10：复杂流程（含网关/会签/多种审批人）先 dry-run 验证 XML（⚠️ 推荐）

**现象：** 直接调用 API 创建复杂流程后，发现 taskExtendJson 配置不正确或布局错乱，需要删除重建。

**推荐流程：**
```bash
# 第一步：dry-run 只生成 XML，不调 API
python "<skill目录>/scripts/bpmn_creator.py" \
    --api-base <URL> --token <TOKEN> --config <config.json> --dry-run

# 第二步：人工或脚本检查 XML 中的关键元素
#   - taskExtendJson 的 sameMode/skipOne 值是否正确
#   - assignee/candidateUsers/candidateGroups 属性是否存在
#   - countersign/multiInstance/timer 等是否正确生成
#   - 条件表达式的 field 字段 model 是否匹配 DesForm 实际字段

# 第三步：确认无误后再正式创建（去掉 --dry-run）
python "<skill目录>/scripts/bpmn_creator.py" \
    --api-base <URL> --token <TOKEN> --config <config.json> --link-form
```

### 规则11：编辑已有流程 XML 时，正则必须兼容 `bpmn2:` 命名空间前缀（⚠️ 强制）

**现象：** 用 `<userTask` 匹配开标签，实际 XML 是 `<bpmn2:userTask`，正则命中失败，脚本报"未找到节点"。

**根因：** JeecgBoot 生成的 BPMN XML 固定使用 `bpmn2:` 命名空间前缀，所有 BPMN 元素名均带前缀（`bpmn2:userTask`、`bpmn2:endEvent`、`bpmn2:sequenceFlow` 等）。

**强制规则：凡是用正则操作已有 BPMN XML，所有元素名必须加 `(?:bpmn2:)?` 前缀。**

```python
# ❌ 错误 —— 匹配不到 <bpmn2:userTask ...>
pattern = rf'(<userTask[^>]*\bid="{node_code}"[^>]*>)'

# ✅ 正确 —— 兼容有/无 bpmn2: 前缀两种写法
pattern = rf'(<(?:bpmn2:)?userTask[^>]*\bid="{re.escape(node_code)}"[^>]*>)'
```

### 规则12：`candidateUsersExpression` 类型在 XML 中不加任何 `groupType`（⚠️ 强制）

**现象：** 写了 `groupType="candidateUsersExpression"`（无 `flowable:` 前缀）导致发布失败：
```
cvc-complex-type.3.2.2: 元素 'bpmn2:userTask' 中不允许出现属性 'groupType'
```

**根因：** BPMN 标准不允许无命名空间的自定义属性。只有带 `flowable:` 前缀的属性（`flowable:groupType`）才合法。而 `candidateUsersExpression` 类型（`bpmn_creator.py` 368行）**本身就不生成任何 groupType 属性**。

**各审批人类型 groupType 规则（来自 `bpmn_creator.py`）：**

| 类型 | XML 属性 | groupType |
|------|---------|-----------|
| `expression` / `assignee` / `candidateUsers` | `flowable:assignee` / `flowable:candidateUsers` | **无** |
| `candidateUsersExpression` | `flowable:candidateUsers="${表达式}"` | **无** |
| `role` | `flowable:candidateGroups` | `flowable:groupType="role"` |
| `approvalRole` | `flowable:candidateUsers="${flowUtil...}"` | `flowable:groupType="approvalRole"` |
| `dept` | `flowable:candidateGroups` | `flowable:groupType="dept"` |
| `deptPosition` | `flowable:candidateGroups` | `flowable:groupType="deptPosition"` |
| `position` | `flowable:candidateUsers="${oaFlowExpression...}"` | `flowable:groupType="position"` |

**强制规则：手写 XML 审批人属性前，必须先查 `bpmn_creator.py` 中对应 type 的生成代码（约 363-395 行），禁止凭记忆猜测。**

### 规则13：手动调用 `saveProcess` 必须用 form-urlencoded + 正确路径（⚠️ 强制）

**现象：** 调用 `/act/process/extActProcess/saveProcess` 报"路径不存在"。

**根因：** `saveProcess` 的正确路径是 `/act/designer/api/saveProcess`，且必须用 `application/x-www-form-urlencoded` 编码，不能用 JSON。

**强制规则：手动调用 saveProcess 必须严格按以下模板，禁止猜测路径或 Content-Type。**

```python
import urllib.parse

save_data = {
    'processDefinitionId': process_id,          # 已有流程ID（新建传 '0'）
    'processName':  process_detail['processName'],
    'processkey':   process_detail['processKey'],  # ⚠ 字段名是 processkey（全小写）
    'typeid':       process_detail.get('processType', 'oa'),  # ⚠ 字段名是 typeid（全小写）
    'lowAppId': '',
    'params': '',
    'nodes': nodes_str,                          # 见下方 nodes_str 构建方式
    'processDescriptor': xml,                    # 原始 XML 字符串（非 base64）
    'realProcDefId': '',
    'startType': process_detail.get('startType', 'manual'),
}

# nodes_str 构建：只含 userTask 节点，格式 id=xxx###nodeName=xxx@@@
nodes_str = ''.join(
    f'id={n["processNodeCode"]}###nodeName={n["processNodeName"]}@@@'
    for n in node_records  # 来自 extActProcessNode/list
)

form_body = urllib.parse.urlencode(save_data).encode('utf-8')
req = urllib.request.Request(
    f'{API_BASE}/act/designer/api/saveProcess',
    data=form_body,
    headers={**HEADERS, 'Content-Type': 'application/x-www-form-urlencoded'},
    method='POST'
)
r = json.loads(urllib.request.urlopen(req).read().decode('utf-8'))
```

> 查询流程 XML：`GET /act/process/extActProcess/queryById?id={id}`，返回的 `processXml` 是 **base64 编码**，用 `base64.b64decode(xml_b64).decode('utf-8')` 解码；`processDescriptor` 传**原始 XML 字符串**。

### 规则14：编辑已有流程前必须先 Grep 确认，不得猜测（⚠️ 强制）

**现象：** 手写脚本时错误路径、错误属性名导致多轮失败，整体执行慢。

**根因：** 执行前未查阅 `bpmn_creator.py` 源码就直接猜测 API 路径和 XML 属性，导致每次报错后才发现问题，反复修改脚本。

**强制规则：编辑已有流程 XML 或调用 saveProcess 前，必须先用 Grep 查阅 `bpmn_creator.py` 的相关代码，确认后再写脚本。探查信息必须合并到单个脚本一次获取，严禁分多个探查脚本串行执行。**

```python
# 编辑流程前的必查清单（用 Grep，不要靠记忆）：
# 1. saveProcess 路径：grep "saveProcess" bpmn_creator.py → /act/designer/api/saveProcess
# 2. 目标审批人类型的 XML 生成：grep "candidateUsersExpression" bpmn_creator.py → 无 groupType
# 3. 已有 XML 的节点命名空间：先探查 XML 打印节点开标签，确认是否有 bpmn2: 前缀
```

### 规则16：条件 fieldType 必须与 DesForm 字段实际类型完全一致（⚠️ 严重）

**现象：** 条件规则配置面板中，字段和运算符正常显示，但值输入框为空（"请选择部门"占位符），"原始JSON数据"中条件值字段完全缺失。条件保存后无法生效。

**根因（双重）：**
1. 条件值字段名必须用 **`expectedValue`**，前端读的是 `expectedValue` 而非 `value`——传 `value` 时前端完全忽略，显示为空
2. `fieldType` 必须与 DesForm 字段实际类型完全一致，否则前端规范化时丢弃 `expectedValue`

**强制规则：conditionExpression 中每个 condition 必须同时满足：**
- 字段名用 `expectedValue`（**不是** `value`）
- `fieldType` 与 DesForm 字段 `type` 完全一致

| DesForm 字段 `type` | condition 中的 `fieldType` |
|---------------------|--------------------------|
| `select-depart` | `"select-depart"` |
| `select-user` | `"select-user"` |
| `checkbox` | `"checkbox"` |
| `select` / `radio` | `"select"` / `"radio"` |
| `money` | `"money"` |
| `integer` | `"integer"` |
| `input` / `textarea` | `"input"` |
| `date` | `"date"` |

```python
# ✅ 正确 —— expectedValue + 正确 fieldType
cond = {"field": "select_depart_xxx", "fieldType": "select-depart", "fieldName": "所在部门",
        "operator": "eq", "expectedValue": "dept_id_here"}

cond = {"field": "money_xxx", "fieldType": "money", "fieldName": "报销金额",
        "operator": "lt", "expectedValue": "1000"}

# ❌ 错误 —— 用 "value" 代替 "expectedValue"，前端完全忽略，显示空白
cond = {"field": "money_xxx", "fieldType": "money", "fieldName": "报销金额",
        "operator": "lt", "value": "1000"}

# ❌ 错误 —— fieldType 与实际类型不符，前端规范化时丢弃 expectedValue
cond = {"field": "select_depart_xxx", "fieldType": "input", ...}
```

> `fieldType` 直接用 `bc.get_desform_fields()` 返回的 `info['type']`，**禁止手动映射或猜测**。

---

### 规则17：`position` 类型审批人表达式必须传三个参数（⚠️ 严重）

**现象：** 前端"职务级别"选择框为空（"请选择职务级别"占位符），"开启职级表达式"勾选但无值，职级审批人实际为空，流程无法正常流转。

**根因：** `oaFlowExpression.getApplyUserDeptPositionLevel` 需要三个参数：`(sys_org_code, applyUserId, positionId)`，传两个参数时方法签名不匹配，前端解析表达式提取 positionId 失败，显示为空。

**强制规则：**

```xml
<!-- ✅ 正确 —— 三个参数 -->
flowable:candidateUsers="${oaFlowExpression.getApplyUserDeptPositionLevel(sys_org_code, applyUserId, 'positionId')}"
flowable:groupType="position"

<!-- ❌ 错误 —— 用 execution 代替前两个参数，只有两个参数 -->
flowable:candidateUsers="${oaFlowExpression.getApplyUserDeptPositionLevel(execution, 'positionId')}"
```

对应 JSON 配置：
```json
{"type": "position", "value": "1958471111989067778"}
```
`bpmn_creator.py` 第389行已正确生成三参数形式，**手写 XML 时必须严格按此格式，禁止简化参数列表**。

---

### 规则18：探查 XML 行内容必须用 `repr()` 打印原始字符串（⚠️ 强制）

**现象：** 打印 XML 行时只用 `print(line)`，看不出行尾是否还有其他标签（如 `</bpmn2:extensionElements>`），写删除逻辑时整行删掉导致结构损坏，deploy 失败。

**根因：** `print(line)` 不显示行边界，无法判断一行内是否同时包含多个标签。

**强制规则：探查 XML 行内容时，必须用 `repr(line)` 打印，以便看清行尾是否还有其他内容。**

```python
# ❌ 错误 —— 看不出行尾有 </bpmn2:extensionElements>
for i, line in enumerate(xml.splitlines()):
    if 'TestExecutionListener' in line:
        print(f'L{i+1}: {line}')

# ✅ 正确 —— repr 显示完整内容，含行尾隐藏标签
for i, line in enumerate(xml.splitlines()):
    if 'TestExecutionListener' in line:
        print(f'L{i+1}: {repr(line)}')
# 输出: L20: '      <flowable:executionListener .../></bpmn2:extensionElements>'
# 可见行尾还有 </bpmn2:extensionElements>，删除时必须保留该部分
```

**删除行内标签的正确模式：** 只删标签本身，保留同行其他内容：

```python
lines = xml.splitlines(keepends=True)
new_lines = []
for line in lines:
    if 'TestExecutionListener' in line:
        # 只删 executionListener 标签，保留同行剩余内容（如 </bpmn2:extensionElements>）
        cleaned = re.sub(r'\s*<flowable:executionListener[^>]*TestExecutionListener[^>]*/>', '', line)
        if cleaned.strip():          # 有剩余内容则保留
            new_lines.append(cleaned)
        # 否则整行丢弃（行内无其他内容）
    else:
        new_lines.append(line)
```

---

### 规则19：`saveProcess` 成功即持久化，deploy 失败不回滚（⚠️ 强制）

**现象：** `saveProcess` 返回 `success=True`，随后 `deployProcess` 失败。再次读取流程 XML 时，发现已是 saveProcess 提交的（可能损坏的）版本，而非原始版本。

**根因：** `saveProcess` 和 `deployProcess` 是两个独立操作，`saveProcess` 一旦成功即写入数据库，deploy 失败不会回滚 save。

**强制规则：在调用 `saveProcess` 之前，必须先用 dry-run 或本地验证确认 XML 结构合法，不要依赖 deploy 失败来发现 XML 错误。**

```python
# 保存前验证 XML 结构（最简验证）
import xml.etree.ElementTree as ET
try:
    ET.fromstring(xml_new)
    print('XML 结构合法 ✓')
except ET.ParseError as e:
    print(f'XML 结构错误，禁止保存: {e}')
    exit(1)
```

---

### 规则15：抄送配置必须写入 BPMN XML 的 ccConfigJson，不得写 nodeConfigJson（⚠️ 强制）

**现象：** 将 ccConfig 写入 `extActProcessNode` 的 `nodeConfigJson` 字段，前端抄送人面板显示为空，配置不生效。

**根因：** 前端读取的是 BPMN XML 中 `<flowable:ccConfigJson value="..."/>` 标签（base64 编码），`nodeConfigJson` 不是抄送人的存储位置。

**强制规则：凡是添加或修改节点抄送人，必须修改 BPMN XML，在对应 userTask 的 `extensionElements` 内插入/替换 `flowable:ccConfigJson`，再通过 `saveProcess` 重新保存并发布。禁止将 ccConfig 写入 `nodeConfigJson`。**

```python
import json, base64, re

# 1. 构建 ccConfigJson base64
cc_list = [{"type": "submitter_parent_dept_leader"}]
cc_b64 = base64.b64encode(json.dumps(cc_list, ensure_ascii=False).encode('utf-8')).decode('utf-8')

# 2. 在 XML 中插入（找到节点的 extensionElements 结束标签前插入）
node_match = re.search(r'(<(?:bpmn2:)?userTask[^>]*\bid="task_draft"[^>]*>)', xml)
node_start = node_match.end()
ext_close = re.search(r'</(?:bpmn2:)?extensionElements>', xml[node_start:])
insert_pos = node_start + ext_close.start()
last_flowable = re.findall(r'(\s+)<flowable:', xml[node_start:node_start + ext_close.end()])
indent = last_flowable[-1] if last_flowable else '\n        '
cc_tag = f'{indent}<flowable:ccConfigJson value="{cc_b64}" />'
xml_new = xml[:insert_pos] + cc_tag + xml[insert_pos:]

# 3. saveProcess + deployProcess（见规则13）
```

---

### 规则20：callActivity `flowable:in` 变量传参必须用 `source`，不得用 `sourceExpression`（⚠️ 强制）

**现象：** 前端「自定义输入变量」弹窗中，**源头(Source)** 字段为空，只有目标(Target)有值；但实际 XML 中写的是 `sourceExpression="${assigneeUserId}"`。

**根因：** 前端解析 `flowable:in` 元素时，只读取 `source` 属性填充 Source 字段，`sourceExpression` 属性被忽略，因此显示为空白。

**强制规则：会签 callActivity 传递 `assigneeUserId` 时，必须使用 `source`，不能使用 `sourceExpression`。**

```xml
<!-- ❌ 错误 —— 前端 Source 显示为空 -->
<flowable:in sourceExpression="${assigneeUserId}" target="assigneeUserId" />

<!-- ✅ 正确 —— 前端正常显示 assigneeUserId -->
<flowable:in source="assigneeUserId" target="assigneeUserId" />
```

> `assigneeUserId` 在多实例循环中已通过 `flowable:elementVariable="assigneeUserId"` 自动成为流程变量，直接用 `source` 传递即可，效果等价。

---

### 规则21：向已有流程插入节点后，必须完整重写 BPMNDiagram 区域，禁止增量偏移坐标（⚠️ 强制）

**现象：** 在中间插入一个节点后，对 DI 区域做「y > 阈值 则 y += SHIFT」的全局偏移，导致连线 waypoint 混乱、分支线变形、网关连线断裂。

**根因：** 增量偏移逻辑无法准确区分「主干点」与「分支中间过渡点」，网关分支的中间 waypoint（如 y=296、y=416 等中转坐标）被错误偏移，造成连线弯折方向错误。

**强制规则：凡是向已有 BPMN 流程中插入或删除节点，必须按新的节点序列从零重新计算并重写整个 `<bpmndi:BPMNDiagram>` 区块，不得对已有 DI 坐标做增量加减。**

```python
# ❌ 错误 —— 增量偏移，连线必然混乱
di_part_new = re.sub(r'y="(\d+)"', lambda m: f'y="{float(m.group(1))+130}"' if float(m.group(1)) > 186 else m.group(0), di_part)

# ✅ 正确 —— 完整重写 BPMNDiagram
NEW_DI = """  <bpmndi:BPMNDiagram id="BPMNDiagram_1">
    <bpmndi:BPMNPlane ...>
      <!-- 按新节点顺序逐一列出所有 Shape 和 Edge，坐标从零计算 -->
      ...
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>"""

di_start = xml.find('<bpmndi:BPMNDiagram')
di_end   = xml.find('</bpmndi:BPMNDiagram>') + len('</bpmndi:BPMNDiagram>')
xml = xml[:di_start] + NEW_DI + xml[di_end:]
```

**重写 DI 时的布局规范（主干垂直流程）：**

| 元素类型 | 宽×高 | 居中 x | 分支左中心 x | 分支右中心 x |
|---------|--------|--------|------------|------------|
| startEvent / endEvent | 36×36 | 382 | — | — |
| userTask / callActivity | 100×80 | 350 | 260（左） | 440（右） |
| parallelGateway / exclusiveGateway | 50×50 | 375 | — | — |

- 主干元素纵向间距（底部到下一元素顶部）：**40px**
- 网关到分支节点之间加 20px 中转 waypoint（`y = 网关底+20`，左右分叉）
- 分支节点回聚合网关同理（`y = 分支底+20`，左右向中汇聚）
- Edge 全部使用折线（L 形），禁止斜线

---

### 规则22：`saveProcess` 新建流程后禁止直接读 `result['obj']` 取 ID（⚠️ 强制）

**现象：** 新建流程（`processDefinitionId='0'`）调 `saveProcess`，返回 `success=True` 但 `result` 字段为 null 或不含 `obj`，直接访问 `r['result']['obj']` 抛 `KeyError: 'result'`。

**根因：** `saveProcess` 的 `result` 结构因版本/场景而异：新建时 `result` 有时为 null，编辑时 `result['obj']` 也可能为 null。不能假设固定结构。

**强制规则：新建流程后必须按 processKey 或 processName 重新查询取得真实 ID，禁止直接读 `result['obj']`。**

```python
# ❌ 错误 —— result 可能为 null
r = save_process(...)
new_id = r['result']['obj']  # KeyError

# ✅ 正确 —— 保存后重新查询
r = save_process(...)
assert r.get('success'), f"保存失败: {r.get('message')}"
# 按 processKey 查
kw = urllib.parse.quote(process_key)
r2 = api_get(f'/act/process/extActProcess/list?pageNo=1&pageSize=20&processKey={kw}')
records = r2.get('result', {}).get('records', [])
matched = [p for p in records if p['processKey'] == process_key]
if not matched:
    # processKey 查不到时按 processName 查
    kw2 = urllib.parse.quote(process_name)
    r3 = api_get(f'/act/process/extActProcess/list?pageNo=1&pageSize=20&processName={kw2}')
    matched = [p for p in r3.get('result', {}).get('records', []) if p['processKey'] == process_key]
new_id = matched[0]['id']
```

---

### 规则23：所有子流程的 `nodes_str` 必须包含 startEvent 节点（⚠️ 强制）

**现象：** 创建子流程时 `nodes_str` 只含 userTask，前端「流程配置 → 流程节点」列表中缺少「开始」节点，无法为其配置表单地址。

**根因：** `nodes_str` 决定了 `ext_act_process_node` 中哪些节点被持久化。startEvent 虽在 XML 中存在，但不在 `nodes_str` 里就不会写入节点配置表，前端列表中就看不到。

**强制规则：任何子流程（会签子流程、调用子流程等）保存时，`nodes_str` 必须同时包含 start 节点和所有 userTask 节点。**

```python
# ❌ 错误 —— 只含 userTask，start 节点不出现在前端列表
nodes_str = 'id=task_cs_parallel###nodeName=会签审批@@@'

# ✅ 正确 —— 包含 start
nodes_str = 'id=start###nodeName=开始@@@id=task_cs_parallel###nodeName=会签审批@@@'
```

---

### 规则24：子流程的开始节点表单地址默认继承主流程，formEditStatus 按需设置（⚠️ 强制）

**现象：** 子流程开始节点在前端节点列表中显示，但 PC/移动端表单地址为空。

**根因：** 子流程通过 `JG_SUB_MAIN_PROCESS_ID` 共享主流程表单数据，其开始节点需要配置与主流程节点相同的表单 URL，才能在子流程运行时正确渲染表单。

**规则：**
- **表单地址**：用户未明确指定时，默认从主流程现有节点中取第一个有地址的节点 URL 继承
- **`formEditStatus`**：**不强制为 1**，视节点用途决定：
  - 需要**编辑**表单的节点（如草稿、填写）→ 设 `formEditStatus=1`
  - 仅**查看**表单的节点（如审批查看）→ 不设或保持默认（不需要 `formEditStatus=1`）
  - 开始节点通常只需配置地址，**无需强制设置** `formEditStatus`，除非子流程需要在开始时编辑表单

**操作步骤（保存子流程后执行）：**

```python
# 1. 从主流程节点中取表单地址（取第一个有地址的节点，通常是草稿节点或节点1）
r = api_get(f'/act/process/extActProcessNode/list?processId={MAIN_PID}&pageNo=1&pageSize=50')
main_nodes = r.get('result', {}).get('records', [])
form_url = next((n['modelAndView'] for n in main_nodes if n.get('modelAndView')), None)
assert form_url, '主流程未配置表单地址，无法继承'

# 2. 查子流程节点，找 start
r2 = api_get(f'/act/process/extActProcessNode/list?processId={SUB_PID}&pageNo=1&pageSize=50')
sub_nodes = r2.get('result', {}).get('records', [])
start_node = next((n for n in sub_nodes if n['processNodeCode'] == 'start'), None)

# 3. 配置表单地址（formEditStatus 按需设置，不强制）
start_node['modelAndView'] = form_url
start_node['modelAndViewMobile'] = form_url
# 如果该节点需要编辑表单，再加：
# start_node['formEditStatus'] = '1'
# cfg = json.loads(start_node.get('nodeConfigJson') or '{}')
# cfg['formEditStatus'] = True
# start_node['nodeConfigJson'] = json.dumps(cfg, ensure_ascii=False)
api_put('/act/process/extActProcessNode/edit', start_node)

# 4. 再次发布子流程使配置生效
api_put('/act/process/extActProcess/deployProcess', {'id': SUB_PID})
```

### 规则25：生成 BPMN XML 后、saveProcess 前必须通过 validate_and_fix_layout 校验布局（⚠️ 强制）

**现象：** 流程保存成功但设计器打开后多个节点堆叠在同一位置（y 坐标相同），连线指向错误坐标，流程图无法正常显示（如采购审批流程中 `task_countersign_1`/`script_node_1`/`svc_getManyDepts`/`end` 全部堆叠在 y=1546）。

**根因：** `calc_layout` 在处理含多段会签链、复杂条件分支的长流程时，后段节点的位置可能未正确推进，导致多个节点共享同一 y 坐标并重叠。

**强制规则：`bpmn_creator.py` 的 `main()` 函数已内置此校验，`validate_and_fix_layout` 在 `build_bpmn_xml` 之后、`save_process` 之前自动执行，无需手动调用。**

检测逻辑（10 项检查，布局类任一触发即修复，结构类仅上报）：

| 类别 | 检查项 | 说明 |
|------|--------|------|
| 布局 | **2a 节点矩形重叠** | 任意两个主节点 Shape 矩形面积相交（x+y 轴同时重叠）|
| 布局 | **2b 节点间距不足** | 同列/同行相邻节点间隙 < 5px（含纵向/横向）|
| 布局 | **2c 连线穿越节点** | 任意边的线段穿越非源/目标节点的矩形（含边界触碰）|
| 布局 | **2d Shape标签遮挡节点** | BPMNShape 的 BPMNLabel 坐标落在其他节点矩形内部 |
| 布局 | **2e 连线标签相互堆叠** | 两个 flow 标签矩形重叠（网关多分支出口 label 挤在同一点）|
| 布局 | **2f 连线标签遮挡节点** | flow 标签矩形与非端点节点矩形重叠 |
| 布局 | **2g 连线标签压线** | flow 标签矩形被其他连线线段穿越 |
| 结构 | **3a start/end 数量** | startEvent ≠ 1 或 endEvent ≠ 1（仅上报，不触发重建）|
| 结构 | **3b 连线整体合理性** | 连线源/目标节点不存在于 BPMNDiagram；中间节点缺入边或出边（孤立/悬空）|
| 布局 | **4a 连线共线重叠** | 两条边的线段共线且重叠超过 6px |

排除项：边界事件（`timer_`/`signal_boundary_`/`msg_boundary_` 前缀的 Shape）不参与检测，它们附着于父节点是合法位置。

修复策略（自动执行）：
1. **结构性问题**（3a/3b）仅打印错误，不触发重建（位置调整无法修复结构）
2. **布局问题**（2a-2g、4a）触发以下修复：
   - 按原 config 重新调用布局算法重建整个 `<bpmndi:BPMNDiagram>` 区块
   - 重建后对所有带标签的 flow edge 执行标签重定位：将 BPMNLabel 移到路径中点旁侧（水平段→线上方，垂直段→线左侧），消除网关处标签堆叠
3. 原 BPMN Process 部分（节点XML、连线XML、监听器等）保持不变

```python
# main() 中已内置，无需额外调用：
bpmn_xml = build_bpmn_xml(config)
bpmn_xml, _layout_fixed, _layout_issues = validate_and_fix_layout(bpmn_xml, config)
if _layout_fixed:
    print(f'  [布局优化] 已自动修复重叠问题: {_layout_issues}')
result = save_process(args.api_base, args.token, config, bpmn_xml)
```

**手动修复已有流程（单独调用场景）：** 见本次采购审批流程的修复模式——获取流程 XML → 检测重叠 → 重建 BPMNDiagram → saveProcess + deployProcess。

### 规则26：每个流程只允许一个 endEvent（⚠️ 强制）

**现象：** 生成含 end_approved / end_rejected 等多个结束节点的流程后，设计器显示多个悬浮结束圆，流程图视觉混乱，用户无法判断正常结束路径。

**根因：** 业务上区分"批准结束"/"驳回结束"等多结果，但 BPMN 中结果信息应通过流程变量或审批意见携带，而非用多个 endEvent 表达。

**强制规则：所有路径统一汇聚到同一个 `end` endEvent。已有流程如存在多个 endEvent 必须合并。**

```python
# 合并多个 endEvent 到单一 end 的标准修复模式
OLD_ENDS = {'end_approved', 'end_rejected', 'end_a', 'end_b'}  # 按实际调整

# Step1: 所有 targetRef 指向 end
for old_id in OLD_ENDS:
    xml = xml.replace(f'targetRef="{old_id}"', 'targetRef="end"')

# Step2: 删除旧 endEvent 元素（自闭合 + 完整标签两种形式）
for old_id in OLD_ENDS:
    xml = re.sub(rf'<bpmn2:endEvent[^>]*id="{old_id}"[^>]*/>', '', xml)
    xml = re.sub(rf'<bpmn2:endEvent[^>]*id="{old_id}".*?</bpmn2:endEvent>', '', xml, flags=re.DOTALL)

# Step3: 在保留的 end 节点中补充新 incoming 元素
ns = "bpmn2:" if "<bpmn2:incoming>" in xml else ""
xml = re.sub(
    r'(<(?:bpmn2:)?endEvent\s[^>]*id="end"[^>]*>)',
    lambda m: m.group(0) + ''.join(
        f'\n      <{ns}incoming>{fid}</{ns}incoming>'
        for fid in ['flow_approve', 'flow_reject']  # 按实际 flow id 调整
    ),
    xml
)
```

> 检测是否已有多余 endEvent：`len(re.findall(r'<bpmn2:endEvent', xml)) > 1` 即触发合并流程。

---

### 规则27：有名称的 sequenceFlow 必须用显式 BPMNLabel 定位（⚠️ 强制）

**现象：** 不指定 BPMNLabel 坐标时，前端自动将 label 放置在连线中点，与节点矩形或其他连线大概率重叠，尤其网关多出线时所有 label 挤在网关附近。

**根因：** BPMNDiagram 中 BPMNEdge 缺少 `<bpmndi:BPMNLabel>` 子元素时，渲染器使用默认算法定位，无法感知周围节点布局。

**强制规则：凡是 sequenceFlow 有 `name`（条件描述），BPMNEdge 必须包含 `<bpmndi:BPMNLabel><dc:Bounds>` 显式指定位置。**

```xml
<!-- ✅ 正确 —— 显式指定 label 位置（在连线中段旁偏移 5-15px） -->
<bpmndi:BPMNEdge id="flow_short_di" bpmnElement="flow_short">
  <di:waypoint x="675" y="240"/>
  <di:waypoint x="200" y="240"/>
  <di:waypoint x="200" y="320"/>
  <bpmndi:BPMNLabel><dc:Bounds x="388" y="222" width="80" height="14"/></bpmndi:BPMNLabel>
</bpmndi:BPMNEdge>

<!-- ❌ 错误 —— 无 BPMNLabel，渲染器自动放置，必然与节点重叠 -->
<bpmndi:BPMNEdge id="flow_short_di" bpmnElement="flow_short">
  <di:waypoint x="675" y="240"/>
  <di:waypoint x="200" y="320"/>
</bpmndi:BPMNEdge>
```

**BPMNLabel 坐标计算原则：**
- 水平段：`x = 连线水平段中点 - label宽/2`，`y = 线段 y - 18`（线上方）
- 垂直段：`x = 线段 x + 5`，`y = 连线垂直段中点 - 7`（线右侧）
- L 形折线：取最长段的中点做偏移
- `width` 建议 60–90（中文 4-6 字），`height=14`

---

### 规则28：结构性网关（分叉/汇合用途）禁止添加 name 属性（⚠️ 强制）

**现象：** 为 parallelGateway、inclusiveGateway 的汇合节点加了"并行审批汇合"、"类型审批汇合"等 name，前端在网关菱形旁边渲染浮动文字 label，视觉上噪音大且无实际意义。

**规则：**
- **禁止加 name**：仅起分叉/汇合作用的网关（parallelGateway 全部、inclusiveGateway 汇合节点）
- **可以加 name**：有业务判断含义的网关（exclusiveGateway 判断条件、inclusiveGateway 分叉节点）

```python
# 去除结构性网关 name 的标准模式
for gw_id in ['gw_par', 'gw_par_join', 'gw_incl_join']:
    xml = re.sub(rf'(id="{gw_id}"[^>]*?)\s+name="[^"]*"', r'\1', xml)
    xml = re.sub(rf'(\s+name="[^"]*")([^>]*id="{gw_id}")', r'\2', xml)
```

| 网关类型 | 加 name？ | 示例 |
|---------|---------|------|
| exclusiveGateway（判断） | ✅ 加（说明判断维度） | `name="请假天数判断"` |
| inclusiveGateway（分叉） | ✅ 加（说明判断维度） | `name="请假类型判断"` |
| parallelGateway（分叉） | ❌ 不加 | 无 name |
| parallelGateway（汇合） | ❌ 不加 | 无 name |
| inclusiveGateway（汇合） | ❌ 不加 | 无 name |

---

## 前置条件

用户必须提供以下信息（或由 AI 引导确认）：

1. **API 地址**：JeecgBoot 后端地址（如 `https://api3.boot.jeecg.com`）
2. **X-Access-Token**：JWT 登录令牌（从浏览器 F12 获取）

如果用户未提供，提示：
> 请提供 JeecgBoot 后端地址和 X-Access-Token（从浏览器 F12 → Network → 任意请求的 Request Headers 中复制）。

## 后端项目路径（本地环境）

> 当需要自动创建 Java 类时，从记忆中读取后端项目路径。若记忆中无此信息，询问用户：
> "请提供后端项目根目录路径（如 D:\path\to\jeecg-boot-framework），用于自动创建 Java 服务类。"

## 主数据复用规则

> **⛔ 严重问题（已发生）：** 不得自行猜测或尝试 API 路径来查询主数据。
>
> **强制要求：必须且只能通过 `jeecg-system` skill 的 `system_utils.py` 查询主数据，禁止直接拼接 API 路径。**
>
> ```python
> from system_utils import init_api, query_depts, query_roles, query_users, query_dept_positions
> init_api(API_BASE, TOKEN)
> depts = query_depts(); roles = query_roles(); users = query_users()
> ```
>
> 配置审批人（角色、用户、部门）或字典时，必须遵循"先查后建"原则。详见 `../jeecg-system/SKILL.md`。

## 交互流程

### Step 0: 解析用户需求

从用户描述中提取以下信息：

| 信息 | 默认值 | 示例 |
|------|--------|------|
| 流程名称 | 用户指定或自动生成 | "员工请假审批流程" |
| 流程类型 | `oa` | 字典 `bpm_process_type` 的值 |
| 节点列表 | 从描述中解析 | 开始→员工提交→经理审批→HR审批→结束 |
| 网关逻辑 | 从描述中解析 | "通过→下一步，拒绝→结束" |
| 审批人配置 | 从描述中解析 | assignee/candidateUsers/candidateGroups/表达式 |

### Step 0.5: 识别「代码生成 + 审批流程」联合创建场景

**触发条件（满足任一即触发）：**
- 用户说"用代码生成创建审批"、"代码生成一个XXX审批单"、"生成代码并配置流程"
- 用户明确选择 `formType=3`（自定义开发表单）作为流程关联表单
- 用户描述中同时包含"建表/CRUD/代码生成" + "审批/流程/BPM"
- 代码生成完成后，用户紧接着要求创建流程

> **重要（用户明确规则）：** 代码生成完成后直接进入流程创建，**跳过 Step 2 的流程摘要确认**。

**联合创建流程（必须按顺序执行）：**

**第 1 步：调用 `jeecg-codegen` skill 生成 CRUD 代码**

调用时追加要求：实体包含 `bpm_status` 字段（`@Dict(dicCode = "bpm_status")`），生成 `Form.vue`，`List.vue` 含"发起流程"和"审批进度"。

**第 2 步：收集代码生成结果**

从输出中获取 `tableName` → `formTableName`、`viewDir` → `formUrl` 前缀、`entityName` → 组件名。

**第 3 步：使用 `formType=3` 创建 BPM 流程**

```json
{
  "formLink": {
    "formType": "3",
    "relationCode": "dev_{tableName}_001",
    "formTableName": "{tableName}",
    "flowStatusCol": "bpm_status",
    "titleExp": "${关键字段名}提交的{业务名}"
  }
}
```

草稿节点表单地址：`modelAndView: "{viewDir}/components/{entityName}Form?edit=1"`

> **注意：** `formType=3` 不需要发起授权步骤（跳过 Step 5），但必须完成 Step 5.5（草稿节点表单地址配置）。

---

### Step 1: 识别节点并构建流程结构

**支持的节点类型：**

| 用户描述关键词 | BPMN 节点类型 | XML 元素 |
|---------------|---------------|----------|
| 开始 | 开始事件 | `startEvent` |
| 结束 | 结束事件 | `endEvent` |
| 审批/审核/处理/提交 | 用户任务 | `userTask` |
| 条件判断/分支/通过或拒绝 | 排他网关 | `exclusiveGateway` |
| **手工分支/意见分支/选择分支** | **userTask 多出线** | 无网关，直接多条 sequenceFlow |
| 同时/并行 | 并行网关 | `parallelGateway` |
| 条件并行/部分并行 | 包含网关 | `inclusiveGateway` |
| **子流程/嵌套** | **内嵌子流程** | `subProcess` — 详见 `references/bpmn-call-activity.md` |
| **调用子流程/主子流程** | **调用子流程** | `callActivity` — 详见 `references/bpmn-call-activity.md` |
| 会签子流程 | 调用子流程+多实例 | `callActivity` + `multiInstance` |
| **Java服务/表达式/调用Bean** | **Java 服务节点** | `serviceTask` — 见下方 |
| **AI流程编排/AIGC调用** | **AI 服务节点** | `aiTask` — 见下方 |
| **调用外部HTTP接口** | **API 服务节点** | `apiTask` — 见下方 |
| **节点超时提醒** | **节点配置字段** | `nodeTimeout` 整数（小时），通过 `edit_node_config` 设置 |
| **节点定时触发** | **边界定时器** | `timer` 字段附加在 `userTask` 上 — 见下方 |
| **脚本节点/Groovy/JS脚本** | **脚本节点** | `scriptTask` — 见下方 |
| **信号/消息事件** | 捕获/抛出/边界 | `signalCatch` `signalThrow` `signalBoundary` `messageCatch` `messageThrow` `messageBoundary` — 详见 [`references/bpmn-signal-message-events.md`](references/bpmn-signal-message-events.md) |

> **手工分支 vs 条件分支：** 条件分支用 `exclusiveGateway` + 条件自动判断；手工分支从 userTask 直接引出多条无条件 sequenceFlow，用户审批时手动选择。详见 `references/bpmn-manual-branch.md`。
>
> **手工分支使用前提：** 仅在通过/拒绝后还需经过不同后续处理节点时才使用。如果都直接到结束，不需要手工分支。

**审批人配置映射（8 种类型 + 扩展）：**

| 用户描述 | JSON assignee type | BPMN XML 属性 |
|----------|-------------------|---------------|
| "发起人/申请人" | `expression` + `applyUserId` | `flowable:assignee="${applyUserId}"` |
| "admin/指定用户名" | `assignee` | `flowable:assignee="admin"` |
| "张三或李四" | `candidateUsers` | `flowable:candidateUsers="zhangsan,lisi"` |
| "部门负责人（表达式）" | `candidateUsersExpression` | `flowable:candidateUsers="${flowNodeExpression.getDepartLeaders(applyUserId)}"` |
| "经理角色/角色组" | `role` | `flowable:candidateGroups="admin,vue3" groupType="role"` |
| "审批角色" | `approvalRole` | `flowable:candidateUsers="${flowUtil.getUsersByApprRole(...)}" groupType="approvalRole"` |
| "某部门审批" | `dept` | `flowable:candidateGroups="部门ID" groupType="dept"` |
| "某岗位审批" | `deptPosition` | `flowable:candidateGroups="岗位ID" groupType="deptPosition"` |
| "职级审批" | `position` | `flowable:candidateUsers="${oaFlowExpression.getApplyUserDeptPositionLevel(...)}" groupType="position"` |
| "提交/填写/草稿" | `expression` + `draft: true` | `flowable:assignee="${applyUserId}"` + AutoSubmitListener |
| "上一节点指派" | `assignedByPrev: true` | `isAssignedByPreviousNode=true` |
| "会签" | `countersign` 配置 | `multiInstance` + `flowUtil.stringToList` |

> **重要区别：** `approvalRole` 和 `position` 用 `candidateUsers`，`role`/`dept`/`deptPosition` 用 `candidateGroups`。

**审批人数据查询：**
- 角色编码：`SELECT role_code, role_name FROM sys_role`；创建：`POST /sys/role/add`
- 用户名：`SELECT username, realname FROM sys_user`
- 部门/岗位ID：`SELECT id, depart_name, org_category FROM sys_depart`（1=公司, 2=部门, 3=岗位, 4=子公司）
- 审批角色：`GET /sys/approvalRole/search?keyword=`；分组 `rootList`；子角色 `childList?pid={groupId}`
  - 创建分组：`POST /sys/approvalRole/group/add`，body: `{"name":"分组名", "pid":"0"}`
  - 创建角色：`POST /sys/approvalRole/role/add`，body: `{"name":"角色名", "pid":"{groupId}"}`
  - 绑定用户：`POST /sys/approvalRoleUser/add`，body: `{"approvalRoleId":"{roleId}", "userIds":["{userId}"], "bizScope":"all", "includeSub":0}`

### serviceTask 配置（Java 服务节点）

`bpmn_creator.py` 原生支持，直接在 nodes 数组中配置。

| 字段 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `id` | 是 | - | 节点唯一ID |
| `type` | 是 | - | 固定为 `serviceTask` |
| `name` | 是 | - | 节点名称 |
| `serviceType` | 否 | `expression` | `expression` / `class` / `delegateExpression` |
| `expression` | 条件 | - | UEL 表达式，如 `${myBean.doWork(execution)}` |
| `className` | 条件 | - | Java 全类名（serviceType=class） |
| `delegateExpr` | 条件 | - | 委托表达式 |
| `resultVar` | 否 | - | 返回值存入该流程变量（仅 expression） |

```json
{"id": "svc1", "type": "serviceTask", "name": "测试服务节点",
 "serviceType": "expression", "expression": "${testExpression.test()}"}
```

> 用户未提供类名/表达式时，参见 [`references/bpmn-service-task-autocreate.md`](references/bpmn-service-task-autocreate.md) 自动创建 Java 类。
> serviceTask 不需要配置审批人，由引擎自动执行后流转。

### aiTask 配置（AI 流程编排节点）

底层是 `serviceTask` + `AigcServiceTaskDelegate`。

| 字段 | 必填 | 说明 |
|------|------|------|
| `id` | 是 | 节点唯一ID |
| `type` | 是 | 固定为 `aiTask` |
| `name` | 是 | 节点名称 |
| `aiFlowId` | 是 | AIGC 流程 ID |
| `inputParamsList` | 否 | 输入参数映射，如 `[{"key": "content", "value": "${name}"}]` |
| `outputParamsList` | 否 | 输出参数映射，如 `[{"key": "result", "value": "aiResult"}]` |

```json
{"id": "task_ai", "type": "aiTask", "name": "AI内容生成",
 "aiFlowId": "2034580389262573569",
 "inputParamsList": [{"key": "content", "value": "${userName}"}],
 "outputParamsList": [{"key": "summary", "value": "aiSummary"}]}
```

> **⚠️ AIGC 模块前缀是 `/airag/`，不是 `/ai/`。** 查询流程编排：`GET /airag/flow/list`；查询 AI 应用：`GET /airag/app/list`。

### timer 边界定时器（附加在 userTask 上）

> **⛔ 严重坑：** 用户说"给某个流程的某个节点创建定时任务"时，**不要**去 `/sys/quartzJob` 创建 Quartz 定时任务。这是 BPMN 层面的操作，应在节点上添加 timer 边界事件。只要提到**流程名**或**节点名**，就是 BPMN 定时。

| 字段 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `type` | 是 | `duration` | `date`=指定日期 / `duration`=等待时长 / `cycle`=重复周期 |
| `value` | 是 | — | ISO 8601 / cron / `${var}` |
| `timerTarget` | 否 | — | 触发后流转到的节点ID |
| `eventId` | 否 | `timer_{nodeId}` | 自动生成 |
| `timerFlowId` | 否 | `flow_{eventId}` | 自动生成 |

**value 格式：**
- `date`：`yyyy-MM-ddTHH:mm:ss`（如 `2026-04-03T15:00:59`）
- `duration`：ISO 8601（`PT1M` `PT10M` `PT1H` `P1D` `P1W` `P1M` `${duration}`）
- `cycle`：ISO 8601 重复（`R3/PT10H` `R/PT1H`）或 cron（`0 0/5 * * * ?`）

**示例：**
```json
{"timer": {"type": "duration", "value": "P1D", "timerTarget": "end"}}
{"timer": {"type": "cycle", "value": "R3/PT5M"}}
{"timer": {"type": "date", "value": "2026-12-31T23:59:59", "timerTarget": "end"}}
```

### apiTask 配置（API 服务节点）

底层是 `serviceTask` + `ApiServiceTaskDelegate`。

| 字段 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `id` | 是 | — | 节点唯一ID |
| `type` | 是 | — | 固定为 `apiTask` |
| `name` | 是 | — | 节点名称 |
| `apiUrl` | 是 | — | 接口路径，支持 `${var}` 和完整 URL |
| `method` | 否 | `GET` | `GET` / `POST` / `PUT` / `DELETE` |
| `headersList` | 否 | `[]` | 请求头 |
| `inputParamsList` | 否 | `[]` | 请求参数，支持流程变量 |
| `outputParamsList` | 否 | `[]` | 响应映射到流程变量（JSONPath），如 `[{"key": "result.records[0].id", "value": "userId"}]` |
| `timeout` | 否 | `30000` | 超时毫秒 |
| `retryCount` | 否 | `3` | 重试次数 |

```json
{"id": "task_api", "type": "apiTask", "name": "查询会议室",
 "apiUrl": "/eoa/meeting/eoaMeetingRoom/list", "method": "GET",
 "inputParamsList": [{"key": "pageNo", "value": "1"}, {"key": "name", "value": "${roomName}"}],
 "outputParamsList": [{"key": "result.records[0].name", "value": "firstRoomName"}]}
```

> 用户未提供 apiUrl 时，参见 [`references/bpmn-api-task-autocreate.md`](references/bpmn-api-task-autocreate.md) 自动创建。

### scriptTask 配置（脚本节点）

| 字段 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `id` | 是 | - | 节点唯一ID |
| `type` | 是 | - | 固定为 `scriptTask` |
| `name` | 是 | - | 节点名称 |
| `scriptFormat` | 否 | `javascript` | `javascript` / `groovy` / `juel` |
| `script` | 是 | - | 脚本内容（特殊字符自动 CDATA 包裹） |
| `resultVar` | 否 | - | 返回值存入流程变量 |

```json
{"id": "script_node", "type": "scriptTask", "name": "脚本节点",
 "scriptFormat": "javascript",
 "script": "var sum = 2 + 9;\nexecution.setVariable(\"myVar\", sum);"}
```

---

### Step 2: 展示流程摘要并确认

**必须展示以下内容，等待用户确认后再执行：**

```
## 流程摘要

- 流程名称：员工请假审批流程
- 流程类型：oa
- 目标环境：https://api3.boot.jeecg.com

### 流程节点

| 序号 | 节点名称 | 类型 | 审批人 |
|------|---------|------|--------|
| 1 | 开始 | startEvent | - |
| 2 | 员工提交申请 | userTask | ${applyUserId} |
| 3 | 部门经理审批 | userTask | manager (角色组) |
| 4 | 审批结果 | exclusiveGateway | 条件分支 |
| 5 | HR审批 | userTask | hr (角色组) |
| 6 | 结束 | endEvent | - |

### 连线与条件

开始 → 员工提交申请 → 部门经理审批 → 审批结果
  ├─ 通过 (result==1) → HR审批 → 结束
  └─ 拒绝 (result==0) → 结束

确认以上信息正确？(y/n)
```

### Step 3: 生成 JSON 配置并调用通用脚本

> **重要：优先使用 `scripts/bpmn_creator.py` 通用脚本 + JSON 配置文件的方式，只需生成 JSON 数据即可创建流程。**

**使用步骤：**
1. 根据用户需求生成 JSON 配置文件（Write 到工作目录的临时 `.json` 文件）
2. 用 Bash 执行：`python "<skill目录>/scripts/bpmn_creator.py" --api-base <URL> --token <TOKEN> --config <config.json>`
3. 删除临时 JSON 配置文件

**脚本自动完成：** 生成 BPMN XML、构建 nodes 参数、调用 saveProcess、关联表单、条件 base64 编码、taskExtendJson、布局计算。

**JSON 配置格式：**
```json
{
  "processName": "请假审批流程",
  "processKey": "oa_leave_approval",
  "typeId": "oa",
  "nodes": [
    {"id": "start", "type": "startEvent", "name": "开始"},
    {"id": "task_draft", "type": "userTask", "name": "提交申请", "draft": true,
     "assignee": {"type": "expression", "value": "applyUserId"}},
    {"id": "task_manager", "type": "userTask", "name": "部门经理审批",
     "assignee": {"type": "role", "value": "manager"}},
    {"id": "gateway_days", "type": "exclusiveGateway", "name": "请假天数判断",
     "default": "flow_le3_end"},
    {"id": "task_hr", "type": "userTask", "name": "HR审批",
     "assignee": {"type": "role", "value": "hr"}},
    {"id": "end", "type": "endEvent", "name": "结束"}
  ],
  "flows": [
    {"id": "flow_1", "source": "start", "target": "task_draft"},
    {"id": "flow_2", "source": "task_draft", "target": "task_manager"},
    {"id": "flow_3", "source": "task_manager", "target": "gateway_days"},
    {"id": "flow_gt3", "source": "gateway_days", "target": "task_hr", "name": "大于3天",
     "conditions": [{"field": "integer_xxx", "fieldType": "integer", "fieldName": "请假天数", "operator": "gt", "value": "3"}]},
    {"id": "flow_le3_end", "source": "gateway_days", "target": "end", "name": "3天及以内(默认)"},
    {"id": "flow_hr_end", "source": "task_hr", "target": "end"}
  ],
  "formLink": {
    "formType": "2",
    "relationCode": "desform_oa_leave_apply",
    "titleExp": "${select_user_xxx}提交的请假申请",
    "formTableName": "oa_leave_apply"
  }
}
```

**手工分支（意见分支）JSON 示例：**
```json
{
  "processName": "客户申请流程",
  "processKey": "crm_customer_apply",
  "nodes": [
    {"id": "start", "type": "startEvent", "name": "开始"},
    {"id": "task_draft", "type": "userTask", "name": "填写申请", "draft": true,
     "assignee": {"type": "expression", "value": "applyUserId"}},
    {"id": "task_manager", "type": "userTask", "name": "经理审批",
     "assignee": {"type": "assignee", "value": "admin"}},
    {"id": "task_director", "type": "userTask", "name": "总监审批",
     "assignee": {"type": "assignee", "value": "admin"}},
    {"id": "end", "type": "endEvent", "name": "结束"}
  ],
  "flows": [
    {"id": "flow_1", "source": "start", "target": "task_draft"},
    {"id": "flow_2", "source": "task_draft", "target": "task_manager", "name": "经理审批"},
    {"id": "flow_3", "source": "task_draft", "target": "task_director", "name": "总监审批"},
    {"id": "flow_4", "source": "task_manager", "target": "end"},
    {"id": "flow_5", "source": "task_director", "target": "end"}
  ]
}
```
> 当 userTask 有 2+ 条出线且都不带 `conditions` 时，脚本自动识别为手工分支，使用水平布局。

---

### 并行网关 / 包容网关 / 排他网关的水平分支布局（自动）

当流程出现 split（出度≥2）→ 多分支链 → join（入度=split出度）的对称模式时，自动横向并排布局。不满足条件退化为垂直布局，无需额外配置。

**排他网关 3+ 分支水平展开（自动）：** 当 `exclusiveGateway` 有 3 条及以上出线时，非空分支链自动水平展开（左/右/更多列），默认流直线向下连接后续节点，分支通过 L 形线汇聚。**不再使用右侧绕行（bypass）**，避免多条绕行线重叠。2 条出线的排他网关仍使用垂直+绕行布局。

**手工分支布局规则：** 顶行水平排列（开始→前置→分支源→结束），第一条出线水平直连结束，后续出线向下再向右，目标节点回到结束走 L 形。

#### JSON 配置字段说明

**顶层字段：**

| 字段 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `processName` | 是 | - | 流程中文名称 |
| `processKey` | 否 | `process_{timestamp}` | 流程唯一标识 |
| `processId` | 否 | `0` | 已有流程ID（编辑时传入） |
| `typeId` | 否 | `oa` | 流程类型 |
| `startType` | 否 | `manual` | 发起方式 |
| `nodes` | 是 | - | 节点数组 |
| `flows` | 是 | - | 连线数组 |
| `formLink` | 否 | - | 表单关联配置 |

**节点（nodes）字段：**

| 字段 | 必填 | 说明 |
|------|------|------|
| `id` | 是 | 节点唯一ID |
| `type` | 是 | `startEvent` / `endEvent` / `userTask` / `exclusiveGateway` / `parallelGateway` / `inclusiveGateway` |
| `name` | 是 | 节点名称 |
| `draft` | 否 | `true` = 首节点（sameMode=0 + AutoSubmitListener + formEditStatus=1）。**草稿节点只添加 `TaskCreatedAutoSubmitListener`，非草稿节点只添加 `TaskSkipApprovalListener`**。开启 formEditStatus=1 的节点必须同时设置 PC 和移动端表单地址 |
| `default` | 否 | 排他网关的默认流 ID |
| `assignee` | 否 | 审批人配置 |
| `countersign` | 否 | 会签配置 |

**会签（countersign）配置：**

| 字段 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `sequential` | 否 | `false` | `true`=串行，`false`=并行 |
| `rule` | 否 | `countersign_all` | `countersign_all`/`countersign_one`/`countersign_half`/`countersign_proportion`/`countersign_custom` |
| `proportion` | 否 | - | 仅 `countersign_proportion` 时有效 |
| `auditorUserType` | 是 | - | `candidateUsers`/`candidatePosts`/`candidateDepts`/`candidateGroups`/`candidateApprovalGroups`/`candidateDeptPositions`/`formData`/`customUser` |
| `auditorUserIds` | 条件 | - | `candidateUsers` 时，如 `["admin","jeecg"]` |
| `auditorPostIds` | 条件 | - | `candidatePosts` 时 |
| `auditorDeptIds` | 条件 | - | `candidateDepts` 时 |
| `auditorGroupIds` | 条件 | - | `candidateGroups` 时，**填角色 code 不是 ID** |
| `auditorApprovalGroupIds` | 条件 | - | `candidateApprovalGroups` 时 |
| `auditorDeptPositionIds` | 条件 | - | `candidateDeptPositions` 时 |
| `auditorCountersignFormField` | 条件 | - | `formData` 时，表单字段 model |

> 配置了 `countersign` 后，`assignee` 被忽略（自动改为 `${assigneeUserId}`）。
>
> **`customUser` 类型**：无 `taskCountersignExtendJson`，collection 为 `${flowUtil.stringToList(assigneeUserIdList)}`，发起时选人。

**会签示例：**
```json
{"id": "task_cs", "type": "userTask", "name": "总经理会签",
 "countersign": {"sequential": true, "rule": "countersign_half",
  "auditorUserType": "candidatePosts", "auditorPostIds": ["1958471074953363458"]}}
```

**审批人（assignee）配置：**

| type 值 | value 含义 | 生成的 XML |
|---------|-----------|-----------|
| `assignee` | 固定用户名 | `flowable:assignee="value"` |
| `expression` | 表达式变量名 | `flowable:assignee="${value}"` |
| `candidateUsers` | 多候选人 | `flowable:candidateUsers="value"` |
| `candidateUsersExpression` | 候选人表达式 | `flowable:candidateUsers="value"` |
| `role` | 角色编码 | `candidateGroups + groupType="role"` |
| `approvalRole` | 审批角色 ID | `candidateUsers + 表达式 + groupType="approvalRole"` |
| `dept` | 部门 ID | `candidateGroups + groupType="dept"` |
| `deptPosition` | 岗位 ID | `candidateGroups + groupType="deptPosition"` |
| `position` | 职级 ID | `candidateUsers + 表达式 + groupType="position"` |

**assignee 额外可选参数（节点行为控制）：**

> **⛔ 严重坑：这些参数必须放在 `assignee` 字典内部，不能放在节点顶层。**
> `gen_user_task` 从 `assignee_cfg = node.get('assignee', {})` 读取这些值，
> 放在节点顶层会导致 taskExtendJson 中对应字段全为 false/0。
>
> ```json
> // ❌ 错误 —— sameMode 在节点顶层，不会被读取
> {"id": "task_x", "type": "userTask", "name": "审批",
>  "assignee": {"type": "role", "value": "manager"},
>  "sameMode": 2, "skipOne": true}
>
> // ✅ 正确 —— 所有行为参数都在 assignee 内部
> {"id": "task_x", "type": "userTask", "name": "审批",
>  "assignee": {"type": "role", "value": "manager",
>               "sameMode": 2, "skipOne": true, "skipEmpty": false}}
> ```

| 参数 | 说明 |
|------|------|
| `sameMode: 2` | 审批人与发起人同一人时自动跳过（**值为 2，不是 1**） |
| `skipOne: true` | 只有一个候选人时自动签收（字段名拼写 `OnePersion`） |
| `skipEmpty: true` | 审批人为空时自动跳过 |
| `skipApproval: true` | 完全跳过审批（**不是**"与发起人相同时跳过"） |
| `assignedByPrev: true` | 由上一节点指派审批人 |
| `emptyAssignedByPrev: true` | 为空时由上一节点指派 |

> 启用跳过功能的节点**必须**挂载 `TaskSkipApprovalListener`。

**节点抄送人（ccConfig）字段：**

```json
{
  "ccConfig": [
    {"type": "candidateUsers", "userIds": ["qinfeng"], "selectedUsers": [{"value": "qinfeng", "label": "秦峰"}]},
    {"type": "submitter_dept_leader"},
    {"type": "dept_leader"}
  ]
}
```

可选 type：`candidateUsers` `candidateRoles` `candidateDeptPositions` `submitter_user` `submitter_dept_leader` `submitter_parent_dept_leader` `dept_members` `dept_leader`。详见 `references/bpmn-advanced.md` 第2节。

**连线（flows）字段：**

| 字段 | 必填 | 说明 |
|------|------|------|
| `id` | 是 | 连线唯一ID |
| `source` | 是 | 源节点ID |
| `target` | 是 | 目标节点ID |
| `name` | 否 | 连线名称 |
| `conditions` | 否 | 条件数组（自动 base64 编码） |
| `bypass` | 否 | `true` = 从右侧绕行 |

**条件格式：**
```json
{"field": "integer_xxx", "fieldType": "integer", "fieldName": "请假天数", "operator": "gt", "value": "3"}
```
operator：`eq` `ne` `gt` `gte` `lt` `lte`/`le` `in` `not_in` `contains` `is_empty` `is_not_empty`

> **DesForm 字段类型 → fieldType 映射：** `money`→`"money"` / `integer`→`"integer"` / `input`/`textarea`→`"input"` / `select`/`radio`/`checkbox`→对应同名 / `date`→`"date"` / `number`→`"number"`

**表单类型选择规则（强制）：** "online表单" → `formType="1"` 用 jeecg-onlform / "表单设计器" → `formType="2"` 用 jeecg-desform / 两者不可混用。

**表单关联（formLink）字段：**

| 字段 | 说明 | 示例 |
|------|------|------|
| `formType` | `1`=Online, `2`=DesForm, `3`=自定义 | `"2"` |
| `relationCode` | Online: `onl_{表名}`, DesForm: `desform_{编码}`, 自定义: 直接写 | `"onl_test_bpm_apply"` |
| `titleExp` | 业务标题 `${字段model}` | `"${user_xxx}提交的请假"` |
| `formTableName` | DesForm=表单编码, Online=表名 | `"oa_leave"` |
| `formDealStyle` | 处理方式 | `"default"` |
| `flowStatusCol` | 状态字段 | `"bpm_status"` |
| `formUrl` | 仅 formType=3 可选 | `"visitor/components/BizVisitorRegisterForm?edit=1"` |

> `relationCode` 无需手动加前缀，`bpmn_creator.py` 根据 `formType` 自动补全（1 加 `onl_`，2 加 `desform_`，3 不加）。Online 表单走流程必须含 `bpm_status` 字段。

**DesForm 表单绑定：**
```json
{"formLink": {"formType": "2", "relationCode": "oa_leave", "formTableName": "oa_leave",
  "flowStatusCol": "bpm_status", "titleExp": "${user_name}提交的请假申请"}}
```

**Online 表单绑定：**
```json
{"formLink": {"formType": "1", "relationCode": "test_bpm_apply", "formTableName": "test_bpm_apply",
  "flowStatusCol": "bpm_status", "titleExp": "BPM测试申请-${title}"}}
```

**自定义开发表单绑定：**
```json
{"formLink": {"formType": "3", "relationCode": "dev_demo_all_component_001",
  "formTableName": "demo_all_component", "flowStatusCol": "bpm_status", "titleExp": "全组件演示-${name}"}}
```

> **自定义开发表单（formType=3）使用场景与规则：**
> - **适用场景：** 通过代码生成器生成的 CRUD 表单（有独立的 Entity/Controller/Service/前端页面），不是 Online 表单也不是 DesForm 设计器表单
> - **relationCode 命名规则：** `dev_{表名}_001`，如 `dev_demo_all_component_001`（参考系统自带示例）
> - **formTableName：** 填数据库表名，如 `demo_all_component`
> - **flowStatusCol：** 必须为 `bpm_status`，表中需有该字段（varchar(10)）
> - **titleExp：** 使用 `${字段名}` 引用表中字段值，如 `全组件演示-${name}`
> - **前缀处理：** `bpmn_creator.py` 对 formType=3 **不自动加前缀**，relationCode 原样使用
> - **发起授权：** formType=3 **不需要**发起授权步骤（不需要调用 saveWorkorderAuth），跳过 Step 5
> - **前置条件：** 生成代码时需确保 Entity 中有 `bpmStatus` 字段（`@Dict(dicCode = "bpm_status")`），建表 DDL 中有 `bpm_status varchar(10)` 列

> **注意：** `relationCode` 无需手动加 `onl_` 前缀，`bpmn_creator.py` 会根据 `formType` 自动补全（`formType=1` 加 `onl_`，`formType=2` 加 `desform_`，`formType=3` 不加前缀）。Online 表单走流程必须在表中包含 `bpm_status` 字段。

**调用示例：**
```bash
python "<skill目录>/scripts/bpmn_creator.py" \
    --api-base <api_base> --token <token> --config leave_process.json

# 只生成 XML 不调用 API（调试用）
python "<skill目录>/scripts/bpmn_creator.py" \
    --api-base <api_base> --token xxx --config leave_process.json --dry-run
```

> **⚠ Windows 环境：**
> - **必须加 `-X utf8`**，否则中文 GBK 乱码
> - Python 未加 PATH 时用 PowerShell：`powershell -Command "& '$PYTHON_PATH' '-X' 'utf8' '<script>'"`
> - 删除临时文件用 PowerShell：`powershell -Command "Remove-Item 'C:\path\to\file'"`
> - 不要在 bash 中直接传 Windows 路径（盘符冒号问题），转 bash 格式（`/c/Users/...`）或用 PowerShell
> - **含 `${...}` 的脚本禁止用 `-c "..."`，必须写入 `.py` 文件执行（见规则7）**

#### 当通用脚本不满足需求时

对于会签、复杂子流程等场景，需编写临时 Python 脚本。阅读以下参考文件：
- `references/bpmn-xml-skeleton.md` — XML 骨架
- `references/bpmn-assignee-types.md` — 审批人配置
- `references/bpmn-layout.md` — 布局计算
- `references/bpmn-countersign.md` — 会签配置
- `references/bpmn-task-extend.md` — taskExtendJson + 监听器
- `references/bpmn-advanced.md` — 条件表达式 + 抄送 + 按钮 + 服务任务
- `references/bpmn-subprocess-gateway.md` — 网关 + 子流程
- `references/bpmn-save-process-api.md` — **saveProcess API 规范 + XML 转义 + 元素顺序 + 临时脚本模式**
- `references/example/*.bpmn` — 生产环境示例

### Step 4: 自动发布流程

通用脚本 `bpmn_creator.py` 已内置 `--deploy` 参数自动发布。手动发布 API：`PUT /act/process/extActProcess/deployProcess`，body `{"id": process_id}`。详见 [`references/bpmn-deploy-authorize.md`](references/bpmn-deploy-authorize.md)。

### Step 5: 发起授权

formType=1/2 需要授权（将表单授权给角色），formType=3 跳过。默认角色ID `f6817f48af4fb3af11b9e8bf182f618b`。

API：`GET getAuthorizedDesignList` 查已有 → `POST saveWorkorderAuth/{roleId}` 追加新表单ID。`authId` 必须包含已有+新增（逗号分隔），否则覆盖。

详见 [`references/bpmn-deploy-authorize.md`](references/bpmn-deploy-authorize.md)。

### Step 5.5: Online/DesForm 表单地址配置（重要）

> **开启 `formEditStatus=1` 的节点必须同时设置 PC 和移动端表单地址**，否则表单无法正常打开。仅对表单可编辑的节点（如草稿节点）设置。

| 表单类型 | PC (`modelAndView`) | 移动端 (`modelAndViewMobile`) |
|---------|---------------------------|-------------------------------------|
| **Online 表单** (formType=1) | `super/bpm/process/components/OnlineFormOpt` | `check/onlineForm/flowedit` |
| **DesForm 表单** (formType=2) | `{{DOMAIN_URL}}/desform/edit/{表单编码}/${BPM_DES_DATA_ID}?token={{TOKEN}}&taskId={{TASKID}}&skip=false` | *(同 PC 地址或留空)* |
| **自定义开发表单** (formType=3) | `{{viewDir}}/components/{{entityName}}Form?edit=1` | *(同 PC 地址或留空)* |

```python
# Online 表单
edit_node_config(api_base, token, process_id, 'task_draft', {
    'formEditStatus': '1',
    'modelAndView': 'super/bpm/process/components/OnlineFormOpt',
    'modelAndViewMobile': 'check/onlineForm/flowedit',
})
```

> 非可编辑节点不需要设置。关闭 formEditStatus 时必须同步清空表单地址。

### Step 6: 节点字段权限配置（可选）

> 详见 [`references/bpmn-field-permissions.md`](references/bpmn-field-permissions.md)

```python
from bpmn_creator import edit_node_config, set_node_field_permissions
edit_node_config(api_base, token, process_id, 'task_draft', {'formEditStatus': '1', ...})
set_node_field_permissions(api_base, token, process_id, 'task_draft', 'form_code', [
    {"field": "字段名", "visible": True, "editable": True, "required": True},
])
```

> **⚠️ 关键顺序：** `deploy_process` → `edit_node_config` → `deploy_process`（再发布） → `set_node_field_permissions`（deploy 后才保存权限）

### OA 审批意见字段配置规范

> 详见 [`references/bpmn-oa-approval-comments.md`](references/bpmn-oa-approval-comments.md)

### Step 7: 输出结果

脚本会自动输出流程 ID、名称、Key、发布状态等信息。

### Step 7.5: 流程高级配置（可选）

通过 `PUT /act/process/extActProcess/edit` 修改通知方式、催办、撤回、督办等。详见 [`references/bpmn-process-config.md`](references/bpmn-process-config.md)。

### Step 7.6: 设置报表打印地址（可选）

仅 formType=3 支持。通过 `PUT /act/process/extActProcessForm/edit` 设置 `reportPrintUrl`（不是 `extActProcess/edit` + `printUrl`）。详见 [`references/bpmn-process-config.md`](references/bpmn-process-config.md)。

---

## 自定义开发表单关联流程时的前端代码变更

> 详见 [`references/bpmn-custom-form-frontend.md`](references/bpmn-custom-form-frontend.md)

## OA 应用一键生成（表单 + 流程 + 授权）

> 当用户说"创建审批单"、"创建报销单"、"做一个OA表单带流程"等，使用本章节一次性完成 **表单设计 → 流程创建 → 流程发布 → 表单关联 → 角色授权**。

### OA 交互流程

#### OA Step 0: 解析用户需求

从用户描述中提取：应用名称、表单编码（`oa_` 前缀）、表单字段、流程节点、审批人。

#### OA Step 1: 展示应用摘要并确认

**必须展示以下内容，等待用户确认后再执行：**

```
## OA 应用摘要

- 应用名称：费用报销单
- 表单编码：oa_expense_reimbursement
- 目标环境：<api_base>

### 表单字段
| 序号 | 字段名称 | 控件类型 | 必填 |
|------|---------|---------|------|
| 1 | 申请人 | select-user | 是 |
| ... | ... | ... | ... |

### 流程节点
| 序号 | 节点名称 | 类型 | 审批人 |
|------|---------|------|--------|
| 1 | 开始 | startEvent | - |
| ... | ... | ... | ... |

### 连线

开始 → 提交 → 审批 → 结束

确认以上信息正确？(y/n)
```

#### OA Step 2: 一键执行创建

用户确认后，使用 `scripts/bpmn_oa.py` 脚本一次性完成全部操作。

**使用步骤：**
1. 根据用户需求生成 JSON 配置文件（Write 到工作目录的临时 `.json` 文件）
2. 用 Bash 执行脚本：
```bash
python "<jeecg-bpmn skill目录>/scripts/bpmn_oa.py" \
    --api-base <后端地址> --token <TOKEN> --config <config.json>
```
3. 删除临时 JSON 配置文件

**脚本自动完成：**
1. 创建设计器表单（调用 desform_creator）
2. 创建 BPMN 流程（调用 bpmn_creator）
3. 发布流程
4. 关联表单到流程
5. 设置草稿节点表单可编辑 + 表单地址
6. 查询已有授权 → 追加新表单ID → 保存授权给管理员角色

### OA JSON 配置格式

```json
{
  "appName": "费用报销单",
  "form": {
    "formName": "费用报销单",
    "formCode": "oa_expense_reimbursement",
    "layout": "word",
    "titleIndex": 2,
    "fields": [
      {"name": "报销单号", "type": "auto-number", "prefix": "BXBX"},
      {"name": "---", "type": "divider", "text": "基本信息"},
      {"name": "申请人", "type": "select-user", "required": true},
      {"name": "所在部门", "type": "select-depart", "required": true},
      {"name": "申请日期", "type": "date", "required": true},
      {"name": "报销类别", "type": "select", "required": true, "options": ["差旅费", "交通费", "办公用品"]},
      {"name": "---", "type": "divider", "text": "费用明细"},
      {"name": "报销金额", "type": "money", "required": true, "unit": "元"},
      {"name": "费用说明", "type": "textarea"},
      {"name": "发票/凭证", "type": "imgupload", "required": true},
      {"name": "附件", "type": "file-upload"},
      {"name": "---", "type": "divider", "text": "审批信息"},
      {"name": "部门负责人意见", "type": "oa-approval-comments"},
      {"name": "财务审核意见", "type": "oa-approval-comments"}
    ]
  },
  "process": {
    "processName": "费用报销审批流程",
    "processKey": "oa_expense_reimbursement_process",
    "typeId": "oa",
    "nodes": [
      {"id": "start", "type": "startEvent", "name": "开始"},
      {"id": "task_draft", "type": "userTask", "name": "提交报销申请", "draft": true,
       "assignee": {"type": "expression", "value": "applyUserId"}},
      {"id": "task_dept", "type": "userTask", "name": "部门负责人审批",
       "assignee": {"type": "role", "value": "manager"}},
      {"id": "task_finance", "type": "userTask", "name": "财务审核",
       "assignee": {"type": "role", "value": "finance"}},
      {"id": "end", "type": "endEvent", "name": "结束"}
    ],
    "flows": [
      {"id": "flow_1", "source": "start", "target": "task_draft"},
      {"id": "flow_2", "source": "task_draft", "target": "task_dept"},
      {"id": "flow_approve", "source": "task_dept", "target": "task_finance", "name": "通过"},
      {"id": "flow_reject", "source": "task_dept", "target": "end", "name": "拒绝"},
      {"id": "flow_end", "source": "task_finance", "target": "end"}
    ]
  },
  "auth": {
    "roleId": "f6817f48af4fb3af11b9e8bf182f618b",
    "authMode": "role"
  },
  "nodePermissions": {
    "task_draft": [
      {"field": "报销单号", "visible": true, "editable": false},
      {"field": "报销金额", "visible": true, "editable": true, "required": true}
    ],
    "task_dept": [
      {"field": "部门负责人意见", "visible": true, "editable": true}
    ]
  }
}
```

> **nodePermissions（可选）：** 按节点编码配置字段权限。key 为节点 ID（如 `task_draft`），value 为字段权限数组。`field` 支持中文字段名或字段 model。`required=true` 时自动强制 `visible=true` + `editable=true`。

### OA 表单字段类型

> 详见 [`references/bpmn-oa-templates.md`](references/bpmn-oa-templates.md)
> 包含：28种字段类型、OA 流程分支规则、callActivity 规则、会签子流程、常见 OA 模板。

## 编辑已有流程

传入 `"processId": "已有流程ID"` 即可更新。查询已有 XML：`GET /act/process/extActProcess/queryById?id={id}`（`processXml` 为 base64，需 decode）。详见 [`references/bpmn-deploy-authorize.md`](references/bpmn-deploy-authorize.md)。

## 错误处理

| 错误 | 解决方案 |
|------|---------|
| Token 过期（401） | 提示用户重新获取 X-Access-Token |
| `流程ID重复` | 重新生成时间戳作为 processkey |
| `不是最新版本` | 先查询最新 processDefinitionId 再保存 |
| 中文乱码 | 使用 Python urllib（不要用 curl） |
| `'str' object has no attribute 'get'` | API 返回 `result` 不是 dict，先 `print(type(result))` 确认结构 |
| `KeyError: 0` | `result` 是 dict 不是 list（如 `approvalRole/rootList`），需 `result['records']` |
| `bash: bad substitution` | 脚本含 `${...}`，不能 `-c "..."` 执行，必须写 `.py` 文件（规则7） |
| taskExtendJson 全为 false/0 | `sameMode`/`skipOne` 放在节点顶层而非 `assignee` 内部（规则1修正） |
| `编码重复或表名已被授权流程！` | 子流程已绑定表单但主流程重复绑定（规则8） |
| 含 `${...}` 的脚本报 `bad substitution` | bash 展开 shell 变量，改用文件执行（规则7） |
| Windows 路径被截断 | 避免在 bash 中直接用 `C:\path\to\file`，用 PowerShell 包装或 `/c/path` 格式 |
| `AttributeError: module 'desform_utils' has no attribute 'get_form_detail'` | 该函数不存在，用 `bc.get_desform_fields()` 或 `du.get_form_fields()` |
| 编辑 XML 时正则匹配不到节点（"未找到节点"） | XML 使用 `bpmn2:userTask` 命名空间前缀，正则须用 `(?:bpmn2:)?`（规则11） |
| 发布报 `cvc-complex-type.3.2.2: 不允许出现属性 'groupType'` | `groupType` 缺少 `flowable:` 前缀，或 `candidateUsersExpression` 类型误加了 groupType（规则12） |
| saveProcess 报"路径不存在" | 路径应为 `/act/designer/api/saveProcess`，Content-Type 须为 `application/x-www-form-urlencoded`（规则13） |
| 条件值显示为空（"原始JSON数据"缺少值字段） | **双重原因**：① 条件值字段名必须是 `expectedValue` 而非 `value`；② `fieldType` 必须与 DesForm 字段实际类型完全一致。两者任一错误都会导致前端忽略条件值（规则16） |
| 职级审批节点"职务级别"为空 | `getApplyUserDeptPositionLevel` 参数错误，必须传三个参数 `(sys_org_code, applyUserId, 'positionId')`，不能用 `(execution, 'positionId')`（规则17） |
| 删除 XML 行后 deploy 报 `cvc-complex-type.2.4.a` 无效内容 | 整行删除时丢失了同行的 `</bpmn2:extensionElements>` 等结束标签。探查时必须用 `repr(line)` 确认行内完整内容，删除时只删目标标签，保留同行其他内容（规则18） |
| `saveProcess` 成功但提交了损坏的 XML，deploy 失败后再读取已是损坏版本 | `saveProcess` 持久化不依赖 deploy 成功。保存前必须先用 `ET.fromstring()` 本地校验 XML 结构合法性（规则19） |
| callActivity 变量设置面板「源头(Source)」显示为空 | `flowable:in` 使用了 `sourceExpression` 属性，前端只识别 `source`。改为 `<flowable:in source="assigneeUserId" target="assigneeUserId" />`（规则20） |
| 向已有流程插入节点后连线全部混乱、分支变形 | 增量偏移 DI 坐标导致网关中转 waypoint 错位。必须完整重写整个 `<bpmndi:BPMNDiagram>` 区块，按新节点序列从零计算坐标（规则21） |
| 新建流程后 `r['result']['obj']` 报 `KeyError` | `saveProcess` 新建时 `result` 可能为 null，必须保存后按 processKey/processName 重新查询取 ID（规则22） |
| 子流程前端节点列表缺少「开始」节点 | `nodes_str` 未包含 `id=start###nodeName=开始@@@`，startEvent 未写入节点配置表（规则23） |
| 子流程开始节点表单地址为空，无法打开表单 | start 节点需配置主流程相同的表单地址（PC/移动端）；`formEditStatus` 按需设置，查看表单不需要设为 1，编辑表单才需要（规则24） |
| 保存后流程图多个节点堆叠在同一位置（y 坐标重叠）、连线乱飞 | `calc_layout` 对长流程/多会签链未正确推进 y 坐标。`main()` 已内置 `validate_and_fix_layout` 在保存前自动检测并重建 BPMNDiagram（规则25）；已有流程需手动：获取 XML → 检测重叠 → 重建 DI → saveProcess + deploy |

## 数据库配置表

| 表名 | 说明 |
|------|------|
| `ext_act_process` | 流程主表（属性、XML、通知等） |
| `ext_act_process_form` | 表单绑定（类型、标题表达式等） |
| `ext_act_process_node` | 节点配置（功能开关） |
| `ext_act_process_node_auth` | 字段权限 |

详见 `references/bpmn-db-config.md`。

## 参考文档

- `references/bpmn-call-activity.md` — 调用子流程 / 内嵌子流程
- `references/bpmn-manual-branch.md` — 手工分支（意见分支）
- `references/bpmn-signal-message-events.md` — 信号与消息事件（6种类型）
- `references/bpmn-deploy-authorize.md` — 发布、授权、编辑已有流程
- `references/bpmn-process-config.md` — 高级配置、报表打印
- `references/bpmn-save-process-api.md` — saveProcess API、XML转义、临时脚本
- `references/bpmn-templates.md` — 参考文件索引

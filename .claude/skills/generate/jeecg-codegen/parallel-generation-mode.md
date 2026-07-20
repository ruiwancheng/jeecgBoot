# 并行生成模式（Beta）

> **状态：Beta — 可能不稳定**
> 本模式通过把前端、后端代码生成分派给两个独立 SubAgent 并行执行,以缩短整体耗时。
> 由于 SubAgent 之间无法共享主会话上下文,跨端契约对齐完全依赖主 Agent 在派发前的"契约冻结"和派发后的"跨端校验"。任何一环出错,都可能产生前后端不一致的代码。
> **不确定时,默认使用串行生成模式（见 SKILL.md "生成模式"章节）。**

---

## 1. 适用场景

| 场景 | 是否适合并行 | 说明 |
|------|------|------|
| 全量生成单表 / 树表 | ✅ 适合 | 前后端文件目录完全隔离,契约简单 |
| 全量生成一对多（主子表） | ⚠️ 谨慎 | 子表数量越多,契约项越多,出错概率越高 |
| **增量字段修改（场景 C）** | ❌ 不适合 | 需要先读已有文件再增量改,SubAgent 双重压缩会丢失现有代码细节,强制串行 |
| 复杂业务逻辑（自定义增强、JS 增强、SQL 增强） | ❌ 不适合 | 超出模板范围,需主 Agent 全程把控 |

**规则：** 一旦进入"场景 C 增量修改"流程,**禁用并行模式**,自动回落串行。

---

## 2. Beta 已知风险

派发前必须主动告知用户以下风险:

1. **字段命名漂移**：DB 字段 / Java 字段 / Vue 字段三态命名若未在契约里逐字固定,两个 SubAgent 可能各自推导出不同形式。
2. **字典编码不一致**：状态字段使用了字典,若主会话未先确认字典编码,SubAgent 可能在两端使用不同编码或自造编码。
3. **API URL 漂移**：后端 `@RequestMapping` 与前端 `api.ts` 的 url 字符串必须完全一致,SubAgent 各自猜测可能拼错路径或大小写。
4. **风格选项不同步**：vue3 / vue3Native、Tab-in-Modal / ERP / 内嵌子表等前端布局风格,以及一对多子表后端返回类型（`Result<IPage<T>>` vs `Result<List<T>>`),必须在契约里逐项指定。
5. **`jeecg-dev` 规范遗漏**：SubAgent 不会自动加载 `jeecg-dev` skill,update-begin/end 标记、命名约定等必须在 prompt 里显式写明。
6. **Flyway / 菜单 SQL 冲突**：两个 SubAgent 若同时尝试写 SQL,会出现版本号竞争。SQL 必须由主 Agent 串行生成,不下放给 SubAgent。
7. **字典创建被违规外包**：SKILL.md 已明确"字典创建必须写入 Flyway SQL,禁止走 API"。SubAgent 不知道这条规则,极易调用 `find_or_create_dict()` —— 必须在派发 prompt 里显式禁止。
8. **生成结果汇报失真**：SubAgent 返回的是任务摘要,不是实际差异。主 Agent 必须自己读取生成的文件做校验,不能只听 SubAgent 报告。
9. **FormSchema 隐藏 id 字段遗漏**：SKILL.md 的"翻车点 2"明确所有 FormSchema 首位必须含隐藏 id —— 前端 SubAgent 必须在 prompt 里显式提醒,否则编辑功能必报错。

---

## 3. 派发前 — 主 Agent 必须冻结的"契约"

主 Agent 在派发任何 SubAgent **之前**,必须自行完成以下工作并在主会话中向用户展示确认。这部分**不能外包**。

### 3.1 实体契约表（必填,逐字一致传给两个 SubAgent）

| 契约项 | 示例 | 备注 |
|------|------|------|
| tableName (snake) | `biz_demo_order` | 数据库表名 |
| entityName (Pascal) | `BizDemoOrder` | Java 类名 |
| entityName_uncap (camel) | `bizDemoOrder` | Java 变量名 / 前端文件名前缀 |
| entityPackage | `biz` | Java 包路径段 |
| viewDir | `biz/demoOrder` | 前端目录 |
| description | `订单管理` | 中文描述,用于注释和菜单名 |
| 主键策略 | `ASSIGN_ID` / `AUTO` / ... | 参照已有表 |
| API URL 前缀 | `/biz/bizDemoOrder` | 后端 Controller + 前端 api.ts 必须一致 |
| 前端风格 | `vue3` (封装) / `vue3Native` (原生) | 影响生成文件数和架构 |
| 表类型 | 单表 / 树表 / 一对多 | 决定模板 |
| 一对多布局风格（若适用） | 默认 / Tab-in-Modal (C9) / 内嵌子表 (C12) / ERP (C11) | 影响 Modal/List 结构 |
| 后端模块 | `jeecg-module-system/jeecg-system-biz` | moduleRoot |
| Flyway 版本号 | `V20260515_1430__订单管理.sql` | 由主 Agent 计算,不能让 SubAgent 自己取 |
| 菜单 ID 时间戳 | `1747300200123` | 由主 Agent 用 `date +%s%3N` 取一次 |

### 3.2 完整字段清单（必填）

每个字段必须明确以下属性,**不允许 SubAgent 自行推导**:

| 字段名 (camel) | DB 字段 (snake) | DB 类型 | Java 类型 | 前端控件 | 字典编码 | 必填 | 注释 |
|---|---|---|---|---|---|---|---|
| orderNo | order_no | varchar(64) | String | Input | - | 是 | 订单编号 |
| amount | amount | decimal(10,2) | BigDecimal | InputNumber | - | 是 | 金额 |
| status | status | varchar(20) | String | JDictSelectTag | order_status | 是 | 状态 |
| ... | ... | ... | ... | ... | ... | ... | ... |

### 3.3 字典依赖（必填,严格遵循 SKILL.md 字典规则）

派发前主 Agent 必须按 `jeecg-system` skill 的"先查后建"原则,确认所有字典编码:

- **已存在的字典** → 通过 `query-dicts` / `query-dict` 或 MySQL 查询确认,记录 `dict_code`、可选值。
- **不存在的字典** → 由**主 Agent 自己**写入当次的 Flyway SQL（`sys_dict` + `sys_dict_item` INSERT 语句）。
- **禁止**：让任何 SubAgent 通过 `find_or_create_dict()` / `create_dict()` API 创建字典。
- **禁止**：让 SubAgent 自造未在契约里出现的字典编码。

### 3.4 用户确认

把 3.1 + 3.2 + 3.3 整合成摘要,向用户展示并等待"确认"。**任何契约项不明确时,禁止进入派发阶段。** 这一步与 SKILL.md 交互流程的 Step 3"展示摘要"等价,**不可跳过**。

---

## 4. SubAgent 派发规范

### 4.1 通用要求

- 两个 SubAgent **必须同时派发**（同一条消息内多个 Agent 工具调用,达成真正并行）。
- 一旦派发,**不允许中途追加新要求**。如需修改,等两个 SubAgent 都完成后由主 Agent 整合处理。
- SubAgent 类型统一使用 `general-purpose`,**不要**用 `Explore`（Explore 只读片段,无法写文件）。
- 派发 prompt 必须自包含 —— SubAgent 看不到主会话的对话历史、CLAUDE.md、memory。

### 4.2 后端 SubAgent — Prompt 模板

```
任务：基于以下契约,生成 JeecgBoot 后端 CRUD 代码（仅 Java 文件 + Mapper XML,不生成 SQL）。

【项目环境】
- 后端根路径：{主会话从 CLAUDE.md / project_paths.md 读取的绝对路径}
- 必须遵循 jeecg-dev 规范：所有自动生成代码块用 update-begin/end 注释包裹,
  命名/Controller/Service/Entity 模式严格参照 codegen-reference.md 模板,
  不要凭框架直觉自由发挥。
- 参考模板：读取 {skill 根目录}/codegen-reference.md 的 Section A（单表）/ B（树表）
  / C/D（一对多,具体子节由契约的布局风格决定）,逐字符按模板生成。

【铁律 — 文件路径】
- 写每个文件之前,必须先在 codegen-reference.md 顶部"文件清单"找到对应路径模板,
  逐字符比对后再调用 Write。禁止猜测路径。

【实体契约】
{完整粘贴 3.1 表格,逐字一致}

【字段清单】
{完整粘贴 3.2 表格}

【字典依赖】
{完整粘贴 3.3,标注哪些字典已存在,直接使用其 dict_code}
注意：不要调用 find_or_create_dict() 或任何字典创建 API。
契约里没列出的字典编码一律不能出现在代码中。

【输出要求】
1. 按 codegen-reference.md 的文件清单逐个生成,使用 Write 工具。
2. 生成完成后,返回:
   - 生成的文件路径列表（绝对路径）
   - 每个文件的字段名清单（用于主 Agent 跨端校验）
   - Controller @RequestMapping 完整路径
   - 任何与契约不一致的地方（如有必须显式说明,不要静默调整）
3. 不要生成 Flyway SQL、不要生成菜单 SQL、不要修改前端文件、不要调用任何字典 API。
4. 不要询问主 Agent —— 契约里没明确的,按 jeecg-dev 默认规范处理并在返回时备注。
```

### 4.3 前端 SubAgent — Prompt 模板

```
任务：基于以下契约,生成 JeecgBoot 前端 Vue3 CRUD 代码（仅前端文件,不生成后端、不生成 SQL）。

【项目环境】
- 前端根路径：{主会话从 CLAUDE.md / project_paths.md 读取的绝对路径}
- 前端风格：{vue3 封装 / vue3Native 原生 —— 二选一,与契约一致,不允许中途切换}
- 参考模板：读取 {skill 根目录}/codegen-reference.md 的对应 Section
  （单表 A / 树表 B / 一对多 C9/C11/C12 / vue3Native C13）,逐字符按模板生成。

【铁律 — 文件路径】
- 写每个文件之前,必须先在 codegen-reference.md 顶部"文件清单"找到对应路径模板,
  逐字符比对后再调用 Write。禁止猜测路径。

【铁律 — FormSchema 隐藏 id 字段】
- 所有 FormSchema（主表 Modal 表单、一对一子表 Form、ERP 子表 Form、树表 Modal 表单）
  必须在数组首位包含：
    { label: '', field: 'id', component: 'Input', show: false },
- 缺失此字段会导致编辑功能直接报错,这是高频翻车点。

【实体契约】
{完整粘贴 3.1 表格,逐字一致}

【字段清单】
{完整粘贴 3.2 表格}

【字典依赖】
{完整粘贴 3.3,前端直接使用 dict_code,不要自行创建字典,不要自造编码}

【输出要求】
1. 按 codegen-reference.md 的前端文件清单生成,使用 Write 工具。
2. 生成完成后,返回:
   - 生成的文件路径列表（绝对路径）
   - data.ts 中所有字段的 dataIndex 清单
   - api.ts 中所有 URL 字符串
   - 使用的字典编码清单
   - 任何与契约不一致的地方
3. 不要修改后端文件、不要生成 SQL、不要修改菜单、不要调用任何字典 API。
4. 不要询问主 Agent —— 契约里没明确的,按默认规范处理并在返回时备注。
```

### 4.4 主 Agent 自己承担的部分（不下放）

派发 SubAgent 的同时,主 Agent **自己**完成以下工作（与 SubAgent 并行进行）:

1. 生成 Flyway 建表 SQL（含字段、注释、索引）。
2. 生成字典 INSERT SQL（如有新建字典,按"字典创建必须写入 Flyway SQL"规则,sys_dict + sys_dict_item INSERT 写入同一份 Flyway 文件）。
3. 生成菜单 SQL（含菜单 + 按钮权限 + 角色授权,使用主 Agent 自己取的时间戳）。
4. （本地环境）准备 SQL 执行计划,但**暂不执行**,等校验通过后再按 SKILL.md"本地环境自动执行菜单 SQL 规则"执行。

---

## 5. 派发后 — 主 Agent 跨端校验（强制）

两个 SubAgent 都返回后,主 Agent **必须**亲自执行以下校验,**不能信任 SubAgent 的自报告**:

### 5.1 字段一致性校验

```
读取 Entity.java 中所有 @TableField 字段名（camel）
读取 data.ts 中所有 columns[].dataIndex 和 formSchema[].field
diff 两份清单 → 必须完全一致（除系统字段）
```

### 5.2 API URL 校验

```
读取 Controller.java 的 @RequestMapping("...") 完整路径
读取 api.ts 的所有 Api.xxx = '...' URL 字符串
确认前端 URL = 后端 @RequestMapping + 子路径,大小写完全一致
```

### 5.3 字典编码校验

```
读取 data.ts 中所有 dictCode: '...' 出现位置
确认每个 dictCode 都在契约 3.3 的字典清单内（不能有自造编码）
确认这些 dict_code 在 sys_dict 表存在(走 jeecg-system 查询)或已写入当次 Flyway SQL
```

### 5.4 风格契约校验（仅一对多）

```
若契约是 Tab-in-Modal (C9)：确认 Modal.vue 有 wrapClassName="j-cgform-tab-modal" 和 radio-group
若契约是 内嵌子表 (C12)：确认 List.vue 有 expandedRowRender,subTables/ 目录存在
若契约是 ERP (C11)：确认子表是独立 Tab 而非 Modal 内嵌
若契约是 vue3Native：确认 Form.vue 存在,Modal 是薄包装,使用 useValidateAntFormAndTable
```

### 5.5 翻车点校验（强制项）

```
grep 所有 *.data.ts 中的 formSchema → 确认每个 schema 数组首位都有
  { label: '', field: 'id', component: 'Input', show: false }
缺失 → 直接报错,本次校验不通过
```

### 5.6 jeecg-dev 规范校验（抽样）

```
随机抽取 2-3 个生成文件,grep update-begin / update-end 标记
若全部缺失 → SubAgent 未遵循 jeecg-dev,需修复
```

### 5.7 校验通过后

- 输出校验报告（哪些项通过、哪些项有偏差）。
- 偏差项 → 主 Agent 直接用 Edit 修复（不再派发 SubAgent,避免无限循环）。
- 全部通过 → 输出最终文件清单,并按 SKILL.md"本地环境自动执行菜单 SQL 规则"执行 SQL。
- 询问用户是否生成移动端代码（对应 SKILL.md 的 Step 6）。

---

## 6. 回退策略（Fallback）

以下任一条件成立,**立即停止并行,切回串行模式从头来过**:

| 触发条件 | 回退动作 |
|------|------|
| 任一 SubAgent 报告失败 / 异常 | 删除两个 SubAgent 已生成的所有文件,切串行 |
| 跨端校验出现 ≥ 3 处偏差 | 删除已生成文件,切串行 |
| 字典编码偏差（前后端不一致或出现自造编码） | 删除已生成文件,切串行（字典对不齐后果严重） |
| FormSchema 隐藏 id 字段缺失（任一文件） | 直接 Edit 补上,不切串行 |
| 用户在派发后追加了新需求 | 等当前两个 SubAgent 完成,把变更作为增量修改单独处理 |

**串行回退时,告诉用户：** "并行生成模式（Beta）出现 {具体问题},已切换为串行生成,正在重新开始。"

---

## 7. 收益与成本

- **预期收益**：单表 / 简单树表场景下,前后端生成耗时可压缩到原来的 60-70%（取决于前后端文件数量是否均衡）。
- **额外成本**：
  - 主 Agent 需要花更多 token 在契约冻结上（值得,串行也该做）。
  - 跨端校验是新增的固定开销。
  - 失败回退时,前两个 SubAgent 的 token 完全浪费。
- **建议**：复杂度高的场景（一对多 + ERP 风格 + 多子表 + 自定义增强）不要用并行模式,收益不抵风险。

---

## 8. 与其他规则的关系

- **SKILL.md 铁律(Step 2/3 不可跳过)**：并行模式不影响这条铁律 —— 契约冻结 + 用户确认必须在派发 SubAgent **之前**完成,本质上对应 Step 2/3。
- **SKILL.md ⛔ 字典创建必须写入 Flyway SQL**：派发 prompt 里显式禁止 SubAgent 调用字典 API,字典 INSERT 由主 Agent 写入 Flyway。
- **SKILL.md ⛔ 接口禁止猜测规则**：派发 prompt 里强调 SubAgent 不得猜测接口路径,所有 @RequestMapping / URL 来自契约 3.1。
- **SKILL.md ⛔ 写文件前的强制自检（FormSchema id / 路径）**：派发 prompt 里逐条写明这两条铁律,SubAgent 必须遵守。
- **`jeecg-dev` 规范**：派发 SubAgent 的 prompt 里必须显式提及"遵循 jeecg-dev 规范",因为 SubAgent 不会自动加载该 skill。
- **`jeecg-system` 主数据查询**：字典/角色/部门"查"可由 SubAgent 间接使用,但"建"必须主会话完成（字典走 Flyway SQL,其他主数据走 API)。
- **`codegen-reference.md`**：两个 SubAgent 都必须读取它（这是模板源）,不能让 SubAgent 凭印象生成。
- **本地 SQL 自动执行规则**：菜单 SQL 由主 Agent 串行生成和执行,与并行模式无关。

---

## 9. 何时升级 Beta → Stable

满足以下全部条件后,可以考虑去掉 Beta 标记:
- 单表 / 树表场景下,连续 20 次并行生成,跨端校验零偏差。
- 一对多场景下,连续 10 次并行生成,跨端校验偏差 ≤ 1 处且能自动修复。
- 用户反馈中无"前后端字段对不齐 / API 路径错 / FormSchema id 漏 / 字典编码错"类问题。

在此之前,SKILL.md 必须保留串行为默认,并在每次进入并行模式前明确告知用户 Beta 状态。

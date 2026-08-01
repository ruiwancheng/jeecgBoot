---
name: decompose
description: 大任务拆分方法论 — 按页面顶层+子功能细分，6 要素+8 反模式+粒度规则。被 /decompose 命令加载。
version: 1.0.0
---

# decompose — 大任务拆分方法论

## 核心理念

**端到端可手工验证的最小切片。** 每个切片完成后，用户能在浏览器里点一遍看到结果。

## 拆分两级结构

```
顶层切片（页面级）
├── 页面 1：订单列表页（complex）
│   ├── 子切片 1.1：列表展示+新建
│   ├── 子切片 1.2：编辑订单
│   ├── 子切片 1.3：作废订单
│   └── 子切片 1.4：审核订单
└── 页面 2：订单详情页（complex）
    ├── 子切片 2.1：物料明细展示
    └── 子切片 2.2：物料编辑
```

### 何时需要子功能细分？

| 页面复杂度 | 处理 |
|----------|------|
| **simple**（每页 1 个功能，如字典） | 顶层 1:1 对应子切片（不细分） |
| **complex**（每页多个操作，如订单列表页） | 顶层 + 子功能细分 |

**判断 simple vs complex 的方法：** 数页面里的用户操作流。1 个 = simple，≥2 个 = complex。

### 子功能粒度规则

| 代码行数 | 处理 |
|---------|------|
| **≤5 行** | 必须合并到相邻子功能 |
| **6-50 行** | 独立子功能 |
| **\>50 行** | 考虑再拆 |

---

## 6 要素拆分原则

每个子功能切片必须包含：

1. **业务名 + 用户操作路径**
   - 例：*"新建订单"* — 浏览器打开 `/order/list` → 点"新建" → 填客户+物料 → 保存 → 列表出现新行

2. **验收标准**（UI 上能看到什么）
   - ✅ *"列表显示新订单，客户名/总金额正确"*
   - ❌ *"Service 返回 Page<XxOrder>"*（用户看不到）

3. **依赖关系**
   - 例：*"依赖 1.1（订单主表已存在）"*
   - **禁止循环依赖**

4. **风险等级**
   - **高** = 改 Entity / SQL / 状态机 / 主子表
   - **中** = 改 Service / Controller / 加字段 / 跨表查询
   - **低** = 改 Vue / 改文案 / 加样式

5. **工作量估算**
   - **小** ≈ ≤20 行代码
   - **中** ≈ 21-100 行
   - **大** ≈ \>100 行（**警示**：可能需要再拆）

6. **Rollback 策略**
   - git commit 锚点（命名：`slice-<顶层ID>.<子ID>-<业务名-kebab>`）
   - 回退命令：`git revert <commit>`

---

## 8 条反模式（自检必查）

详见命令文件 `decompose.md` 的"反模式清单"章节。**输出前必须主动检查每条，违反任何一条都要警告用户并修正。**

---

## 粒度自检清单

`/decompose` 输出前必须逐项自检：

- [ ] **最小闭环**：首个切片能跑通（打开页面 → 新建 → 列表显示）
- [ ] **可验证**：每个子切片都有用户操作路径
- [ ] **可观察**：每个子切片都有 UI 验收标准
- [ ] **可评估**：风险等级已标注（高/中/低）
- [ ] **可估算**：工作量估算已标注（小/中/大）
- [ ] **可回退**：Rollback 策略已标注（commit + revert 命令）
- [ ] **无循环**：依赖关系图无环
- [ ] **无过细**：无 ≤5 行的孤立子切片
- [ ] **无反模式**：8 条反模式逐条检查通过

---

## 状态文件结构

`.claude/.decompose-state.json`：

```json
{
  "task": "销售订单模块",
  "created_at": "2026-07-31T19:30:00+08:00",
  "updated_at": "2026-07-31T19:30:00+08:00",
  "slices": [
    {
      "id": "1",
      "name": "订单列表页",
      "page": "/order/list",
      "type": "page-level",
      "complexity": "complex",
      "status": "in_progress",
      "current_child": "1.2",
      "children": [
        {
          "id": "1.1",
          "name": "列表展示+新建",
          "type": "feature",
          "status": "done",
          "commit": "abc1234",
          "user_path": "浏览器打开 /order/list → 点'新建' → 填客户+物料 → 保存 → 列表出现新行",
          "acceptance": "列表展示订单数据，新建按钮可点击，保存后新行出现在列表中",
          "depends_on": [],
          "risk": "medium",
          "effort": "medium",
          "files": [
            "jeecg-boot/.../OrderController.java",
            "jeecg-boot/.../OrderService.java",
            "jeecg-boot/.../Order.java",
            "jeecg-boot/.../OrderMapper.xml",
            "jeecgboot-vue3/src/views/order/OrderList.vue"
          ],
          "rollback": "git revert abc1234"
        }
      ]
    }
  ]
}
```

### 状态字段说明

| 字段 | 取值 | 说明 |
|------|------|------|
| `status` | pending / in_progress / done / blocked | 切片进度 |
| `current_child` | 子切片 ID 或 null | 当前正在做的子切片 |
| `commit` | git commit hash | 子切片完成时的 commit |

---

## Token 成本估算

| 切片规模 | orca-review | Token |
|---------|-------------|-------|
| ≤3 文件 | 免评 | 0 |
| 4-10 文件 | 轻量 | ~30K |
| \>10 文件 | 完整 | ~150K |

> 每个切片自带成本预估，让用户决策。

---

## 拆分完整示例：销售订单模块

### 输入

> "实现销售订单管理模块"

### 输出（机器可解析 JSON，v4.1）

`/decompose` 输出**纯 JSON 格式**（供 `auto-delegate.sh` 自动派发使用）：

```json
{
  "task": "实现销售订单管理模块",
  "generated_at": "2026-08-01T20:45:00+08:00",
  "slices": [
    {
      "id": "slice-1.1",
      "name": "订单列表页（列表展示+新建）",
      "page": "/order/list",
      "type": "page-level",
      "user_path": "浏览器打开 /order/list → 点"新建" → 填客户+物料 → 保存 → 列表出现新行",
      "acceptance": "列表展示订单数据，新建按钮可点击，保存后新行出现在列表中",
      "depends_on": [],
      "risk": "medium",
      "effort": "medium",
      "files": ["OrderController.java","OrderService.java","Order.java","OrderMapper.xml","OrderList.vue"],
      "rollback": "git revert <slice-1.1-commit>",
      "review_required": true
    },
    {
      "id": "slice-1.2",
      "name": "编辑订单",
      "user_path": "列表 → 点击行 → 编辑 → 保存",
      "acceptance": "列表显示更新后的数据",
      "depends_on": ["slice-1.1"],
      "risk": "medium",
      "effort": "small",
      "files": [],
      "rollback": "git revert <slice-1.2-commit>",
      "review_required": true
    },
    {
      "id": "slice-1.3",
      "name": "作废订单（带确认）
        user_path: 列表 → 点击作废 → 确认 → 状态变"已作废"
        acceptance: 列表状态变化，按钮禁用
        depends_on: ["1.1"]
        risk: medium
      - id: 1.4
        name: 审核流（提交→审核→通过/驳回）
        user_path: 列表 → 提交 → 切换用户 → 审核 → 状态机流转
        acceptance: 每个状态显示对应操作按钮
        depends_on: ["1.1"]
        risk: high  # 状态机
  - id: 2
    name: 订单详情页
    page: /order/detail/:id
    type: page-level
    complexity: complex
    children:
      - id: 2.1
        name: 物料明细展示+新增
        user_path: 详情页 → 添加物料行 → 保存
        acceptance: 详情页显示物料明细列表
        depends_on: ["1.1"]
        risk: high  # 主子表 SQL
```

### 执行顺序建议

1. **1.1 列表展示+新建**（最小闭环，立刻验收）
2. **1.2 编辑订单**（依赖 1.1，~20 行）
3. **1.3 作废订单**（依赖 1.1，独立功能）
4. **2.1 物料明细**（依赖 1.1，主子表）
5. **1.4 审核流**（依赖 1.1，状态机风险高）
6. （如有）3. 订单导入/导出/报表等独立页面

---

## 常见错误及修正

| 错误 | 修正 |
|------|------|
| 顶层 1 个 = 列表页所有操作合并 | complex 页面必须拆子功能 |
| 子功能 ≤5 行还独立成片 | 必合并 |
| 验收标准写"Service 返回 X" | 必须写 UI 上能看到的 |
| 风险等级全标"低" | Entity/SQL/状态机必标"高" |
| 首个切片无法跑通最小闭环 | 重排，让 1.1 能端到端走通 |
| 状态文件忘更新 | 每片 done 强制更新状态文件 |
| 切片完成后没 commit | 必须 `git commit slice-<ID>-<业务名-kebab>` |

---

## 与 `/done` 的衔接

每片 done 时，**强制执行**：

1. **git commit**：`slice-<顶层ID>.<子ID>-<业务名-kebab>`
2. **更新状态文件**：子切片 `status: done` + `commit: <hash>` + 顶层 `current_child` 推进
3. **后端健康检查**：`curl getEncryptedString` 返回 200
4. **写状态变更到 `.claude/.decompose-state.json`**（gitignore 模式）

下次输入 `/decompose`（无参数）→ 检测状态文件 → 提示继续下一个子切片。

---

## 拆分方法论的局限

- **过度细分风险**：≤5 行必合并，但 6-50 行也可能太细（看验收粒度）
- **跨页面操作流难切**：如"订单→发货→收货"涉及多个页面，按页面切会导致中间状态不可验收
- **配置/初始化切片**：建表、字典初始化等"非页面"内容，按"可手工验证"标准可能无法切片 → 标 `effort: small, risk: low`，单独成片（**首个切片前置依赖**）

> **跨页面操作流**的处理：拆为"每个页面的关键节点"，如"订单页提交 + 发货页创建"，每个节点是 1 个切片，依赖关系显式标注。
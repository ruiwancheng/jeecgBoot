# /coverage — 测试覆盖率统计

> **业务人员命令**：查看当前测试覆盖情况，找到待补缺口。

## 命令格式

```bash
/coverage                    # 总览：覆盖率统计表
/coverage gap                # 缺口清单：所有无覆盖端点
/coverage <项目>             # 单项目：项目内详情
/coverage <项目> <模块>      # 单模块：模块内详情
```

## 输出格式

### `/coverage`（总览）

```markdown
## 测试覆盖率总览（2026-08-04）

**前端页面**：38 个 | 后端 Controller：40 个 | 总端点：~180 个

| 维度 | 已覆盖 | 总数 | 覆盖率 |
|---|---|---|---|
| 页面（E2E spec） | 36 | 38 | 95% |
| 链路（chains） | 9 | ? | ? |
| 模块（modules） | 14 | ? | ? |
| 端点（API） | ~145 | ~180 | ~80% |

### 缺口（按优先级）

🔴 P0 — 完全无覆盖：
- customerAddress（7 端点，0 调用）
- customerContact（7 端点，0 调用）
...

🟡 P1 — 部分覆盖：
- salesInvoice（写入路径覆盖不足）
- purchaseInvoice（写入路径覆盖不足）

🟢 P2 — 已基本覆盖：
- basic/material（55 次调用）
```

### `/coverage gap`（缺口清单）

按 controller 列出无覆盖端点：

```markdown
## 完全无覆盖端点

| Controller | 端点数 | 调用次数 | 建议命令 |
|---|---|---|---|
| customerAddress | 7 | 0 | /add-tests basic customerAddress |
| customerContact | 7 | 0 | /add-tests basic customerContact |
...
```

## AI 执行流程

1. 解析参数（scope = 项目/模块/全部）
2. 扫描源码：
   - `find ... -name "*Controller.java"` 列所有 controller
   - `grep -E "@(Get|Post|Put|Delete)Mapping"` 数端点数
3. **扫描测试（v2 算法，识别统一测试循环）**：
   ```bash
   # A. 识别"覆盖声明"——统一测试文件（ENDPOINTS/PAGES 数组里的模块路径）
   #    例如 finance.test.js:  `{ mod: 'payable', base: '/mes/finance/payable' }`
   #    例如 finance.spec.ts: `{ name: '应付账款', path: '/project/mes/finance/payable' }`
   covered_in_array=$(grep -rE "(base|path).*['\"]?<module>['\"]?" harness/tests/ harness/e2e/mes/ | wc -l)

   # B. 数"实际调用次数"——controller 每个端点路径在测试中被调用的次数
   #    提取 controller 的所有端点路径（如 /list, /queryById, /add, ...）
   for ep in $(grep -oE "@(PostMapping|GetMapping|PutMapping|DeleteMapping).*[\"']/[\w/]+[\"']" Controller.java | grep -oE "/[\w/]+" | sort -u); do
     calls=$(grep -rE "$ep" harness/tests/ harness/e2e/mes/ | wc -l)
   done

   # C. 覆盖判定（取并集）：
   #    covered_in_array >= 1  → 视为"统一测试循环覆盖"（如 finance.test.js）
   #    所有端点 calls >= 1    → 视为"独立测试覆盖"
   #    否则 → 真缺口
   ```

   **判定规则**：
   - `covered_in_array >= 1` → 标注"统一测试覆盖"，**不视为缺口**
   - 否则若 `任一端点 calls == 0` → 标注"缺口"
   - 否则 → 标注"完整覆盖"
4. 输出覆盖率表 + 缺口清单 + 推荐 `/add-tests` 命令

> **为什么这样改**：v1 算法（`grep -c "/mes/<module>"`）只数**路径字符串出现次数**，会把统一测试文件里 ENDPOINTS 数组的 1 行声明误判为"低覆盖"。v2 算法区分"覆盖声明 vs 实际调用 vs 误判"，对 finance.test.js 这样的循环测试给正确判定。

## 关联命令

- `/add-tests` — 补齐缺口
- `/test-all` — 跑全量测试
---
name: chain-test
description: 跨模块链路贯通验证 — 基于 business-chains.json 用 Orca browser + curl 逐段验证，/chain-test 命令的领域知识
version: 1.0.0
---

# chain-test — 跨模块链路验证

## 链路来源

`hermes/business-chains.json` 中的 `chains` 对象。每条链路包含：

```json
{
  "id": "purchase-chain",
  "flow": ["申请", "审核", "生成订单", "审核订单", "收货入库", "审核入库", "库存更新", "应付生成"],
  "modules": ["purchase/apply", "purchase/order", "purchase/receipt", "purchase/ledger"],
  "chainTests": {
    "enabled": true,
    "segments": [
      {
        "name": "申请→订单",
        "file": "harness/tests/mes/purchase-apply-order.chain.test.js",
        "covers": ["创建申请→审核→加载到订单→创建订单→审核→反审核"]
      },
      {
        "name": "订单→入库",
        "file": "harness/tests/mes/purchase-order-receipt.chain.test.js",
        "covers": ["创建订单→审核→入库→超量拦截→全部到货→库存台账"]
      }
    ]
  },
  "criticalPaths": [
    "POST /mes/purchase/receipt/add → 校验订单存在+状态+超量",
    "PUT /mes/purchase/receipt/audit → 原子扣减+库存更新+应付生成"
  ]
}
```

## 链路匹配

基于 git diff 自动匹配：

```bash
# 获取变更文件路径
CHANGED=$(git diff HEAD~1 --name-only)
PY_CMD=$(command -v python3 || command -v python || echo python)

# 与每条链路的 modules[] 做前缀匹配
for chain in $($PY_CMD -c "import json; [print(c['id']) for c in json.load(open('hermes/business-chains.json'))['chains'].values()]"); do
  echo "$CHANGED" | grep -q "$chain" && echo "HIT: $chain"
done
```

多条链路同时命中 → 串行执行，先采购再销售再生产。

## 验证执行

### 方式 1：有 chain test 文件

如果 segment 有 `file` 字段且文件存在，直接运行：

```bash
node <segment.file>
```

### 方式 2：无 chain test 文件 — Orca browser + curl

按 segment 的 `covers` 数组逐步骤执行。

以"申请→订单"为例：

```
步骤 1：browser 登录 → 导航到采购申请页 → 点击"新增"
步骤 2：browser 填写申请表（物料、数量、供应商）
步骤 3：browser 点击提交 → 获取申请 ID ← curl 校验
步骤 4：curl 审核申请 PUT /mes/purchase/apply/audit?id=<申请ID>
步骤 5：browser 导航到采购订单页 → 点击"从申请生成"
步骤 6：browser 选择申请 → 点击生成 → 校验订单已创建 ← curl 校验
步骤 7：curl 审核订单 PUT /mes/purchase/order/audit?id=<订单ID>
步骤 8：curl 反审核 PUT /mes/purchase/order/unaudit?id=<订单ID> ← 校验可回退
```

每步的验证脚本：

```bash
# curl 单步
PY_CMD=$(command -v python3 || command -v python || echo python)
RESP=$(curl -s -X PUT "http://localhost:8080/jeecg-boot/mes/purchase/apply/audit?id=$ID" \
  -H "X-Access-Token: $TOKEN")
echo "$RESP" | $PY_CMD -c "import sys,json; d=json.load(sys.stdin); print('PASS' if d.get('success') else 'FAIL: '+d.get('message','?'))"
```

### Orca browser 操作

```bash
# 1. 登录
orca goto --url http://localhost:3100
orca wait --timeout 3000
orca fill --element <用户名ref> --value "admin"
orca fill --element <密码ref> --value "123456"
orca click --element <登录按钮ref>
orca wait --timeout 3000

# 2. 导航到模块页面
orca goto --url http://localhost:3100/project/mes/<模块路径>
orca wait --timeout 3000
orca snapshot

# 3. 通过 snapshot 找到"新增"按钮 ref → 点击
orca click --element <新增按钮ref>
orca wait --timeout 2000

# 4. 填写表单字段（通过 snapshot 获取输入框 ref）
orca fill --element <字段ref> --value "<值>"

# 5. 提交
orca click --element <提交/保存按钮ref>
orca wait --timeout 3000
orca snapshot

# 6. 从页面文本提取生成的 ID
# 在 snapshot 输出中查找 "PA-XXXX" 等业务编码
```

### 验证点（每段）

| 验证类型 | 方法 | 通过标准 |
|---------|------|----------|
| 数据传递 | 步骤 N 产生的 ID 能作为步骤 N+1 的输入 | ID 存在且有效 |
| 状态流转 | 查询记录状态字段 | 状态值正确的序列 |
| 数量一致性 | 对比每一步的数量字段 | 一致无丢失 |
| 回滚能力 | 反审核 → 验证状态回退 | 返回原状态 |
| 权限隔离 | 无权限用户 curl → 验证 403 | 返回 403 |

## 汇总输出

```
📊 链路验证报告 — <链路名>

  链路流程：<flow 数组>

  分段结果：
  ├─ 🟢 申请→订单 — <N> 项验证全部通过（<耗时>）
  ├─ 🟢 订单→入库 — <N> 项验证全部通过（<耗时>）
  └─ 🟢 库存台账 — M 项验证通过（<耗时>）

  整体判定：🟢 全通

  关键路径验证：
  ├─ 🟢 POST /mes/purchase/receipt/add → 订单存在+状态+超量校验 ✓
  └─ 🟢 PUT /mes/purchase/receipt/audit → 库存更新+应付生成 ✓
```

🟡 或 🔴 时触发 human-gate。

## 降级

Orca 不可用 → 仅执行 curl 验证部分（browser 步骤跳过），输出"⚠️ Orca 不可用，仅完成 API 级链路验证"。

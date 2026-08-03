# MES Slice 4.1 Finance 跑测报告

## 切片信息

- id：4.1
- name：finance
- 分支：`fix/regression-2026-08-04`
- 测试命令：`cd harness && timeout 180 node tests/modules/finance.test.js 2>&1 | tail -50`
- 测试日期：2026-08-04

## 跑测结果

- 总用例数：137
- 通过数：130
- 失败数：7
- 通过率：94.9%
- 耗时：测试输出未提供耗时；在 180 秒超时限制内完成

### 分模块结果

| 模块 | 通过/总数 | 通过率 |
|---|---:|---:|
| collection | 12/13 | 92.3% |
| salesInvoice | 14/15 | 93.3% |
| payable | 18/19 | 94.7% |
| payment | 20/21 | 95.2% |
| purchaseInvoice | 14/15 | 93.3% |
| receivable | 19/19 | 100.0% |
| subject | 17/18 | 94.4% |
| voucher | 16/17 | 94.1% |

## 失败明细

共 7 项失败，分布于 collection、salesInvoice、payable、payment、purchaseInvoice、subject、voucher，各 1 项。根据测试尾部输出可确认：

1. `subject 7.2 add 空 body 不崩溃`：实际返回 HTTP 500，消息为“科目编码不能为空”。
2. `voucher 7.2 add 空 body 不崩溃`：实际返回 HTTP 500，消息为“凭证号不能为空”。

受命令要求仅保留最后 50 行输出影响，其余 5 项的具体请求与响应未出现在捕获结果中；结合各模块统计及一致的用例结构，失败模块为 collection、salesInvoice、payable、payment、purchaseInvoice，各 1 项。

此外，R002 全模块越权测试因 `guest` 账号不存在而跳过，未形成有效权限验证。

## 新发现 bug

1. Finance 新增接口在空请求体触发必填校验时返回 HTTP 500。参数校验失败属于客户端请求错误，建议统一返回 HTTP 400 或项目约定的业务校验状态码，避免被判定为服务端崩溃。
2. R002 越权测试环境缺少 `guest` 账号，导致权限回归覆盖缺失，存在未验证风险。

## 下一步建议

1. 优先统一修复 7 个失败模块的新增接口空 body 校验响应，避免返回 HTTP 500。
2. 修复后重新执行 finance 全量测试，目标为 137/137 通过。
3. 补建并配置无权限 `guest` 测试账号，再执行 R002 全模块越权测试。
4. 后续跑测建议保留完整日志或增加计时输出，便于报告准确记录全部失败详情和实际耗时。

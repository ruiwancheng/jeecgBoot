# [2026-07-21] [数据库] 软删唯一索引 (code, del_flag) 的二次删除冲突

## 触发条件
表用 `UNIQUE INDEX (rule_code, del_flag)` 支持"软删后同名重建"。

## 现象
同一编码「删除 → 重建 → 再删除」时，第二次删除报错：
`Duplicate entry 'TST-1' for key 'uk_code_rule_code'`
（已存在一条 del_flag=1 的历史行，新行再 UPDATE del_flag=1 撞唯一索引）

## 正确处理
- 自动化测试每次用独立编码（如 `T + 时间戳`），不依赖固定码
- 业务上该场景罕见，记录即可
- 彻底解法：删除时把 del_flag 写成记录 id（每行 del_flag 唯一），JeecgBoot 部分标品表用此模式

## 诊断方法
删除接口报 `Duplicate entry 'XX-1'` 且表有 (code, del_flag) 唯一索引 → 是历史软删行残留，不是并发问题。

**关联：** hermes/tiequan/2026-07-21/codeRule（修复验证中顺带发现）

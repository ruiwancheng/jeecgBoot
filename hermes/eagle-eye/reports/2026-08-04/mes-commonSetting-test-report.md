# MES CommonSetting 模块回归测试报告

**日期**：2026-08-04
**模块**：commonSetting（通用设置）
**测试类型**：E2E

## 一、测试概况

| 指标 | 数值 |
|---|---:|
| E2E 测试用例 | 1 |
| 通过 | 0 |
| 失败 | 1 |

## 二、🔴 P2 — commonSetting.spec.ts 失败

```
Error: 切片B：通用设置页面端到端验证
```

**症状**：通用设置页面整页不可达。

**可能根因**：
- 路由守卫拦截（mes_admin 权限不足？）
- 菜单权限缺失
- 组件加载失败（前端 TS 错误？）
- token 注入失败

## 三、明早优先排查

1. **🟡 P2**: 看截图 + 检查路由/菜单权限
2. **核对**：前端 TS 错误是否导致 commonSetting 组件无法渲染

## 四、原始日志

`hermes/eagle-eye/state/e2e-20260804.log`（grep commonSetting）
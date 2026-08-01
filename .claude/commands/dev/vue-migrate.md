---
description: 自有命令 — Vue 黄金模板改造：检测偏离项 + 生成 diff 让人工 review，半自动模式
---

# /vue-migrate <文件> [--apply]

按黄金模板 UX 基线**检测偏离项 + 生成改造 diff**，人工 review 后应用。

## 用法

```
/vue-migrate jeecgboot-vue3/src/views/mes/receipt/index.vue
/vue-migrate jeecgboot-vue3/src/views/mes/receipt/index.vue --apply     # 直接应用（风险高）
/vue-migrate --all-list                                                  # 列出全部不合规文件
```

## 流程

### 1. 加载 vue-audit 脚本

使用 `vue-audit.sh` 获取基线检查结果。

### 2. 检测偏离项

跑 vue-audit.sh，提取 WARN/FAIL 项：

| 偏离项 | 自动修复策略 | 风险等级 |
|---|---|---|
| 缺 `@generated-from` 标注 | 自动追加 | 低 |
| 缺 `_dictText` 后缀 | 自动追加（按规则改） | 中 |
| 缺 `confirmLoading` | 自动追加防重复模板 | 中 |
| 缺 `popConfirm` | 自动包 popConfirm 组件 | 中 |
| 缺 `onMaterialChange` 预填 | 自动加默认值 | 高（需业务确认） |
| 缺 `JMaterialSelect` | 不自动改（提示人工选） | 高 |
| 缺 `MaterialSelectModal` | 不自动改（提示人工选） | 高 |
| 缺红标样式 | 不自动改 | 低 |

### 3. 输出改造方案

```
文件：receipt/index.vue
当前状态：PASS 3 / WARN 9 / FAIL 1
   ├─ ⚠ 缺 @generated-from → [自动] 在文件首追加注释
   ├─ ⚠ 缺 rowSelection → [人工] 业务是否需要批量操作？
   ├─ ⚠ 缺 popConfirm → [自动] 包 popConfirm 组件
   ├─ ✗ 缺 confirmLoading → [自动] 加 setDrawerProps({confirmLoading: true})
   └─ ⚠ 缺 _dictText → [半自动] grep 出 materialId 等字段，提示改法

生成 diff（人 review 后应用）：
  + // @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
  + import { Popconfirm } from 'ant-design-vue';
  + setDrawerProps({ confirmLoading: true });
  ...
```

### 4. 人工 review

显示 diff，要求用户确认：

- 输入 `y` → 应用修改（备份原文件到 `<file>.bak`）
- 输入 `n` → 取消
- 输入 `edit` → 进入交互式编辑

### 5. 改造后重审

跑一次 vue-audit.sh，确认改进效果：

```
改造前：PASS 3 / WARN 9 / FAIL 1
改造后：PASS 8 / WARN 4 / FAIL 0   ← 合规率提升
```

## 安全约束

1. **默认不应用**——只生成 diff，必须人工确认
2. **`--apply` 才改文件**——改前备份 `.bak`
3. **自动项限制在 4 类**（标注/confirmLoading/popConfirm/_dictText）——其他项只给建议
4. **高风险项不自动改**（onMaterialChange / JMaterialSelect / MaterialSelectModal）——必须人工判断

## 示例

```
用户：/vue-migrate jeecgboot-vue3/src/views/project/mes/receipt/index.vue
AI  ：
  1. 跑 vue-audit.sh：PASS 3 / WARN 9 / FAIL 1
  2. 检测 4 项可自动改造：
     ├─ 缺 @generated-from（自动追加）
     ├─ 缺 confirmLoading（自动追加）
     ├─ 缺 popConfirm（自动追加）
     └─ 缺 _dictText（半自动）
  3. 生成 diff 预览：
     + // @generated-from: harness/templates/mes-doc-page/master-detail
     + import { Popconfirm } from 'ant-design-vue';
     + setDrawerProps({ confirmLoading: true });
     ...
  4. 询问：应用？(y/n/edit)
```

## 与 /vue-audit 的关系

- `/vue-audit` = 只检测，输出报告
- `/vue-migrate` = 检测 + 生成 diff + 人工 review 后应用
- 日常：`/vue-audit --all` 找问题 → `/vue-migrate <file>` 改单个文件
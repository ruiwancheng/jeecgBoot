# Vue 模板属性值禁用半角引号（" ' <）

**场景**：在 Vue template 属性里写带半角引号的中文文案，例：
```html
<a-alert message="点击"查看追溯"按钮..." />
```

**根因**：Vue 模板属性解析器不允许属性值里出现 `"` `'` `<`（Vite 编译错误）：
```
[plugin:vite:vue] Attribute name cannot contain U+0022 ("), U+0027 ('), and U+003C (<).
```

**触发场景**：
- 黄金模板对齐时写 Alert 文案（含按钮名、操作名）
- 业务文案习惯用半角引号（英文"按钮"、'提示'）但 Vue 解析失败
- /verify 截 Playwright 截图时发现整个页面卡在 Vite loading，说明编译失败

**正确处理**：

```html
<!-- 用中文方括号或全角引号替代 -->
<a-alert message="点击「查看追溯」按钮..." />
<a-alert message="点击【查看追溯】按钮..." />
<a-alert message="点击&ldquo;查看追溯&rdquo;按钮..." />
```

**或**用 ref + script 设置（更稳妥）：
```vue
<a-alert :message="alertMsg" />

<script setup>
const alertMsg = '点击「查看追溯」按钮...'
</script>
```

**判断信号**：
- 改完 .vue 文件后 Playwright 截图卡在 "JeecgBoot 企业级低代码平台" 加载页（Vite 编译错误）
- Vite 日志报 "Attribute name cannot contain U+0022"
- `/verify` 跑前端 UI 截图，页面永远 loading

**实证**：2026-07-31 批次管理 traceability 模块 Playwright 截图卡死，Vite 日志暴露半角引号编译错误。修复为「」后编译通过。

**避免**：黄金模板 Alert 文案阶段必须用中文引号（『』「」【】）替代半角引号。`/verify` 阶段如发现截图卡 loading，先 `cat /tmp/jeecg-local-frontend.log | grep ERROR` 排查编译错误。
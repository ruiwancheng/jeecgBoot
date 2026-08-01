# Vue SFC parser 误导性行号——精确二分定位真因

**触发条件：** Vite/Vue build 报 `Attribute name cannot contain U+0022 ("), U+0027 ('), and U+003C (<).` 或类似"行号 XX 列 YY"错误，且错误指向的位置看起来没问题（如 `<script lang="ts" setup>` 标签）。

**处理方式：**
1. **不信任报错行号**：用 `@vue/compiler-sfc` 的 `parse()` 单独解析文件，拿到精确 errors 数组
2. **二分定位**：从最小 hello world 模板开始，每次加回一半内容，看错误位置/数量变化
3. **找字节级差异**：`od -c` 或 `cat -A` 看特殊字符；`xxd` 看不可见字符（CR/LF/单引号/反引号）
4. **重点查 `<script>` 标签属性**：HTML 解析器对 `<script lang="ts" setup>` 这种属性顺序敏感——`<script lang="ts" setup">`（setup 后多一个引号）会被解析为 `setup"` 属性名 + 缺值，导致状态错乱
5. **用 `python -c "ord(...)"` 看具体字符的码点**：避免字符显示歧义

**实证：** 2026-08-02 完工入库页面 `index.vue` 报 "Attribute name cannot contain..." @ line 22 col 24——但 line 22 是 `<script lang="ts" setup>` 看似正常。实际错误是 `<script lang="ts" setup">` 中 `setup` 后多了一个 `"` 字符（0x22），Vue SFC parser 误判 `setup"` 为属性名 + 缺值，状态机错位。修复 1 字符（删 `"`）后 build 通过。误导性行号 4 小时排查，靠 `@vue/compiler-sfc parse()` + `python ord()` 找到真因。

**配套检查：** commit 前用 `cat -A` 看关键行有无不可见字符；服务端报 Vue 错时先 `git diff` 看是不是新加/改了特殊字符。

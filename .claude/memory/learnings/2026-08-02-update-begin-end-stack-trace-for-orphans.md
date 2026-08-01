# 定位历史代码 `update-begin/end` 不对账——栈模拟找孤儿 begin

**触发条件：** 任何 commit 改了 .java 文件，CLAUDE.md 强约束要求 update-begin/end 对账，但 `grep -c "update-begin"` ≠ `grep -c "update-end"`——说明有未闭合的 begin 或多余的 end。

**处理方式：**
1. **不要手动数**：嵌套 if/else / try-catch / 多层 update 块容易数错。用 `python + 正则 + 栈模拟` 自动找
2. **栈模拟脚本**：
   ```python
   import re
   with open(file, 'r', encoding='utf-8') as f:
       lines = f.read().split('\n')
   stack = []
   for i, line in enumerate(lines, 1):
       for m in re.finditer(r'update-begin', line):
           stack.append(i)
       for m in re.finditer(r'update-end', line):
           if stack:
               stack.pop(0)
           else:
               print(f'L{i}: 多余 update-end')
   if stack:
       print(f'未闭合 begin: {stack}')
   ```
3. **找出来后看上下文**：用 `sed -n 'X,Yp' file.java` 看未闭合 begin 周围 5-10 行
4. **常见历史 bug 模式**：
   - 复制粘贴遗留：同一 end 注释出现 2 次
   - 改老代码时只加 begin 没加 end（反之亦然）
   - update-begin 跨方法边界时容易漏 end

**实证：** 2026-08-02 提交 V10.0.0 全连锁修改时对账发现 `MesSalesOutboundServiceImpl.java` begin=23 / end=22。栈模拟定位 L336 是 L334 的复制（`P0-02/03/10来源+数量校验` end 出现 2 次），L240 begin 只配对 L334 end。删 L336 重复行后 22/22 对账通过。1 行修复解决历史遗留 4 年的不对账 bug。

**配套：** 任何 commit 改 .java 后必须跑对账脚本；CI 流水线可加 `python check_update_pairs.py *.java` 钩子阻断对账失败。

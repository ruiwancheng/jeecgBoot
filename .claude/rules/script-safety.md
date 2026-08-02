# 脚本安全规则

> 防止批量脚本破坏仓库（2026-08-02 P0 清理灾难教训）

## 适用范围

任何会修改 **≥50 个文件** 的脚本必须遵守本规则：
- 删除未使用变量/import
- 批量重命名
- 批量格式化
- 自动修复 lint 错误
- 任何 sed/Python 跨文件批量改

## 强制流程

### 1. 试运行

```bash
# 任何脚本必须有 --test 模式
python fix-script.py --test    # 只统计修改数，不写文件
python fix-script.py --test --file=path/to/test.ts  # 单文件测试
```

### 2. 小批

```bash
# 限制单次执行数量
grep "error TS" log | head -100  # 一次只处理 100 个
# 而不是：grep "error TS" log | wc -l  # 看总数但跑全部
```

### 3. 每批验证

```bash
# 跑完一批立即验证错误数趋势
npx vue-tsc --noEmit 2>&1 | grep -c "error TS"
# 预期：错误数下降（如 1000 → 800 → 600）
# 异常：错误数上升（如 1000 → 1100）→ 立即停止
```

### 4. 保留回退点

```bash
# 每次 commit 后记录 hash
git log --oneline -1  # 复制 hash
# 重要：每个脚本批次 commit 一次（不要合并多个批次）
```

### 5. 错误数上升立即回退

```bash
git reset --hard <last-known-good-commit>
# 或更安全：git revert <bad-commit>
```

## 常见破坏模式

| 模式 | 后果 | 预防 |
|------|------|------|
| 删除 name 但留下 `: value` | 语法错误 `1: false` | 模式必须包含冒号后值 |
| 多行类型签名（`function foo(a: A, b: B)`）| 破坏签名 | 跳过含 `:` 的行 |
| 链式 `.` 访问（`a.b.c`）| 删 `c` 留下 `a.b.` | 必须看上下文 |
| 解构（`const { a, b } = ...`）| 删 `b` 留下 `, }` | 整行处理 |
| 函数声明（`function f() {}`）| 删函数名留下 `function () {}` | 跳过 function 行 |

## 反面案例

**本会话 P0 清理灾难**（2026-08-02）：
- 脚本 `fix-ts6133.py` 一次性跑 1025 个 TS6133
- 没有 `--test`、没有分批、没有立即验证
- 错误数从 1 → 1810（破坏 297 个文件）
- 浪费时间：约 2 小时
- 修复：回退 + 写本规则

**教训**：脚本能力越强，破坏力越大。先试运行再批量。

## 检查清单

执行批量脚本前：
- [ ] 有 `--test` 参数
- [ ] 限制单次 ≤100 个
- [ ] 跑完跑 `vue-tsc` 验证
- [ ] 错误数下降才继续
- [ ] git commit 每批一次
- [ ] 记录 commit hash 以便回退
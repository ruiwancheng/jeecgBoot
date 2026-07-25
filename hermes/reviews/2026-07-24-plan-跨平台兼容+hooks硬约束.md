# Claude 外部评审 — 跨平台兼容 + hooks 硬约束方案

## 评审结论

**通过。方向正确，有一个遗漏和一个隐患需补。**

---

## 背景

其他客户端试用 Harness 工程后反馈：基础工作流 / orca-review / delegate 命令始终未触发，AI 行为无法管控。

## 根因（三层断层）

| 层 | 问题 | 现象 |
|:--:|------|------|
| 1 | CLAUDE.md 是软约束 | AI 读了但不跟，今天20个提交0次delegate |
| 2 | delegate/orca-review 依赖 Orca | Orca 不可用时全部降级，降级=不做 |
| 3 | .claude/ 是 Claude Code 专属 | 其他 AI (Cursor/pi/Copilot) 不加载 |

---

## 已落地改动

### Round 1: 跨平台兼容（4 hooks）

```
问题: python3 硬编码 → Windows 用 python → hooks 全部失效
修复: PYTHON=$(command -v python3 || command -v python || echo python)
      全部 python3 -c → $PYTHON -c

问题: post-tool-failure.sh:24 appRunning 旧格式
修复: d.get('appRunning') → d.get('result',{}).get('app',{}).get('running')
```

### Round 2: 硬约束下沉到 hooks（2 hooks）

```
pre-plan-check.sh (Skill=plan 时触发)
  + 检测未提交 Java/Vue/TS/SQL 文件
  + 显示 DELEGATE 强制判定横幅
  + 列出文件清单 + 提醒走 /delegate

pre-commit-check.sh (git commit 时触发)
  + 检测暂存 Java/Vue/TS + 8080 在线
  + 检查 .last-verify 时间戳
  + 无证据 → 阻断横幅（可用 --no-verify 跳过）
```

---

## ✅ 思路对齐

- 从"文本规则"到"hook 弹窗"的策略转换正确——hook 是 AI 无法跳过的最低层防线
- python3 兼容方案简洁（command -v 回退链），没有引入复杂依赖
- pre-commit 阻断是非阻塞的（--no-verify 可跳过），避免阻碍紧急 hotfix

## ⚠️ 遗漏或风险

### 1. .last-verify 机制有鸡生蛋问题
- 当前没有任何东西自动写 `.last-verify`
- AI 需要手动 `touch .last-verify` 或 `/verify` 命令更新它
- **建议：** 在 `verify/SKILL.md` 中加一步：验证通过后自动 `date > .last-verify`

### 2. pre-plan-check 只在 plan 技能触发时运行
- 但很多时候 AI 跳过 /plan 直接编码（今天就是这样）
- settings.json 中 PreToolUse(Skill) 匹配 plan 技能，但如果 AI 不调 plan 就永远不会触发
- **建议：** 考虑加一个 PreToolUse(Edit|Write) 的轻量检查——检测到即将编辑代码文件时提醒 delegate

### 3. delegate 横幅是"提醒"不是"阻断"
- 横幅显示后 AI 可以无视继续写代码
- 但考虑到 delegate 需要 Orca 可用，强行阻断会让 Orca 不可用时的开发完全卡死
- **当前设计合理**——提醒但不阻断，留给 AI 判断空间

## 💡 优化建议

### 建议 1: verify/SKILL.md 补 .last-verify 写入
```markdown
### /verify 完成的最后一步
验证全部通过后，记录证据：
```bash
date '+%Y-%m-%d %H:%M:%S' > .last-verify
```
```

### 建议 2: pre-commit 降级文案优化
当前横幅说"touch .last-verify"——对不熟悉命令行的用户不友好。
建议改为："如已实测验证：运行 /verify 自动记录"。

---

*评审人：Claude（降级手工评审）*
*日期：2026-07-24*

---
name: list-projects
description: 列出所有KA客户项目并显示当前活跃项目 — List all KA customer projects and show the current active project
version: 1.0.0
---

# 列出项目 (List Projects)

## 项目目录结构

所有 KA 客户项目位于 `jeecg-boot/jeecg-boot-module/` 目录下，目录名格式为：

```
jeecg-boot/jeecg-boot-module/project-<项目名>
```

**示例：**
```
jeecg-boot/jeecg-boot-module/project-haier/
jeecg-boot/jeecg-boot-module/project-cmhk/
jeecg-boot/jeecg-boot-module/project-template/
```

## 项目识别

通过目录名识别客户项目：

```bash
ls jeecg-boot/jeecg-boot-module/ | grep '^project-' | sed 's/project-//'
```

**输出示例：**
```
haier
cmhk
template
```

## 活跃项目

当前活跃项目记录在 `.claude/memory/active-project.md`，内容格式：

```markdown
# 当前项目：<项目名>
```

**读取活跃项目：**
```bash
cat .claude/memory/active-project.md | grep '^# 当前项目' | sed 's/^# 当前项目：//'
```

## 切换项目

修改 `.claude/memory/active-project.md` 中的项目名：

```markdown
# 当前项目：cmhk
```

切换后，所有后续操作（代码生成、测试、验证）自动作用于新的活跃项目。

## 项目信息

列出项目时，输出格式：

```
活跃项目：haier

所有项目：
  haier    — jeecg-boot/jeecg-boot-module/project-haier/
  cmhk     — jeecg-boot/jeecg-boot-module/project-cmhk/
  template — jeecg-boot/jeecg-boot-module/project-template/
```

如果活跃项目不存在于已识别列表中，提示用户检查 `.claude/memory/active-project.md` 是否正确。

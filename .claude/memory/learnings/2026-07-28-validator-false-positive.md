# [2026-07-28] [测试] 验证器假阳性——验证命令本身必须真实断言

## 触发条件
写完修复后跑验证，用 `grep ... | python -c "..."` 校验输出。

## 现象
验证命令 `grep -o '{...' file | python -c "import sys,json; print('JSON OK')" || echo "(无JSON)"` 打印了 "JSON OK"，但 stdout 里其实**根本没有 JSON**——python 脚本没读 stdin，是无条件 print，永远通过。差点把"阻断路径不该有 JSON"误报成"JSON 发射成功"。

## 根因
验证脚本写成了"仪式"而非"断言"：pipeline 的退出码链（grep→python→||）看似严谨，但中间环节的 python 不做真实校验时，整条链恒真。

## 正确处理
1. 验证命令必须**消费输入并断言**：`python -c "import sys,json; d=json.load(sys.stdin); print(d['key'])"`——空输入会异常退出，`||` 兜底才会触发
2. 存疑时**直接 cat 原始输出**看肉眼事实（本次就是 cat 后发现 3 行无 JSON）
3. 修复类验证至少覆盖两个分支：该成功的路径 + 该失败的路径（本次 exit 2 阻断 + exit 0 提醒各测一次）
4. 教训同源：`set -e` 重试陷阱（2026-07-09）——脚本控制流的每个环节都要问"失败时它真的会失败吗"

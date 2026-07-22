# [2026-07-22] [delegate] 工人verify阶段卡死的根因与修复

## 触发条件
/delegate 派发的工人在 /verify 阶段执行 mvn compile + curl 实测时陷入死循环，永远不发 worker_done。

## 根因
1. mvn clean 杀掉正在运行的后端 → curl 必然失败
2. curl 失败后工人不知道怎么办 → 尝试重启后端 → 继续失败 → 无限自旋
3. worker_done 依赖 verify 成功 → verify 失败就永远不发 → 协调者不知道工人状态

## 修复（delegate.md preamble）
```
5. /verify: mvn compile + curl
   - 🚫 禁止 mvn clean，用 mvn compile
   - curl失败 → 重试1次(mvn compile, 等5秒) → 还不行 → 发 worker_done(verify_failed)
6. 无论如何必须发送 worker_done
   - 成功: worker_done + completed
   - verify失败但代码已改: worker_done + verify_failed + 说明
```

## 新增消息阶段
- verifying heartbeat → 让协调者知道工人在做verify
- worker_done 两种状态: completed / verify_failed

## 关联
- 2026-07-22-delegate-worker-no-mvn-clean.md (mvn clean具体问题)
- delegate.md preamble 步骤5-6
- ✅ 已覆盖: delegate.md preamble 模板

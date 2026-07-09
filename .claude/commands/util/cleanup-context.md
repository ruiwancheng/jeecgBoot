# /cleanup-context

长会话上下文清理。token 接近窗口上限时使用。

## 流程
1. 输出当前会话摘要
2. 清理过期 memory 引用
3. 提示是否需要紧凑上下文

---
name: backend-first
description: 业务逻辑放后端 Service 层，Controller 精简，前端不做数据验证
glob: "**/*.java,**/*.vue,**/*.ts"
version: 1.0
---

# 后端优先原则

- 数据验证、状态转换、计算逻辑、默认值——全部在 Service 中实现
- Controller 只做参数接收和调用 Service
- 前端仅做 UI 展示和格式校验（必填、长度），不做业务判断
- 扩展字段用项目专属扩展表，不修改标品表结构

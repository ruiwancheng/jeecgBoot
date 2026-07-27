# [2026-07-22] [delegate] 工人端 /verify 禁止 mvn clean——会杀掉正在运行的后端

## 触发条件
/delegate 派发的工人在 /verify 阶段执行 `mvn clean compile`。

## 现象
`mvn clean` 清空 `target/` 目录导致正在运行的 Spring Boot 后端进程死掉，后续 `curl localhost:8080` 必然失败。工人陷入"后端起不来→curl不过→尝试重启"的死循环，终端卡住。

## 根因
`mvn clean` 删除 target/ 后，devtools 热加载失效，正在运行的 JVM 进程虽然没被杀但类文件丢失，新请求会报 ClassNotFoundException 或连接拒绝。

## 正确做法
- 本地后端已在跑时，用 `mvn compile`（不加 clean），devtools 会自动热加载新类
- 如果必须重新编译所有模块，用 `mvn compile -pl jeecg-boot-module/project-mes -am`
- 后端确认没在跑时，才能用 `mvn clean compile`

## 工人 preamble 应加入的禁止模式
```
🚫 /verify 阶段禁止 mvn clean——用 mvn compile
🚫 禁止手动杀后端进程或重启
✅ curl 前先确认 8080 端口在侦听：curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/jeecg-boot/sys/getEncryptedString
```

**关联：** /delegate 流程、workflow.md /verify 铁律
- ✅ 已覆盖: delegate.md preamble 模板

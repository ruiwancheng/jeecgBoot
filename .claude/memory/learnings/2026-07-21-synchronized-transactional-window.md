# [2026-07-21] [并发] synchronized + @Transactional 存在提交窗口期，发号必用行锁

## 触发条件
给"取号/发号/计数器"类单条记录并发更新加锁时，在 `@Transactional` 方法上叠加 `synchronized`。

## 现象
两个用户同时开单拿到同一个单号；业务表唯一约束兜底报"编码已存在"。

## 根因
Spring 事务代理在 synchronized 方法**外层**：锁在方法退出时释放，但事务在代理层才提交。
线程 B 可在"A 释放锁"与"A 提交"之间进入方法，读到未提交的旧值。
且 synchronized 是 JVM 级，集群部署完全失效。

## 正确处理
```java
@Transactional(rollbackFor = Exception.class)
public String nextCode(String ruleCode) {
    // FOR UPDATE 行锁随事务提交才释放，无窗口期，集群有效
    MesCodeRule rule = getOne(new LambdaQueryWrapper<MesCodeRule>()
        .eq(MesCodeRule::getRuleCode, ruleCode).last("FOR UPDATE"));
    ...
}
```
或原子累加 `UPDATE ... SET seq = seq + 1 WHERE ...` 后回查。

## 检查清单
代码评审时见到 `synchronized` 与 `@Transactional` 同方法共存 → 必提 P1。

**关联：** hermes/tiequan/2026-07-21/codeRule（铁拳团 P1-A）

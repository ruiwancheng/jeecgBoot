# Slice 5.2 — stocktake 跑测报告

- **报告路径**：`hermes/eagle-eye/reports/2026-08-04/slice-5.2-stocktake.md`
- **生成时间**：2026-08-04（Asia/Shanghai）
- **测试文件**：`harness/tests/modules/stocktake.test.js`
- **分支**：`fix/regression-2026-08-04`
- **结论**：❌ 测试在登录阶段被环境问题阻断，本地后端 `localhost:8080` 不可达；盘点单全链路 25+ 项业务断言均未执行

---

## 切片信息

| 字段 | 值 |
|---|---|
| id | 5.2 |
| name | stocktake |
| type | module-api |
| 测试范围 | 盘点单（快照 → 实盘 → 审核 → 自动生成调整单 → 库存校准）全链路 7 个场景 |
| 计划业务断言 | 25+（场景1全盘快照、场景2盘亏、场景3盘盈、场景3b金额对账+编辑拦截、场景4守卫、场景5抽盘book校验、场景6刷新保留、场景7批量审核单事务） |
| BASE 地址 | `http://localhost:8080/jeecg-boot`（脚本 `stocktake.test.js:5` 默认值，与任务环境一致，**无地址硬编码问题**） |
| 业务链路 | 涉及 `mes/stock/stocktake`、`mes/stock/otherIn`、`mes/stock/otherOut`、`mes/basic/warehouse`、`mes/basic/material`、`mes/warehouse/inventory` |

## 跑测结果

执行命令（原样）：

```bash
cd harness && timeout 180 node tests/modules/stocktake.test.js 2>&1 | tail -50
```

原始输出（`tail -50`）：

```text
===== MES 盘点单 API 测试 =====

[TypeError: fetch failed] {
  [cause]: AggregateError [ECONNREFUSED]: 
      at internalConnectMultiple (node:net:1142:49)
      at afterConnectMultiple (node:net:1723:7) {
    code: 'ECONNREFUSED',
    [errors]: [ [Error], [Error] ]
  }
}
```

| 指标 | 结果 |
|---|---:|
| 套件通过数 | 0 |
| 套件失败数 | 1（登录阶段异常，环境阻断） |
| 套件通过率 | 0%（N/A，业务断言未执行） |
| 实际耗时 | <1s（墙钟取整为 0s；Node.js 进程在 `login()` 内首次 `fetch` 时即抛出 `ECONNREFUSED`） |
| 业务断言执行数 | 0 / 25+ |
| 进程退出码 | 1（Node.js 抛出未捕获异常） |

> 说明：本次失败发生在 `login()` 的网络请求阶段，**先于**任何业务断言。因此“0/1、0%”是**套件级结果**，不是把登录异常伪计为业务断言失败；盘点单全链路 25+ 项业务断言均未执行，无法评价盘点模块功能是否通过。

## 失败明细

| # | 阶段 | 预期 | 实际 | 影响 |
|---|---|---|---|---|
| 1 | 登录 `POST /sys/login` | 登录成功后执行 25+ 项盘点业务断言 | Node.js 抛 `[TypeError: fetch failed] [cause]: AggregateError [ECONNREFUSED]`，进程退出码 1 | 场景1~场景7 全部未测，含 5 个评审补强的盲区校验（金额对账 / 已审编辑拦截 / 抽盘 book 篡改拦截 / refreshItems 保留 / 批量审核单事务） |

### 只读核验证据

1. 当前进程未设置 `HARNESS_BASE` 环境变量。
2. `stocktake.test.js:5` 的默认 BASE 是 `http://localhost:8080/jeecg-boot`，**与任务环境声明的本地后端地址一致**；地址硬编码类配置缺陷**不存在**。
3. 任务声明的本地后端 `localhost:8080` **不可达**：
   - `curl -sS -X POST -H "Content-Type: application/json" -d '{"username":"mes_admin","password":"123456"}' http://localhost:8080/jeecg-boot/sys/login` 直接退出，HTTP `000` + exit code 7（连接拒绝），无任何返回内容。
   - `curl http://localhost:8080/jeecg-boot/sys/login` 简单探测同样 `HTTP 000`，约 2.27s 后失败。
   - `netstat -ano | grep ":8080"` 无任何 LISTENING 条目；当前活跃 Java 进程只有 Maven `compile -DskipTests`（PID 11616），并未启动 Spring Boot。
4. 数据库端口 `13306`（开发 MySQL）同样未监听（`netstat` 无对应条目），意味着即使恢复后端，盘点测试所需的 `mes_admin` 账号及基础数据链路也可能受影响（与 Slice 5.1 报告的环境基线需交叉确认）。
5. 测试在 `login()` 的 `fetch('http://localhost:8080/jeecg-boot/sys/login')` 调用即抛出 `ECONNREFUSED`，没有创建任何业务数据（仓库、原料、期初入库单、盘点单均未生成） → **本轮无需清理残留测试数据**。
6. 异常链路完整：`TypeError: fetch failed` → `cause: AggregateError [ECONNREFUSED]` → `code: 'ECONNREFUSED'`，与 Node.js `net:1142` `internalConnectMultiple` 一致，可确认是 TCP 层 RST 而非应用层 4xx/5xx。

## 新发现 Bug

无（本切片在登录阶段即终止，**未触及任何业务接口**，不触发新的代码缺陷假设）。

唯一的环境侧问题已记录在下文：

- **P1（环境类）** `BUG-STOCKTAKE-HARNESS-ENV-LOST`：本次切片执行时本地后端 `localhost:8080` 不可达（无 Java 进程监听、无 Maven `spring-boot:run`），与任务前置条件“后端运行中”不符，导致回归覆盖被环境阻断。该问题已在 Slice 3.1（manufacturing）首次出现，后续切片均依赖该环境前置；当前属于**再次复发**，需在下一轮回归前置环节系统性解决（启动后端 + 等待端口 ready + 守护进程）。

> 备注：`stocktake.test.js` 自身的地址配置正确（`localhost:8080/jeecg-boot`），不存在 Slice 3.1 的 `BUG-MANUFACTURING-HARNESS-BASE-MISMATCH` 类型问题。

## 下一步建议

1. **P1 恢复后端 + 守护**：
   - 执行 `./start-local-backend.sh`（或 `cd jeecg-boot/jeecg-module-system/jeecg-system-start && mvn spring-boot:run -Dspring-boot.run.profiles=dev -Dspring.flyway.enabled=false`）。
   - 等待 `curl http://localhost:8080/jeecg-boot/sys/login` 返回有效 HTTP 响应（不再 `HTTP 000`）后再跑测。
   - 建议把后端启动 + 健康检查纳入回归前置脚本，避免后续切片再次因环境丢失而全量失败。
2. **确认数据库与种子数据**：
   - 确认 Docker MySQL `13306` 端口在线、`mes_admin` 账号可用、盘点单相关菜单权限码注册到位（`stocktake:add / edit / audit / delete / refreshItems / batchAudit`）。
   - 若 `13306` 仍离线，先按 `start-docker-compose.sh`（或 `start-docker-compose.bat`）拉起。
3. **环境恢复后重跑 Slice 5.2**：
   - 同一命令 `cd harness && timeout 180 node tests/modules/stocktake.test.js 2>&1 | tail -50`。
   - 以脚本尾部“`===== 结果: N 通过, M 失败 =====`”作为盘点模块通过率（目标 25+/0）。
4. **保留完整日志**：本次报告受 `tail -50` 限制，盘点测试本身输出较多（前缀标题、期中库存快照、4 个临时盘点单打印），后续切片建议改为 `tee logs/slice-5.2-stocktake.full.log`，便于归档失败场景的完整堆栈。
5. **关联检查**：与 Slice 3.1、3.2、4.1、4.2 一并核对：本地后端在多切片轮询过程中是否会因 Maven 编译或资源回收被误杀；若是，建议把 Spring Boot 进程托管到独立终端或后台守护。

---

**reportPath**：`hermes/eagle-eye/reports/2026-08-04/slice-5.2-stocktake.md`
**filesModified**：`hermes/eagle-eye/reports/2026-08-04/slice-5.2-stocktake.md`（仅验证报告；未修改业务代码、未新建任何代码文件）
**risk**：P1（盘点单全链路回归被本地后端环境丢失阻断；`stocktake.test.js` 自身配置正确，环境恢复后可直接重跑）
**phase**：completed（按任务指令完成跑测+报告；环境恢复超出本次切片范围，作为下一步 P1）
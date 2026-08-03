# Slice 3.1 — manufacturing 跑测报告

- **报告路径**：`hermes/eagle-eye/reports/2026-08-04/slice-3.1-manufacturing.md`
- **生成时间**：2026-08-04 02:57（Asia/Shanghai）
- **测试文件**：`harness/tests/modules/manufacturing.test.js`
- **分支**：`fix/regression-2026-08-04`
- **结论**：❌ 测试在登录阶段被环境/目标地址问题阻断，制造业务断言未开始执行

---

## 切片信息

| 字段 | 值 |
|---|---|
| id | 3.1 |
| name | manufacturing |
| type | module-api |
| 测试范围 | BOM 管理、生产订单、生产领料、完工入库、测试数据清理 |
| 计划业务断言 | 24 |

## 跑测结果

执行命令：

```bash
cd harness && timeout 180 node tests/modules/manufacturing.test.js 2>&1 | tail -50
```

原始输出：

```text
测试异常: fetch failed

__TEST_EXIT_CODE__=1
__WALL_SECONDS__=0
```

| 指标 | 结果 |
|---|---:|
| 套件通过数 | 0 |
| 套件失败数 | 1（登录阶段异常） |
| 套件通过率 | 0% |
| 实际耗时 | <1s（墙钟取整为 0s） |
| 业务断言执行数 | 0 / 24 |
| 进程退出码 | 1 |

> 说明：本次失败发生在 `login()` 的网络请求阶段，尚未进入任何业务断言。因此“0/1、0%”是**套件级结果**，不是把登录异常伪计为业务断言失败；24 项业务断言均未执行，无法评价制造模块功能是否通过。

## 失败明细

| # | 阶段 | 预期 | 实际 | 影响 |
|---|---|---|---|---|
| 1 | 登录 `POST /sys/login` | 登录成功后执行 24 项制造业务断言 | Node.js 报 `fetch failed`，进程退出码 1 | BOM、生产订单、领料、完工入库全部未测，清理逻辑也未进入 |

### 只读核验证据

1. 当前进程未设置 `HARNESS_BASE`。
2. `manufacturing.test.js:5` 的默认地址是 `http://100.122.125.106:8080/jeecg-boot`，并非任务环境声明的 `http://localhost:8080/jeecg-boot`。
3. 对脚本默认远端地址探测时，TCP 可连接，但服务立即返回空响应：`curl: (52) Empty reply from server`。
4. 对任务声明的本地后端探测时，`localhost:8080` 无法连接：HTTP `000`，约 2.262s 后连接失败；同时未发现 8080 监听端口或 Java 后端进程。
5. 测试在创建任何业务数据前失败，因此本次无需清理残留测试数据。

## 新发现 Bug

### P1 — `BUG-MANUFACTURING-HARNESS-BASE-MISMATCH`

`harness/tests/modules/manufacturing.test.js` 将默认 API 地址硬编码为旧远端 `100.122.125.106`，与当前任务环境及多数同类 API 测试使用的 `localhost` 默认值不一致。按本任务给定命令直接执行、且未显式设置 `HARNESS_BASE` 时，测试不会访问声明的本地后端，导致回归验证被错误目标地址阻断。

这属于**测试基础设施/配置缺陷**，不是制造业务功能缺陷。

### 环境异常（非产品 Bug）

任务前提称本地后端正在运行，但跑测后的独立探测显示 `localhost:8080` 不可达且无 Java 服务监听。由于业务断言完全未执行，本轮**没有发现或排除任何新的制造业务 Bug**。

## 下一步建议

1. **P1 恢复测试环境**：启动或恢复本地后端，先确认 `curl http://localhost:8080/jeecg-boot/` 能获得有效 HTTP 响应。
2. **统一测试目标地址**：将 `manufacturing.test.js` 默认地址改为 `http://localhost:8080/jeecg-boot`；在修复前，也可显式设置 `HARNESS_BASE=http://localhost:8080/jeecg-boot` 后跑测。
3. **环境恢复后重跑 Slice 3.1**：应完整执行 24 项业务断言，并以脚本最终的“通过 N 项，失败 M 项”作为业务通过率；本报告当前的 0% 不可用于判断制造模块质量。
4. **若仍出现 `fetch failed`**：保留 Node.js 的底层 `cause`（如 `ECONNREFUSED`/`UND_ERR_SOCKET`）并记录实际请求 URL，避免仅有泛化错误信息。

---

**reportPath**：`hermes/eagle-eye/reports/2026-08-04/slice-3.1-manufacturing.md`  
**filesModified**：`hermes/eagle-eye/reports/2026-08-04/slice-3.1-manufacturing.md`（仅验证报告；未修改业务代码）  
**risk**：P1（制造模块回归被环境/测试地址配置阻断）

# grep 调用点验证修改范围——不信任计划声明的 N 值

**触发条件：** 计划说"需要修改 N 个文件/Service/调用点"。

**处理方式：**
1. 用 grep 搜索目标方法/类的所有引用（如 `grep "\.createBatch\("` 找所有调用方）
2. 核对计划中列出的文件清单是否覆盖了 grep 找到的所有文件
3. 特别检查 Controller（`grep "createBatch" --include="*Controller.java"`）——Controller 容易被遗漏
4. 如果 grep 结果 ≠ 计划声明的 N 值，标记为 P0（遗漏调用方）或 P1（描述不准确）

**实证：** 2026-08-01 批次手工录入评审：grep 发现 `createBatch` 仅有 3 个调用方（2 Service + 1 Controller），但计划列了 4 个。另外 2 个 Service（领料/销售出库）调的是 `stockOutFifo` 而非 `createBatch`。同时 `MesBatchController.add` L52 调 `createBatch` 是计划遗漏的第 3 个调用方——如果漏掉，批次主档手工新增功能形同虚设。

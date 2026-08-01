# V8 时代 commit 漏文件导致服务端编译失败——多 commit 修复连锁

**触发条件：** 任何修改了 mes 模块下 Entity/Service/Controller 的 commit，服务端部署连续失败 3+ 次报"package does not exist"或"method not found"。

**处理方式：**
1. **不轻信服务端报告**：本地 `mvn clean install -pl <module> -am` 必须 100% BUILD SUCCESS 才能确认代码无问题
2. **逐项核对服务端点名要的类/方法**：
   - 服务端说"缺 IMesGlobalSwitchService" → `find` 验证文件实际存在路径
   - 服务端说"缺 createBatchWithManualNo 方法" → `grep -n "createBatchWithManualNo" <interface>.java`
3. **查 `git status` 看 untracked 目录**：`git status --short` 找 `??` 标记的整个目录（最容易被忽略）
4. **批量 commit 用目录而非文件**：`git add jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/system/` 一次加完整个模块

**实证：** 2026-08-02 连续 5 个 commit 修复 5 个独立"漏提交"问题——`mesGlobalSwitch.ts`（前端 store）、`commonSetting.api.ts`（前端 API）、`mes/system/` 整个子模块（后端 6 个文件）、`createBatchWithManualNo` 方法（接口+实现）、V10.0.0 shelfLife 字段（3 个文件）。全部是 V8.0.3 commit 时新建但 `git add` 漏的文件，本地 `mvn install` 100% SUCCESS（增量编译用老 class），但服务端 `git pull` 拉不到这些 untracked 文件。

**配套 commit 模式：** 改完本地 mvn 验证 → `git status --short` 盘点 untracked → 批量 add 整个目录 → commit 前用 `grep -c "update-begin"` 和 `grep -c "update-end"` 对账。

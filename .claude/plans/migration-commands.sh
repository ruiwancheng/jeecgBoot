#!/bin/bash
# 步骤 1: harness/tests/ 目录迁移（git mv）
# 注意：必须在 git 仓库根目录执行

set -e

# 创建新目录
mkdir -p harness/tests/modules
mkdir -p harness/tests/chains

# 移动 modules/ (8 个文件)
git mv harness/tests/mes/basic.test.js harness/tests/modules/
git mv harness/tests/mes/batch-global-switch.test.js harness/tests/modules/
git mv harness/tests/mes/batch-manual-e2e.test.js harness/tests/modules/
git mv harness/tests/mes/purchase.test.js harness/tests/modules/
git mv harness/tests/mes/system.test.js harness/tests/modules/
git mv harness/tests/mes/codeRule.test.mjs harness/tests/modules/
git mv harness/tests/mes/sales-api.test.mjs harness/tests/modules/
git mv harness/tests/mes/sales-order.test.mjs harness/tests/modules/

# 删除 mes/ 目录（如果空了）
# rmdir harness/tests/mes/ 2>/dev/null || true

# 链文件保留在 mes/，步骤 2 会处理合并
# purchase-apply-order.chain.test.js
# purchase-order-receipt.chain.test.js
# purchase-payment-flow.test.js
# sales-receipt-flow.test.js
# other-stock-in.test.js
# stocktake.test.js
# finance.test.js
# manufacturing.test.js
# traceability-batch-level.test.js

echo "迁移完成。当前结构："
find harness/tests -maxdepth 2 -type f -name "*.test.*" | sort

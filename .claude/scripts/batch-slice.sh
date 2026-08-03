#!/bin/bash
# 批量派 Slice 脚本（按用户指示：连续跑，出问题记录，明天重测）
# 用法：bash .claude/scripts/batch-slice.sh
set -e

cd /d/vibecoding/jeecgBoot
COORD="term_568f9124-fd5e-40ed-aea7-b01062499b45"
RESULTS_DIR="hermes/eagle-eye/reports/2026-08-04"

# 待跑切片列表：id|file|report_name|type
SLICES=(
  "2.1|sales-receipt-flow.test.js|sales-receipt-flow|chain-base"
  "2.2|sales-chain.test.js|sales-chain|chain-new"
  "3.1|manufacturing.test.js|manufacturing|chain-base"
  "3.2|manufacturing-chain.test.js|manufacturing-chain|chain-new"
  "4.1|finance.test.js|finance|chain-base"
  "4.2|finance-chain.test.js|finance-chain|chain-new"
  "5.1|other-stock-in.test.js|other-stock-in|chain-base"
  "5.2|stocktake.test.js|stocktake|chain-base"
  "5.3|warehouse-chain.test.js|warehouse-chain|chain-new"
  "6.1|traceability-batch-level.test.js|traceability-batch-level|chain-base"
  "6.2|batch-chain.test.js|batch-chain|chain-new"
  "7.1|basic+system+codeRule.test.js|basic-system-codeRule|module-batch"
  "7.2|batch-global-switch+batch-manual-e2e.test.js|batch-modules|module-batch"
  "8.1|basic+purchase+sales-order.spec.ts|e2e-core|e2e-batch"
  "8.2|manufacturing+finance+stocktake.spec.ts|e2e-business|e2e-batch"
  "8.3|materialBatch+purchaseReceiptBatch+other-stock-in+commonSetting+traceabilityBatch.spec.ts|e2e-batch|e2e-batch"
)

# 跑命令模板
run_test() {
  local id="$1" file="$2" report="$3" type="$4"
  local report_path="$RESULTS_DIR/slice-$id-$report.md"
  local test_cmd
  case "$type" in
    chain-base|module-batch)
      # modules 测试
      if [ "$type" = "module-batch" ] && [[ "$file" == *+* ]]; then
        local files="${file//+/ }"
        files="${files//.test.js/}"
        files="${files//.test.mjs/}"
        test_cmd="cd harness && timeout 240 bash -c 'for f in $files.test.js $files.test.mjs; do [ -f \"\$f\" ] && node \"\$f\"; done' 2>&1 | tail -50"
      else
        local fpath="tests/chains/$file"
        [ "$type" = "module-batch" ] && fpath="tests/modules/$file"
        test_cmd="cd harness && timeout 180 node $fpath 2>&1 | tail -50"
      fi
      ;;
    chain-new)
      test_cmd="cd harness && timeout 180 node tests/chains/$file 2>&1 | tail -50 || echo '测试文件可能不存在（待新建）'"
      ;;
    e2e-batch)
      local files="${file//+/.spec.ts }"
      files="${files}.spec.ts"
      test_cmd="cd harness && timeout 300 npx playwright test e2e/mes/$files 2>&1 | tail -30 || echo 'E2E 测试可能因环境失败'"
      ;;
  esac
  echo "TEST_CMD: $test_cmd"
}

# 主循环
for entry in "${SLICES[@]}"; do
  IFS='|' read -r id file report type <<< "$entry"
  report_path="$RESULTS_DIR/slice-$id-$report.md"
  echo ""
  echo "=========================================="
  echo "Slice $id — $report ($type)"
  echo "=========================================="
  run_test "$id" "$file" "$report" "$type"
done
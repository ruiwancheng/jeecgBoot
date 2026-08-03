#!/usr/bin/env python
# -*- coding: utf-8 -*-
import io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

"""批量派 Slice 脚本（按用户指示：连续跑，出问题记录，明天重测）"""
import json
import subprocess
import sys
import time
from datetime import datetime, timezone

COORD = "term_568f9124-fd5e-40ed-aea7-b01062499b45"
RESULTS_DIR = "hermes/eagle-eye/reports/2026-08-04"

# 待跑切片：(id, type, file_or_path, report_name, test_cmd_template)
SLICES = [
    ("2.1", "chain-base", "sales-receipt-flow.test.js", "sales-receipt-flow",
     "cd harness && timeout 180 node tests/chains/{file} 2>&1 | tail -50"),
    ("2.2", "chain-new", "sales-chain.test.js", "sales-chain",
     "cd harness && timeout 180 node tests/chains/{file} 2>&1 | tail -50 || true"),
    ("3.1", "chain-base", "manufacturing.test.js", "manufacturing",
     "cd harness && timeout 180 node tests/modules/{file} 2>&1 | tail -50"),
    ("3.2", "chain-new", "manufacturing-chain.test.js", "manufacturing-chain",
     "cd harness && timeout 180 node tests/chains/{file} 2>&1 | tail -50 || true"),
    ("4.1", "chain-base", "finance.test.js", "finance",
     "cd harness && timeout 180 node tests/modules/{file} 2>&1 | tail -50"),
    ("4.2", "chain-new", "finance-chain.test.js", "finance-chain",
     "cd harness && timeout 180 node tests/chains/{file} 2>&1 | tail -50 || true"),
    ("5.1", "chain-base", "other-stock-in.test.js", "other-stock-in",
     "cd harness && timeout 180 node tests/modules/{file} 2>&1 | tail -50"),
    ("5.2", "chain-base", "stocktake.test.js", "stocktake",
     "cd harness && timeout 180 node tests/modules/{file} 2>&1 | tail -50"),
    ("5.3", "chain-new", "warehouse-chain.test.js", "warehouse-chain",
     "cd harness && timeout 180 node tests/chains/{file} 2>&1 | tail -50 || true"),
    ("6.1", "chain-base", "traceability-batch-level.test.js", "traceability-batch-level",
     "cd harness && timeout 180 node tests/modules/{file} 2>&1 | tail -50"),
    ("6.2", "chain-new", "batch-chain.test.js", "batch-chain",
     "cd harness && timeout 180 node tests/chains/{file} 2>&1 | tail -50 || true"),
    ("7.1", "module-batch", "basic+system+codeRule", "basic-system-codeRule",
     "cd harness && timeout 240 bash -c 'for f in tests/modules/basic.test.js tests/modules/system.test.js tests/modules/codeRule.test.mjs; do [ -f $f ] && echo --- $f --- && timeout 90 node $f; done' 2>&1 | tail -80"),
    ("7.2", "module-batch", "batch-global-switch+batch-manual-e2e", "batch-modules",
     "cd harness && timeout 240 bash -c 'for f in tests/modules/batch-global-switch.test.js tests/modules/batch-manual-e2e.test.js; do echo --- $f --- && timeout 120 node $f; done' 2>&1 | tail -80"),
    ("8.1", "e2e-batch", "basic+purchase+sales-order", "e2e-core",
     "cd harness && timeout 300 npx playwright test e2e/mes/basic.spec.ts e2e/mes/purchase.spec.ts e2e/mes/sales-order.spec.ts 2>&1 | tail -30 || true"),
    ("8.2", "e2e-batch", "manufacturing+finance+stocktake", "e2e-business",
     "cd harness && timeout 300 npx playwright test e2e/mes/manufacturing.spec.ts e2e/mes/finance.spec.ts e2e/mes/stocktake.spec.ts 2>&1 | tail -30 || true"),
    ("8.3", "e2e-batch", "materialBatch+purchaseReceiptBatch+other-stock-in+commonSetting+traceabilityBatch", "e2e-batch",
     "cd harness && timeout 300 npx playwright test e2e/mes/materialBatch.spec.ts e2e/mes/materialBatchEnabledSave.spec.ts e2e/mes/purchaseReceiptBatch.spec.ts e2e/mes/other-stock-in.spec.ts e2e/mes/commonSetting.spec.ts e2e/mes/traceabilityBatch.spec.ts 2>&1 | tail -30 || true"),
]

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='replace')

def orca_json(cmd):
    r = run(cmd)
    try:
        return json.loads(r.stdout)
    except:
        return None

def create_pi_worker():
    r = run(['orca', 'terminal', 'create', '--command', 'pi', '--json'])
    d = json.loads(r.stdout)
    return d['result']['terminal']['handle']

def send(worker, text):
    run(['orca', 'terminal', 'send', '--terminal', worker, '--text', text, '--enter'])

def close(worker):
    run(['orca', 'terminal', 'close', '--terminal', worker])

def poll_worker_done(slice_id, timeout_sec=300):
    """轮询 worker_done（30 秒间隔，最多 timeout_sec）"""
    start = time.time()
    seq = 0
    while time.time() - start < timeout_sec:
        time.sleep(30)
        inbox = orca_json(['orca', 'orchestration', 'inbox', '--json'])
        if not inbox:
            continue
        for m in inbox.get('result', {}).get('messages', []):
            if not isinstance(m, dict) or m.get('type') != 'worker_done':
                continue
            if f'[slice-{slice_id}]' in m.get('subject', '') or slice_id in m.get('body', ''):
                return m
        # 卡死检测：lastOutputAt gap > 90s
        # 简化：每段 ping
        if int(time.time() - start) % 120 < 30:
            pass  # 跳过实际 ping
    return None

def state_update(slice_id, status, **kwargs):
    """更新 .decompose-state.json"""
    with open('.claude/.decompose-state.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    # 找到 slice
    for s in data['slices']:
        for c in s.get('children', []):
            if c['id'] == slice_id:
                c['status'] = status
                for k, v in kwargs.items():
                    c[k] = v
                break
    data['updated_at'] = datetime.now(timezone.utc).astimezone().isoformat(timespec='seconds')
    with open('.claude/.decompose-state.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def make_preamble(slice_id, file_or_path, report_name, test_cmd, type_):
    """生成精简 preamble（≤ 1500 字节）"""
    test_cmd_real = test_cmd.replace('{file}', file_or_path)
    report_path = f"{RESULTS_DIR}/slice-{slice_id}-{report_name}.md"
    return f"""MES Slice {slice_id} 任务。

## 环境
- 后端运行中（http://localhost:8080/jeecg-boot）
- 分支：fix/regression-2026-08-04
- 工作目录：D:/vibecoding/jeecgBoot

## 任务（{'纯验证 + 跑测' if 'new' not in type_ else '可能需新建文件，文件不存在也汇报'}）

跑测命令：
```
{test_cmd_real}
```

## 报告
写报告到 {report_path}：
- 切片信息（id={slice_id}, name={report_name}）
- 跑测结果（通过数/失败数/通过率/耗时）
- 失败明细（如有）
- 新发现 bug（如有）
- 下一步建议

## 🚨 必须发 worker_done
完成后**第一步**调：
```
orca orchestration send --to {COORD} --type worker_done --subject "[slice-{slice_id}] {report_name} 完成" --body "测试结果：<N>/<M> 通过 <X>% 耗时 <Y>s
失败明细：<无 / 列具体>
reportPath: {report_path}
filesModified: <无 / 列修改文件>
phase: completed
risks: <无 / P0/P1>"
```

🚫 禁止：终端打印"完成"就 idle
"""

def main():
    summary = []
    for entry in SLICES:
        slice_id, type_, file_or_path, report_name, test_cmd = entry
        report_path = f"{RESULTS_DIR}/slice-{slice_id}-{report_name}.md"
        print(f"\n{'='*60}\nSlice {slice_id} — {report_name}\n{'='*60}")

        # 创建 worker
        worker = create_pi_worker()
        print(f"  worker: {worker}")

        # 注入 preamble
        preamble = make_preamble(slice_id, file_or_path, report_name, test_cmd, type_)
        send(worker, preamble)

        # 写状态
        run(['python', '.remember/tmp/sync-state.py', 'add',
             '--id', f'slice-{slice_id}',
             '--task-title', f'Slice {slice_id} {report_name}',
             '--worker-handle', worker,
             '--coordinator-handle', COORD,
             '--match-rules', json.dumps({"subject_prefix": f"[slice-{slice_id}]"}),
             '--expected-files', report_path])

        # 轮询 worker_done
        print(f"  polling...")
        result = poll_worker_done(slice_id, timeout_sec=300)
        if result:
            body = result.get('body', '')
            summary.append({
                'slice': slice_id,
                'report': report_name,
                'status': 'done',
                'preview': body[:200]
            })
            print(f"  [OK] done")
            state_update(slice_id, 'done', report=report_path)
        else:
            summary.append({
                'slice': slice_id,
                'report': report_name,
                'status': 'timeout',
                'preview': 'no worker_done in 5min'
            })
            print(f"  [TIMEOUT]")
            state_update(slice_id, 'timeout', report=report_path)

        # 关闭 worker
        close(worker)
        print(f"  worker closed")

    # 汇总
    print(f"\n{'='*60}\n[Summary]\n{'='*60}")
    for s in summary:
        print(f"  {s['slice']:6} | {s['status']:8} | {s['report']:35} | {s['preview'][:80]}")

if __name__ == '__main__':
    main()
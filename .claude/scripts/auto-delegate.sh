#!/usr/bin/env bash
# auto-delegate.sh — 联合模式自动派发脚本
# 读 decompose 输出 JSON，按依赖顺序串行/并行派发切片给 pi 工人
# 用法: ./auto-delegate.sh slices.json [--dry-run] [--max-retries N]

set -uo pipefail

# ============ 配置 ============
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(pwd)"
MAX_RETRIES="${MAX_RETRIES:-2}"
POLL_INTERVAL=60
POLL_TIMEOUT=600  # 单切片最长 10 分钟

# ============ 颜色 ============
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ============ 解析参数 ============
JSON_FILE=""
DRY_RUN=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --max-retries) MAX_RETRIES="$2"; shift 2 ;;
    -h|--help)
      echo "用法: $0 <slices.json> [--dry-run] [--max-retries N]"
      exit 0
      ;;
    *) JSON_FILE="$1"; shift ;;
  esac
done

if [ -z "$JSON_FILE" ]; then
  log_error "缺少 JSON 文件参数"; exit 1
fi
if [ ! -f "$JSON_FILE" ]; then
  log_error "JSON 文件不存在: $JSON_FILE"; exit 1
fi

# ============ 解析 JSON 切片 ============
log_info "解析 JSON: $JSON_FILE"
WIN_JSON=$(cygpath -w "$JSON_FILE" 2>/dev/null || echo "$JSON_FILE")
SLICES_JSON=$(PYTHONIOENCODING=utf-8 python -c "
import json, sys
with open(r'$WIN_JSON', encoding='utf-8') as f:
    d = json.load(f)
print(json.dumps(d.get('slices', []), ensure_ascii=False))
")
if [ -z "$SLICES_JSON" ]; then
  log_error "JSON 解析失败或无 slices"; exit 1
fi

# ============ 拓扑排序（按 depends_on） ============
log_info "拓扑排序..."
EXEC_ORDER=$(PYTHONIOENCODING=utf-8 python -c "
import json
slices = json.loads('''$SLICES_JSON''')
order = []
remaining = list(slices)
while remaining:
    progress = False
    for s in list(remaining):
        deps = s.get('depends_on', [])
        if all(d in [x['id'] for x in order] for d in deps):
            order.append(s)
            remaining.remove(s)
            progress = True
    if not progress:
        # 检测循环依赖
        cycle_ids = [s['id'] for s in remaining]
        print(f'CIRCULAR: {\",\".join(cycle_ids)}', file=sys.stderr)
        sys.exit(2)
print(json.dumps([s['id'] for s in order]))
" 2>&1)
if [[ "$EXEC_ORDER" == CIRCULAR* ]]; then
  log_error "检测到循环依赖: $EXEC_ORDER"; exit 2
fi
log_info "执行顺序: $EXEC_ORDER"

if [ "$DRY_RUN" = true ]; then
  log_info "[DRY-RUN] 不实际派发"
  echo "$SLICES_JSON" | PYTHONIOENCODING=utf-8 python -m json.tool
  exit 0
fi

# ============ 派发循环 ============
START_HASH=$(git rev-parse HEAD)
COMPLETED=()
FAILED=()

for SLICE_ID in $(echo "$EXEC_ORDER" | PYTHONIOENCODING=utf-8 python -c "import json,sys; print(' '.join(json.load(sys.stdin)))"); do
  # 提取切片详情
  SLICE_JSON=$(PYTHONIOENCODING=utf-8 python -c "
import json
slices = json.loads('''$SLICES_JSON''')
for s in slices:
    if s['id'] == '$SLICE_ID':
        print(json.dumps(s, ensure_ascii=False))
        break
")

  RETRY=0
  while [ $RETRY -le $MAX_RETRIES ]; do
    log_info "派发切片 [$SLICE_ID] (重试 $RETRY/$MAX_RETRIES)"

    # 创建 pi 终端
    HANDLE=$(orca terminal create --command "pi" --json 2>/dev/null | PYTHONIOENCODING=utf-8 python -c "
import json, sys
d = json.load(sys.stdin)
print(d['result']['terminal']['handle'])
" 2>/dev/null)

    if [ -z "$HANDLE" ]; then
      log_error "创建终端失败"; RETRY=$((RETRY+1)); continue
    fi
    log_info "  handle=$HANDLE"

    # 等 TUI idle
    orca terminal wait --terminal "$HANDLE" --for tui-idle --timeout-ms 60000 --json > /dev/null 2>&1

    # 生成 preamble
    PREAMBLE=$(PYTHONIOENCODING=utf-8 python << PYEOF
import json
slice = json.loads('''$SLICE_JSON''')
files = '\n'.join(f'- {f}' for f in slice.get('files', []))
deps = ', '.join(slice.get('depends_on', [])) or '无'
preamble = f"""# MES 记忆卡片

## 🤖 恢复指令
- 当前阶段：implement（切片 {slice['id']}）
- 行为：直接做
- 接力次数：1
- 切片依赖：{deps}

## 🎯 当前会话
- 正在做：{slice['name']}
- 风险：{slice.get('risk', '中')}
- 工作量：{slice.get('effort', '中')}

## ⚠️ 关键提醒
- /verify 禁止 mvn clean
- 任何代码改动必须先 orca-review
- 完成后必须 worker_done

## 当前任务
**{slice['name']}**

用户路径：{slice.get('user_path', 'N/A')}

验收标准：{slice.get('acceptance', 'N/A')}

改文件：
{files}

要求：
- 严格遵循 preamble v4.0 全 10 步
- commit: feat/fix(...): {slice['name']}
- 完成后 worker_done
"""
print(preamble)
PYEOF
)

    # 注入
    orca terminal send --terminal "$HANDLE" --text "$PREAMBLE" --enter > /dev/null 2>&1
    log_info "  preamble 已注入"

    # 等待完成（git 兜底）
    PRE_HASH="$START_HASH"
    ELAPSED=0
    COMPLETED_FLAG=false

    while [ $ELAPSED -lt $POLL_TIMEOUT ]; do
      sleep $POLL_INTERVAL
      ELAPSED=$((ELAPSED + POLL_INTERVAL))

      # git 兜底：新 commit 是否包含本切片 ID
      CURRENT_HASH=$(git rev-parse HEAD 2>/dev/null)
      if [ "$CURRENT_HASH" != "$PRE_HASH" ]; then
        if git log --oneline "$PRE_HASH..$CURRENT_HASH" 2>/dev/null | grep -q "$SLICE_ID"; then
          log_info "  ✅ [$SLICE_ID] 已 commit ($CURRENT_HASH)"
          COMPLETED_FLAG=true
          break
        fi
      fi

      # inbox 兜底：worker_done 是否到
      HAS_DONE=$(orca orchestration inbox --json 2>/dev/null | PYTHONIOENCODING=utf-8 python -c "
import json, sys
try:
    d = json.load(sys.stdin)
    msgs = d.get('result', {}).get('messages', [])
    done = [m for m in msgs if isinstance(m, dict) and m.get('type')=='worker_done']
    print(len(done))
except: print(0)
" 2>/dev/null)
      [ "$HAS_DONE" != "0" ] && { log_info "  ✅ [$SLICE_ID] worker_done 收到"; COMPLETED_FLAG=true; break; }

      # 僵死检测（每 5 分钟）
      if [ $((ELAPSED % 300)) -eq 0 ] && [ $ELAPSED -gt 0 ]; then
        PV=$(orca terminal show --terminal "$HANDLE" --json 2>/dev/null | PYTHONIOENCODING=utf-8 python -c "
import json, sys
try:
    d = json.load(sys.stdin)
    pv = d.get('result', {}).get('terminal', {}).get('preview', '')
    print(len(pv))
except: print(0)
" 2>/dev/null)
        if [ "$PV" = "0" ] || [ -z "$PV" ]; then
          log_warn "  工人僵死信号（preview 空 $ELAPSED 秒），触发重派"
          orca terminal close --terminal "$HANDLE" > /dev/null 2>&1
          break
        fi
      fi
    done

    # 收尾
    orca terminal close --terminal "$HANDLE" > /dev/null 2>&1
    START_HASH=$(git rev-parse HEAD 2>/dev/null)

    if [ "$COMPLETED_FLAG" = true ]; then
      COMPLETED+=("$SLICE_ID")
      break
    else
      RETRY=$((RETRY+1))
      if [ $RETRY -le $MAX_RETRIES ]; then
        log_warn "  [$SLICE_ID] 未完成，60s 后重试"
        sleep 60
      fi
    fi
  done

  [ "$COMPLETED_FLAG" != true ] && FAILED+=("$SLICE_ID")
done

# ============ 汇总 ============
echo ""
log_info "================================"
log_info "派发完成"
log_info "  成功: ${#COMPLETED[@]} (${COMPLETED[*]})"
log_info "  失败: ${#FAILED[@]} (${FAILED[*]})"
log_info "================================"

# 自动 push 成功的 commit
if [ ${#COMPLETED[@]} -gt 0 ]; then
  log_info "推送 commit 到 origin/main..."
  git push origin main 2>&1 | tail -3
fi

[ ${#FAILED[@]} -gt 0 ] && exit 1 || exit 0
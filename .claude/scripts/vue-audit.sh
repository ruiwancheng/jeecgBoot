#!/usr/bin/env bash
# vue-audit.sh — Vue 文件 vs 黄金模板 UX 基线审计
# 用法: ./vue-audit.sh <vue-file> [--strict]
# 输出: PASS / WARN / FAIL + 逐项检查明细

set -uo pipefail

# ============ 配置 ============
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
STRICT=false

# ============ 解析参数 ============
VUE_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) STRICT=true; shift ;;
    -h|--help)
      echo "用法: $0 <vue-file> [--strict]"
      echo "  --strict  WARN 也算 FAIL"
      exit 0
      ;;
    *) VUE_FILE="$1"; shift ;;
  esac
done

if [ -z "$VUE_FILE" ] || [ ! -f "$VUE_FILE" ]; then
  echo -e "${RED}[ERROR]${NC} 缺少有效 Vue 文件"; exit 1
fi

# ============ 文件类型识别 ============
IS_INDEX=$(basename "$VUE_FILE" | grep -qE "^index\.vue$" && echo true || echo false)
IS_DRAWER=$(basename "$VUE_FILE" | grep -qE "Drawer\.vue$" && echo true || echo false)

if [ "$IS_INDEX" != "true" ] && [ "$IS_DRAWER" != "true" ]; then
  echo -e "${YELLOW}[SKIP]${NC} $VUE_FILE 非 index.vue/Drawer.vue，跳过审计"
  exit 0
fi

# ============ 审计项 ============
PASS=0; WARN=0; FAIL=0
RESULTS=()

check() {
  local name="$1" status="$2" detail="$3"
  RESULTS+=("$name|$status|$detail")
  case "$status" in
    PASS) PASS=$((PASS+1)); echo -e "  ${GREEN}✓ PASS${NC} $name — $detail" ;;
    WARN) WARN=$((WARN+1)); echo -e "  ${YELLOW}⚠ WARN${NC} $name — $detail" ;;
    FAIL) FAIL=$((FAIL+1)); echo -e "  ${RED}✗ FAIL${NC} $name — $detail" ;;
  esac
}

echo ""
echo "═══════════════════════════════════════════════════════"
echo "Vue UX 审计：$VUE_FILE"
echo "类型：$( [ "$IS_INDEX" = "true" ] && echo "列表页 (index.vue)" || echo "抽屉页 (Drawer.vue)")"
echo "═══════════════════════════════════════════════════════"
echo ""

# ============ 0. @generated-from 标注 ============
if grep -q "@generated-from" "$VUE_FILE"; then
  check "模板来源标注" "PASS" "已标注 @generated-from"
else
  check "模板来源标注" "WARN" "缺失 @generated-from（建议标注模板来源）"
fi

# ============ 列表页审计 ============
if [ "$IS_INDEX" = "true" ]; then
  echo "── 列表页 UX 基线 ──"

  # 1. 搜索栏字典下拉
  if grep -qE "JDictSelectTag|ApiSelect" "$VUE_FILE"; then
    check "搜索栏字典下拉" "PASS" "找到 JDictSelectTag/ApiSelect"
  else
    check "搜索栏字典下拉" "WARN" "未找到字典下拉组件"
  fi

  # 2. 复选框 rowSelection
  if grep -qE "rowSelection|checkbox" "$VUE_FILE"; then
    check "复选框（rowSelection）" "PASS" "已配置"
  else
    check "复选框（rowSelection）" "WARN" "未配置 rowSelection"
  fi

  # 3. 操作列按 status 动态显隐
  if grep -qE "status.*===|'1'.*===|'3'.*===" "$VUE_FILE"; then
    check "操作列按 status 动态显隐" "PASS" "检测到 status 判断"
  else
    check "操作列按 status 动态显隐" "WARN" "未检测到 status 条件渲染"
  fi

  # 4. 主子表展开行组件
  if grep -qE "ItemsSubTable|expand" "$VUE_FILE"; then
    check "主子表展开行" "PASS" "找到 ItemsSubTable/expand"
  else
    check "主子表展开行" "WARN" "主子表页面应有展开行（如适用）"
  fi
fi

# ============ 抽屉页审计 ============
if [ "$IS_DRAWER" = "true" ]; then
  echo "── 抽屉页 UX 基线 ──"

  # 1. 自动获取编码
  if grep -qE "getNextCode|MES_BIZ_CODE" "$VUE_FILE"; then
    check "新增自动获取编码" "PASS" "找到 getNextCode/MES_BIZ_CODE"
  else
    check "新增自动获取编码" "WARN" "未检测到编码自动获取"
  fi

  # 2. JMaterialSelect 选物料
  if grep -qE "JMaterialSelect" "$VUE_FILE"; then
    check "JMaterialSelect 选物料" "PASS" "已使用"
  else
    check "JMaterialSelect 选物料" "WARN" "未使用（业务需要时）"
  fi

  # 3. 选物料预填 unitCost
  if grep -qE "onMaterialChange|unitCost|movingAvgCost" "$VUE_FILE"; then
    check "选物料预填成本" "PASS" "找到 onMaterialChange/unitCost"
  else
    check "选物料预填成本" "WARN" "未检测到成本预填"
  fi

  # 4. MaterialSelectModal 批量添加
  if grep -qE "MaterialSelectModal" "$VUE_FILE"; then
    check "批量添加物料弹窗" "PASS" "已使用 MaterialSelectModal"
  else
    check "批量添加物料弹窗" "WARN" "未使用（业务需要时）"
  fi

  # 5. confirmLoading 防重复点击
  if grep -qE "confirmLoading" "$VUE_FILE"; then
    check "confirmLoading 防重复" "PASS" "已配置"
  else
    check "confirmLoading 防重复" "FAIL" "缺失（必填）"
  fi

  # 6. 业务规则 Alert
  if grep -qE "a-alert|AaAlert|<Alert" "$VUE_FILE"; then
    check "业务规则 Alert" "PASS" "已配置"
  else
    check "业务规则 Alert" "WARN" "未配置（按需）"
  fi

  # 7. 表单提交 loading 状态
  if grep -qE "setDrawerProps.*loading|loading.*true" "$VUE_FILE"; then
    check "提交 loading 状态" "PASS" "已配置"
  else
    check "提交 loading 状态" "WARN" "未检测到"
  fi
fi

# ============ 通用：状态机 ============
echo "── 状态机 ──"

if grep -qE "popConfirm|PopConfirm|popconfirm" "$VUE_FILE"; then
  check "删除有 popConfirm" "PASS" "已配置"
else
  check "删除有 popConfirm" "WARN" "未检测到 popConfirm"
fi

if grep -qE "@confirm|Modal\.confirm|requireConfirm" "$VUE_FILE"; then
  check "审核/反审核有确认" "PASS" "已配置"
else
  check "审核/反审核有确认" "WARN" "未检测到确认弹窗"
fi

# ============ 通用：展示值 ============
echo "── 展示值 ──"

if grep -qE "materialId_dictText|_dictText" "$VUE_FILE"; then
  check "字典翻译展示" "PASS" "已使用 _dictText"
else
  check "字典翻译展示" "WARN" "未检测到 _dictText"
fi

# 裸 ID 检测（排除 _dictText 和 _dict 后的）
if grep -qE "{{.*\.materialId[^_]}}|{{ record\.materialId[^_]}}" "$VUE_FILE"; then
  check "禁止裸 ID 展示" "FAIL" "检测到裸 materialId 展示（应改为 _dictText）"
else
  check "禁止裸 ID 展示" "PASS" "未发现裸 ID"
fi

if grep -qE "#f5222d|red.*color" "$VUE_FILE"; then
  check "异常值红标高亮" "PASS" "找到红标样式"
else
  check "异常值红标高亮" "WARN" "未检测到红标（按需）"
fi

# ============ 汇总 ============
echo ""
echo "═══════════════════════════════════════════════════════"
echo -e "汇总：${GREEN}PASS $PASS${NC}  ${YELLOW}WARN $WARN${NC}  ${RED}FAIL $FAIL${NC}"
echo "═══════════════════════════════════════════════════════"

# ============ 退出码 ============
if [ $FAIL -gt 0 ]; then
  exit 1
elif [ "$STRICT" = true ] && [ $WARN -gt 0 ]; then
  exit 1
else
  exit 0
fi
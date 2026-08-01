#!/usr/bin/env bash
# vue-audit.sh — Vue 页面 vs 黄金模板 UX 基线审计
#
# 用法:
#   ./vue-audit.sh <vue-file>           # 单文件模式（向后兼容）
#   ./vue-audit.sh <page-dir>           # 按页面目录聚合（v2 新增）
#   ./vue-audit.sh --all                # 全量按页面枚举（v2 重定义口径）
#   ./vue-audit.sh <...> [--strict]     # 严格模式：WARN 也算 FAIL
#
# v2 变更（2026-08-01）：
#   - 新增"按页面目录"模式：输入为目录时聚合 index.vue + Drawer.vue + data.ts + api.ts
#   - --all 口径改为"扫描 X 个页面（含 Y 个文件）"
#   - 4 个守卫：空目录/简单页面/多 api.ts/子目录提示
#   - 跨文件一致性：data.ts 引用的 ApiSelect 函数必须在 api.ts 中存在
#   - 向后兼容：传单文件路径时行为零变化（pre-vue-audit.sh hook 链路稳定）

set -o pipefail

# ============ 配置 ============
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
STRICT=false
MODE="single"
INPUT=""

# ============ 解析参数 ============
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) STRICT=true; shift ;;
    --all) MODE="all"; shift ;;
    -h|--help)
      echo "用法: $0 <vue-file|page-dir> [--strict] | --all [--strict]"
      echo ""
      echo "模式："
      echo "  <vue-file>   单文件审计（向后兼容，pre-commit hook 使用）"
      echo "  <page-dir>   按页面目录聚合（index + Drawer + data + api）"
      echo "  --all        全量按页面枚举，输出页面合规率"
      echo "  --strict     WARN 也算 FAIL"
      exit 0
      ;;
    *) INPUT="$1"; shift ;;
  esac
done

# ============ 文件类型识别 ============
is_index()  { basename "$1" | grep -qE "^index\.vue$"; }
is_drawer() { basename "$1" | grep -qE "Drawer\.vue$"; }
is_data()   { basename "$1" | grep -qE "\.data\.ts$"; }
is_api()    { basename "$1" | grep -qE "\.api\.ts$"; }

# ============ 结果打印（累加 PASS/WARN/FAIL）============
PASS=0; WARN=0; FAIL=0
print_check() {
  local name="$1" status="$2" detail="$3"
  case "$status" in
    PASS) PASS=$((PASS+1)); echo -e "  ${GREEN}✓ PASS${NC} $name — $detail" ;;
    WARN) WARN=$((WARN+1)); echo -e "  ${YELLOW}⚠ WARN${NC} $name — $detail" ;;
    FAIL) FAIL=$((FAIL+1)); echo -e "  ${RED}✗ FAIL${NC} $name — $detail" ;;
  esac
}

# ============ 单文件审计（14 项基线，原 vue-audit.sh 核心逻辑）============
# 直接调用 print_check 累加全局 PASS/WARN/FAIL
audit_one_file() {
  local file="$1"
  local is_idx=false is_drw=false
  is_index "$file"  && is_idx=true
  is_drawer "$file" && is_drw=true

  if [ "$is_idx" != "true" ] && [ "$is_drw" != "true" ]; then
    echo "__SKIP__"
    return
  fi

  # 0. @generated-from 标注
  if grep -q "@generated-from" "$file"; then
    print_check "模板来源标注" "PASS" "已标注 @generated-from"
  else
    print_check "模板来源标注" "WARN" "缺失 @generated-from（建议标注模板来源）"
  fi

  # 列表页 4 项
  if [ "$is_idx" = "true" ]; then
    if grep -qE "JDictSelectTag|ApiSelect" "$file"; then
      print_check "搜索栏字典下拉" "PASS" "找到 JDictSelectTag/ApiSelect"
    else
      print_check "搜索栏字典下拉" "WARN" "未找到字典下拉组件"
    fi
    if grep -qE "rowSelection|checkbox" "$file"; then
      print_check "复选框（rowSelection）" "PASS" "已配置"
    else
      print_check "复选框（rowSelection）" "WARN" "未配置 rowSelection"
    fi
    if grep -qE "status.*===|'1'.*===|'3'.*===" "$file"; then
      print_check "操作列按 status 动态显隐" "PASS" "检测到 status 判断"
    else
      print_check "操作列按 status 动态显隐" "WARN" "未检测到 status 条件渲染"
    fi
    if grep -qE "ItemsSubTable|expand" "$file"; then
      print_check "主子表展开行" "PASS" "找到 ItemsSubTable/expand"
    else
      print_check "主子表展开行" "WARN" "主子表页面应有展开行（如适用）"
    fi
  fi

  # 抽屉页 7 项
  if [ "$is_drw" = "true" ]; then
    if grep -qE "getNextCode|MES_BIZ_CODE" "$file"; then
      print_check "新增自动获取编码" "PASS" "找到 getNextCode/MES_BIZ_CODE"
    else
      print_check "新增自动获取编码" "WARN" "未检测到编码自动获取"
    fi
    if grep -qE "JMaterialSelect" "$file"; then
      print_check "JMaterialSelect 选物料" "PASS" "已使用"
    else
      print_check "JMaterialSelect 选物料" "WARN" "未使用（业务需要时）"
    fi
    if grep -qE "onMaterialChange|unitCost|movingAvgCost" "$file"; then
      print_check "选物料预填成本" "PASS" "找到 onMaterialChange/unitCost"
    else
      print_check "选物料预填成本" "WARN" "未检测到成本预填"
    fi
    if grep -qE "MaterialSelectModal" "$file"; then
      print_check "批量添加物料弹窗" "PASS" "已使用 MaterialSelectModal"
    else
      print_check "批量添加物料弹窗" "WARN" "未使用（业务需要时）"
    fi
    if grep -qE "confirmLoading" "$file"; then
      print_check "confirmLoading 防重复" "PASS" "已配置"
    else
      print_check "confirmLoading 防重复" "FAIL" "缺失（必填）"
    fi
    if grep -qE "a-alert|AaAlert|<Alert" "$file"; then
      print_check "业务规则 Alert" "PASS" "已配置"
    else
      print_check "业务规则 Alert" "WARN" "未配置（按需）"
    fi
    if grep -qE "setDrawerProps.*loading|loading.*true" "$file"; then
      print_check "提交 loading 状态" "PASS" "已配置"
    else
      print_check "提交 loading 状态" "WARN" "未检测到"
    fi
  fi

  # 通用：状态机
  if grep -qE "popConfirm|PopConfirm|popconfirm" "$file"; then
    print_check "删除有 popConfirm" "PASS" "已配置"
  else
    print_check "删除有 popConfirm" "WARN" "未检测到 popConfirm"
  fi
  if grep -qE "@confirm|Modal\.confirm|requireConfirm" "$file"; then
    print_check "审核/反审核有确认" "PASS" "已配置"
  else
    print_check "审核/反审核有确认" "WARN" "未检测到确认弹窗"
  fi

  # 通用：展示值
  if grep -qE "materialId_dictText|_dictText" "$file"; then
    print_check "字典翻译展示" "PASS" "已使用 _dictText"
  else
    print_check "字典翻译展示" "WARN" "未检测到 _dictText"
  fi
  if grep -qE "{{.*\.materialId[^_]}}|{{ record\.materialId[^_]}}" "$file"; then
    print_check "禁止裸 ID 展示" "FAIL" "检测到裸 materialId 展示（应改为 _dictText）"
  else
    print_check "禁止裸 ID 展示" "PASS" "未发现裸 ID"
  fi
  if grep -qE "#f5222d|red.*color" "$file"; then
    print_check "异常值红标高亮" "PASS" "找到红标样式"
  else
    print_check "异常值红标高亮" "WARN" "未检测到红标（按需）"
  fi
}

# ============ data.ts 轻量化审计（3 项）============
# 1. @generated-from  2. 结构完整性  3. 跨文件：ApiSelect 引用
audit_data_file() {
  local file="$1" page_dir="$2"

  if grep -q "@generated-from" "$file"; then
    print_check "模板来源标注" "PASS" "已标注 @generated-from"
  else
    print_check "模板来源标注" "WARN" "缺失 @generated-from"
  fi

  if grep -qE "BasicColumn|FormSchema" "$file"; then
    print_check "结构完整性" "PASS" "导入了 BasicColumn/FormSchema"
  else
    print_check "结构完整性" "WARN" "未导入 BasicColumn/FormSchema"
  fi

  # 跨文件：data.ts 引用的 query*Select 必须存在于 api.ts
  local refs
  refs=$(grep -oE "query[A-Z][a-zA-Z]+Select" "$file" 2>/dev/null | sort -u)
  if [ -n "$refs" ]; then
    local missing=()
    for ref in $refs; do
      # 跨文件检查范围：
      #  1. 同目录的 api.ts（主接口）
      #  2. basic/* 基础数据模块的 api.ts（仓库/客户/供应商等共享 query 函数）
      #  3. 整个项目所有 api.ts 作为兑底（性能高但安全）
      if grep -rq "export.*function $ref" "$page_dir"/*.api.ts 2>/dev/null; then
        continue
      fi
      # 兑底：检查 basic/* 模块（绝大多数 query*Select 都在这里定义）
      local basic_dir="$page_dir/../basic"
      if [ -d "$basic_dir" ]; then
        if grep -rq "export.*function $ref" "$basic_dir"/*/*.api.ts 2>/dev/null; then
          continue
        fi
      fi
      # 最终兑底：全项目扫描（最慢但保险）
      if grep -rq "export.*function $ref" "$page_dir/../../.." --include="*.api.ts" 2>/dev/null; then
        continue
      fi
      missing+=("$ref")
    done
    if [ ${#missing[@]} -eq 0 ]; then
      print_check "ApiSelect 引用完整" "PASS" "data.ts 引用 $(echo "$refs" | wc -l) 个 query 函数，全部存在于某处 api.ts"
    else
      print_check "ApiSelect 引用缺失" "FAIL" "data.ts 引用但未在 api.ts 中找到导出：${missing[*]}"
    fi
  else
    print_check "ApiSelect 引用" "PASS" "data.ts 未引用 query*Select 函数（按需）"
  fi
}

# ============ api.ts 轻量化审计（2 项）============
# 1. @generated-from  2. 标准下拉函数
audit_api_file() {
  local file="$1"
  if grep -q "@generated-from" "$file"; then
    print_check "模板来源标注" "PASS" "已标注 @generated-from"
  else
    print_check "模板来源标注" "WARN" "缺失 @generated-from"
  fi
  if grep -qE "export.*function query.*Select" "$file"; then
    print_check "标准下拉函数" "PASS" "有 query*Select 函数"
  else
    print_check "标准下拉函数" "WARN" "未发现 query*Select 标准导出"
  fi
}

# ============ 简单页面通用检查（仅 @generated-from + 字典翻译）============
audit_simple_only() {
  local file="$1"
  if grep -q "@generated-from" "$file"; then
    print_check "模板来源标注" "PASS" "已标注"
  else
    print_check "模板来源标注" "WARN" "缺失"
  fi
  if grep -qE "_dictText" "$file"; then
    print_check "字典翻译展示" "PASS" "已使用 _dictText"
  else
    print_check "字典翻译展示" "WARN" "未检测到"
  fi
}

# ============ 模式分发 ============

if [ "$MODE" = "all" ]; then
  # ============== 全量模式 ==============
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "Vue 全量页面审计（按目录单元）"
  echo "═══════════════════════════════════════════════════════"

  TOTAL_PAGES=0
  TOTAL_FILES=0
  PAGE_PASS=0
  PAGE_FAIL=0
  declare -a FAIL_PAGES

  # 辅助函数：跑一个页面目录（复用目录模式逻辑），返回 3 行 PASS/WARN/FAIL
  # 通过临时文件 + 抑制输出方式避免污染全量报告
  audit_page_silent() {
    local page_dir="$1"
    # G1 空目录
    if [ $(ls "$page_dir"/*.{vue,ts} 2>/dev/null | wc -l) -eq 0 ]; then
      echo "0 0 0"; return
    fi

    local page_files=()
    local has_index=false
    [ -f "$page_dir/index.vue" ] && { has_index=true; page_files+=("$page_dir/index.vue"); }
    for f in "$page_dir"/*Drawer.vue; do [ -f "$f" ] && page_files+=("$f"); done
    for f in "$page_dir"/*.data.ts; do [ -f "$f" ] && page_files+=("$f"); done
    # api.ts: 注意目录可能是 kebab-case 而 api.ts 是 camelCase，不强行匹配同名
    local first_api
    first_api=$(ls "$page_dir"/*.api.ts 2>/dev/null | head -1)
    [ -n "$first_api" ] && page_files+=("$first_api")

    # 简单页面
    if [ ${#page_files[@]} -eq 1 ] && [ "$has_index" = true ]; then
      local sp=0 sw=0 sf=0
      is_index "$page_dir/index.vue" || is_drawer "$page_dir/index.vue" || {
        echo "0 0 0"; return
      }
      local saved_p=$PASS saved_w=$WARN saved_f=$FAIL
      PASS=0; WARN=0; FAIL=0
      if is_index "$page_dir/index.vue"; then
        # 简单 index.vue 走简单检查
        audit_simple_only "$page_dir/index.vue" >/dev/null
      else
        audit_one_file "$page_dir/index.vue" >/dev/null
      fi
      sp=$PASS; sw=$WARN; sf=$FAIL
      PASS=$saved_p; WARN=$saved_w; FAIL=$saved_f
      echo "$sp $sw $sf"
      return
    fi

    # 完整审计
    local saved_p=$PASS saved_w=$WARN saved_f=$FAIL
    PASS=0; WARN=0; FAIL=0
    for f in "${page_files[@]}"; do
      if is_data "$f"; then
        audit_data_file "$f" "$page_dir" >/dev/null
      elif is_api "$f"; then
        audit_api_file "$f" >/dev/null
      else
        audit_one_file "$f" >/dev/null
      fi
    done
    local sp=$PASS sw=$WARN sf=$FAIL
    PASS=$saved_p; WARN=$saved_w; FAIL=$saved_f
    echo "$sp $sw $sf"
  }

  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    TOTAL_PAGES=$((TOTAL_PAGES+1))
    FILE_COUNT=$(ls "$dir"/*.{vue,ts} 2>/dev/null | wc -l)
    TOTAL_FILES=$((TOTAL_FILES+FILE_COUNT))

    read P W F < <(audit_page_silent "$dir")

    if [ "$F" -gt 0 ] 2>/dev/null; then
      PAGE_FAIL=$((PAGE_FAIL+1))
      FAIL_PAGES+=("$dir  [P$P/W$W/F$F]")
    elif [ "$STRICT" = true ] && [ "$W" -gt 0 ] 2>/dev/null; then
      PAGE_FAIL=$((PAGE_FAIL+1))
      FAIL_PAGES+=("$dir  [P$P/W$W/F0 --strict]")
    else
      PAGE_PASS=$((PAGE_PASS+1))
    fi
  done < <(find jeecgboot-vue3/src/views -name "index.vue" -type f 2>/dev/null \
            | xargs -I{} dirname {} 2>/dev/null | sort -u)

  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "全量汇总：扫描 $TOTAL_PAGES 个页面（含 $TOTAL_FILES 个相关文件）"
  echo -e "  ${GREEN}✓ PASS 页面：$PAGE_PASS${NC}"
  echo -e "  ${YELLOW}⚠ WARN 页面：$((TOTAL_PAGES - PAGE_PASS - PAGE_FAIL))${NC}（合规率良好，未单列）"
  echo -e "  ${RED}✗ FAIL 页面：$PAGE_FAIL${NC}"
  if [ ${#FAIL_PAGES[@]} -gt 0 ]; then
    echo ""
    echo "FAIL 页面清单："
    for p in "${FAIL_PAGES[@]}"; do
      echo "  $p"
    done
  fi
  echo "═══════════════════════════════════════════════════════"

  [ "$PAGE_FAIL" -gt 0 ] && exit 1
  exit 0

elif [ -d "$INPUT" ]; then
  # ============== 目录模式 ==============
  PAGE_DIR="$INPUT"
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "Vue 页面审计：$PAGE_DIR"
  echo "═══════════════════════════════════════════════════════"

  # G1: 空目录守卫
  FILE_TOTAL=$(ls "$PAGE_DIR"/*.{vue,ts} 2>/dev/null | wc -l)
  if [ "$FILE_TOTAL" -eq 0 ]; then
    echo "无 Vue/TS 文件"; exit 0
  fi

  # G4: 子目录提示
  SUBS=$(find "$PAGE_DIR" -mindepth 1 -type d 2>/dev/null)
  if [ -n "$SUBS" ]; then
    echo -e "${YELLOW}⚠${NC} 子目录不会被审计（递归功能未启用）："
    while IFS= read -r s; do echo "  - $s"; done <<< "$SUBS"
    echo ""
  fi

  # 收集页面文件
  declare -a PAGE_FILES=()
  HAS_INDEX=false

  # 1. 锚点 index.vue
  [ -f "$PAGE_DIR/index.vue" ] && { HAS_INDEX=true; PAGE_FILES+=("$PAGE_DIR/index.vue"); }

  # 2. *Drawer.vue（可能多个，正常情况只有一个）
  for f in "$PAGE_DIR"/*Drawer.vue; do
    [ -f "$f" ] && PAGE_FILES+=("$f")
  done

  # 3. *.data.ts（通常一个）
  for f in "$PAGE_DIR"/*.data.ts; do
    [ -f "$f" ] && PAGE_FILES+=("$f")
  done

  # 4. *.api.ts — G3: 多 api.ts 时提示，取第一个审计
  # 注意：目录可能是 kebab-case (other-out) 而 api.ts 是 camelCase (otherOut.api.ts)，
  # 不能强行匹配同名
  DIR_NAME=$(basename "$PAGE_DIR")
  API_COUNT=$(ls "$PAGE_DIR"/*.api.ts 2>/dev/null | wc -l)
  FIRST_API=$(ls "$PAGE_DIR"/*.api.ts 2>/dev/null | head -1)
  if [ "$API_COUNT" -gt 1 ]; then
    echo -e "${YELLOW}⚠${NC} 目录含 $API_COUNT 个 api.ts（同名匹配不可靠：目录 $DIR_NAME vs api.ts），仅审计第一个：$(basename "$FIRST_API")"
  fi
  if [ -n "$FIRST_API" ]; then
    PAGE_FILES+=("$FIRST_API")
  fi

  echo "文件数：${#PAGE_FILES[@]}"
  echo ""

  # G2: 简单页面守卫（只有 index.vue）
  if [ "${#PAGE_FILES[@]}" -eq 1 ] && [ "$HAS_INDEX" = true ]; then
    echo -e "${YELLOW}[简单页面]${NC} 仅 index.vue，只跑通用检查"
    echo ""
    PASS=0; WARN=0; FAIL=0
    audit_simple_only "$PAGE_DIR/index.vue"
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo -e "页面汇总：${GREEN}PASS $PASS${NC}  ${YELLOW}WARN $WARN${NC}  ${RED}FAIL $FAIL${NC}"
    echo "═══════════════════════════════════════════════════════"
    [ "$FAIL" -gt 0 ] && exit 1
    [ "$STRICT" = true ] && [ "$WARN" -gt 0 ] && exit 1
    exit 0
  fi

  # 完整审计
  PASS=0; WARN=0; FAIL=0
  for f in "${PAGE_FILES[@]}"; do
    fname=$(basename "$f")
    echo "── $fname ──"
    if is_data "$f"; then
      audit_data_file "$f" "$PAGE_DIR"
    elif is_api "$f"; then
      audit_api_file "$f"
    else
      # audit_one_file 直接 print_check；若文件不是 index/Drawer 会跳过
      audit_one_file "$f" || true
      # 检查是否跳过（SKIP 时会输出 SKIP，但 audit_one_file 不会 echo __SKIP__ 了）
      # 用 is_index/is_drawer 二次判断
      if ! is_index "$f" && ! is_drawer "$f"; then
        echo -e "  ${YELLOW}[SKIP]${NC} $fname 非 index.vue/Drawer.vue"
      fi
    fi
    echo ""
  done

  echo "═══════════════════════════════════════════════════════"
  echo -e "页面汇总：${GREEN}PASS $PASS${NC}  ${YELLOW}WARN $WARN${NC}  ${RED}FAIL $FAIL${NC}"
  echo "═══════════════════════════════════════════════════════"

  [ "$FAIL" -gt 0 ] && exit 1
  [ "$STRICT" = true ] && [ "$WARN" -gt 0 ] && exit 1
  exit 0

elif [ -f "$INPUT" ]; then
  # ============== 单文件模式（向后兼容，行为零变化）==============
  VUE_FILE="$INPUT"
  IS_INDEX=false
  IS_DRAWER=false
  is_index "$VUE_FILE"  && IS_INDEX=true
  is_drawer "$VUE_FILE" && IS_DRAWER=true

  if [ "$IS_INDEX" != "true" ] && [ "$IS_DRAWER" != "true" ]; then
    echo -e "${YELLOW}[SKIP]${NC} $VUE_FILE 非 index.vue/Drawer.vue，跳过审计"
    exit 0
  fi

  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "Vue UX 审计：$VUE_FILE"
  echo "类型：$( [ "$IS_INDEX" = "true" ] && echo "列表页 (index.vue)" || echo "抽屉页 (Drawer.vue)")"
  echo "═══════════════════════════════════════════════════════"
  echo ""

  PASS=0; WARN=0; FAIL=0
  audit_one_file "$VUE_FILE"

  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo -e "汇总：${GREEN}PASS $PASS${NC}  ${YELLOW}WARN $WARN${NC}  ${RED}FAIL $FAIL${NC}"
  echo "═══════════════════════════════════════════════════════"

  [ "$FAIL" -gt 0 ] && exit 1
  [ "$STRICT" = true ] && [ "$WARN" -gt 0 ] && exit 1
  exit 0
else
  echo -e "${RED}[ERROR]${NC} 输入既不是文件也不是目录: $INPUT"
  exit 1
fi
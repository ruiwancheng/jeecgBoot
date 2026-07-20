
# -*- coding: utf-8 -*-
"""
Spec-driven bigscreen builder.

AI outputs a compact JSON spec; this builder expands it into full component
configs with auto-applied dark theme, axis styling, gradient shortcuts,
chartData serialization, and built-in pitfall avoidance (pie has no xAxis/yAxis,
variant suffix resolution, transparent container bg, etc).

Usage:
    py spec_builder.py <API> <TOKEN> <spec.json>
    py spec_builder.py <API> <TOKEN> <spec.json> --page-id <ID>   # 追加/迭代到已有页面
    py spec_builder.py <API> <TOKEN> --dry <spec.json>            # compile-only, no API calls
    py spec_builder.py --schema <CompType>               # print spec schema for one component
    py spec_builder.py --schema <CompType> --full        # + dump complete defaults JSON (deep option)
    py spec_builder.py --schema --list                   # list all supported compTypes

Spec format:
{
  "page": {"name": "...", "bg": "bg4", "theme": "dark"},
  "palette": "科技",                                // 可选：整屏命名色板，自动应用
  "delete": {"types": [...], "names": [...], "ids": [...]},  // 可选：--page-id 模式下删除既有组件
  "components": [
    {"type": "JText", "pos": [x,y,w,h], "text": "...", "style": "title"},
    {"type": "JBar",  "pos": [...], "title": "...",
     "data": [{"name":"A","value":1}], "color": "#00d4ff",
     "gradient": ["v","#0064a0","#00d4ff"], "barWidth": 16},
    {"type": "JPie",  "pos": [...], "title": "...",
     "data": [...], "colors": ["#ff6b6b","#ffa726"]},
    ...
  ]
}

迭代一体化（核心提速场景）：--page-id 模式下 `delete` + `components`(新增) + `palette`
一次 query_page → 过滤旧组件 → 追加新组件 → 应用色板 → 一次 save_page，
取代 "comp_ops delete × N + spec_builder append + style_ops set-palette" 多脚本串接。
"""
import sys, os, json, time, copy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

DEFAULTS_DIR = os.path.join(HERE, 'defaults')

# 首次读盘后常驻，后续调用返回深拷贝，避免 N 组件大屏 N 次磁盘 I/O。
# 132 个 defaults JSON 总计 ~656KB，全量驻留代价可接受。
_DEFAULTS_CACHE: dict = {}

# ---------------------------------------------------------------
# Palette presets — AI only picks a bg alias, colors inferred
# ---------------------------------------------------------------
PALETTES = {
    'bg4': {
        'title':      '#f0c040',
        'subtitle':   '#00d4ff',
        'label':      '#ffffff',
        'value':      '#d4e8ff',
        'axis':       '#8ab8d0',
        'axisLine':   '#1a3a5a',
        'gridline':   '#1a3a5a55',
        'tooltipBg':  '#0b1e3acc',
        'tooltipTxt': '#e0f0ff',
    },
}
PALETTES['_dark'] = dict(PALETTES['bg4'])

BG_IMAGES = {f'bg{i}': f'/img/bg/bg{i}.png' for i in range(1, 11)}

ECHARTS_CARTESIAN = {
    'JBar', 'JStackBar', 'JHorizontalBar', 'JBackgroundBar', 'JDynamicBar',
    'JMultipleBar', 'JNegativeBar', 'JPercentBar', 'JMixLineBar',
    'JLine', 'JSmoothLine', 'JStepLine', 'JArea', 'JMultipleLine', 'DoubleLineBar',
    'JScatter', 'JQuadrant', 'JBubble',
}

ECHARTS_POLAR = {
    'JPie', 'JRose', 'JRotatePie', 'JRing', 'JBreakRing', 'JActiveRing',
    'JRadialBar', 'JRadar', 'JCircleRadar', 'JFunnel', 'JPyramidFunnel',
}

# 实测：大屏（bigScreen）平台本身不支持以下 compType —— 组件未在大屏渲染层注册，生成后一律不显示。
# 仅在仪表盘（dashboard）/Online 图表中可用。spec_builder 直接禁止生成，避免占位浪费版面。
DISABLED_COMPONENTS = {
    'JRankingList',    # 大屏不渲染 → 替代：JScrollRankingBoard（DataV 排行榜）
    'JTotalProgress',  # 大屏不渲染 → 替代：JListProgress / JCapsuleChart
    'JPivotTable',     # 大屏不渲染 → 替代：JScrollBoard / JCommonTable
    'JFly3dMap',       # 大屏不支持此 compType（defaults 未录入，实测不渲染）→ 替代：JFlyLineMap / JTotalFlyLineMap
}

# Common city coordinates (allows JFlyLineMap spec to use just "from"/"to" names).
CITY_COORDS = {
    '北京': (116.4074, 39.9042), '上海': (121.4737, 31.2304),
    '深圳': (114.0579, 22.5431), '广州': (113.2644, 23.1291),
    '杭州': (120.1551, 30.2741), '成都': (104.0657, 30.6586),
    '武汉': (114.2734, 30.5801), '西安': (108.9541, 34.2658),
    '重庆': (106.5049, 29.5331), '天津': (117.1901, 39.0851),
    '南京': (118.7969, 32.0603), '苏州': (120.5853, 31.2990),
    '青岛': (120.3826, 36.0671), '大连': (121.6147, 38.9140),
    '厦门': (118.0894, 24.4798), '长沙': (112.9388, 28.2278),
    '郑州': (113.6253, 34.7466), '济南': (117.1201, 36.6512),
    '沈阳': (123.4315, 41.8057), '哈尔滨': (126.5349, 45.8038),
    '昆明': (102.8329, 24.8801), '贵阳': (106.6302, 26.6477),
    '南昌': (115.8921, 28.6765), '合肥': (117.2830, 31.8612),
    '石家庄': (114.5149, 38.0428), '太原': (112.5489, 37.8706),
    '长春': (125.3245, 43.8868), '福州': (119.2965, 26.0745),
    '兰州': (103.8343, 36.0611), '银川': (106.2309, 38.4872),
    '乌鲁木齐': (87.6177, 43.7928), '香港': (114.1694, 22.3193),
    '澳门': (113.5439, 22.1987), '台北': (121.5654, 25.0330),
}


def load_def(comp_key):
    """读取 defaults/<comp_key>.json 并返回可安全修改的副本。

    首次调用落盘读取并缓存；后续 deepcopy 缓存值返回，保证
    调用方之间互不污染（defaults 深层嵌套 dict/list，浅拷贝不够）。
    """
    cached = _DEFAULTS_CACHE.get(comp_key)
    if cached is None:
        path = os.path.join(DEFAULTS_DIR, comp_key + '.json')
        with open(path, encoding='utf-8') as f:
            cached = json.load(f)
        _DEFAULTS_CACHE[comp_key] = cached
    return copy.deepcopy(cached)


def _gradient(direction, c1, c2):
    if direction in ('v', 'vertical'):
        g = {'type': 'linear', 'x': 0, 'y': 0, 'x2': 0, 'y2': 1}
    else:
        g = {'type': 'linear', 'x': 0, 'y': 0, 'x2': 1, 'y2': 0}
    g['colorStops'] = [{'offset': 0, 'color': c1}, {'offset': 1, 'color': c2}]
    return g


def _apply_echarts_theme(opt, p, *, has_axes=True, title_text=None):
    if title_text:
        t = opt.setdefault('title', {})
        t.update({'show': True, 'text': title_text})
        t.setdefault('textStyle', {}).update({'color': p['subtitle'], 'fontSize': 13})
    if has_axes:
        for ak in ('xAxis', 'yAxis'):
            existing = opt.get(ak)
            if isinstance(existing, str):
                # e.g. JPercentBar has xAxis/yAxis as plain string — upgrade to dict
                opt[ak] = {'type': existing}
                existing = opt[ak]
            elif existing is None:
                opt[ak] = {}
                existing = opt[ak]
            # handle both single dict and list of dicts (e.g. DoubleLineBar yAxis=[{...},{...}])
            axes = existing if isinstance(existing, list) else [existing]
            for a in axes:
                if not isinstance(a, dict):
                    continue
                a.setdefault('axisLabel', {}).setdefault('color', p['axis'])
                a.setdefault('axisLine', {}).setdefault('lineStyle', {}).setdefault('color', p['axisLine'])
                if ak == 'yAxis':
                    a.setdefault('splitLine', {}).setdefault('lineStyle', {}).setdefault('color', p['gridline'])
        # Enforce minimum grid margins; especially grid.top must accommodate title+legend.
        # Defaults JSON may pre-set grid (e.g. JMultipleLine top=12), so setdefault alone
        # is insufficient — we must also clamp top upward when title+legend both sit there.
        g = opt.setdefault('grid', {})
        if 'bottom' not in g: g['bottom'] = 30
        if 'left'   not in g: g['left']   = 55
        if 'right'  not in g: g['right']  = 20
        # title(left) + legend(center) 共享同一水平行 ≈ 22px，加 8px 留白 → 30 刚好不重叠
        # 无 title 时 legend 独占该行，同样 30 即可；有 title 时也 30（非叠排，不需要 60）
        min_top = 30
        if g.get('top', 0) < min_top:
            g['top'] = min_top
    tt = opt.setdefault('tooltip', {})
    tt.setdefault('backgroundColor', p['tooltipBg'])
    tt.setdefault('textStyle', {}).setdefault('color', p['tooltipTxt'])
    opt.setdefault('legend', {}).setdefault('textStyle', {}).setdefault('color', p['axis'])


# ---------------------------------------------------------------
# Per-type handlers
# ---------------------------------------------------------------
def handle_JText(c, p):
    # 防呆：用户常把字段嵌在 spec.option 或 spec.option.body 下（仿 ECharts/前端组件直觉），
    # 但 JText 走专用 handler，只读 spec 顶级字段。这里把 spec.option(.body) 里的已知字段
    # 降级合并到顶级，提示一次后照常处理。
    err_keys = {'fontSize', 'color', 'fontWeight', 'textAlign', 'letterSpacing',
                'fontStyle', 'fontFamily', 'marginLeft', 'marginTop'}
    opt = c.get('option') or {}
    misplaced = {k: v for k, v in opt.items() if k in err_keys}
    body_misplaced = {k: v for k, v in (opt.get('body') or {}).items() if k in err_keys}
    # spec.data[0].value / spec.option.body.text 也是用户常写错的"标题来源"
    fallback_text = ''
    if isinstance(c.get('data'), list) and c['data'] and isinstance(c['data'][0], dict):
        fallback_text = c['data'][0].get('value', '') or fallback_text
    body_text = (opt.get('body') or {}).get('text', '')
    if misplaced or body_misplaced or fallback_text or body_text:
        wrong_paths = []
        if misplaced:      wrong_paths.append(f'option.{list(misplaced)}')
        if body_misplaced: wrong_paths.append(f'option.body.{list(body_misplaced)}')
        if fallback_text:  wrong_paths.append('data[0].value')
        if body_text:      wrong_paths.append('option.body.text')
        print(f'[spec_builder] JText "{c.get("name", c.get("title", ""))}" — '
              f'写在 {wrong_paths} 的字段已自动迁移到 spec 顶级。'
              f'正确写法：spec 顶级写 text/title 与 color/fontSize/fontWeight/align/letterSpacing。')
        for k, v in misplaced.items():
            c.setdefault('align' if k == 'textAlign' else k, v)
        for k, v in body_misplaced.items():
            c.setdefault('align' if k == 'textAlign' else k, v)
        if fallback_text and not c.get('text') and not c.get('title'):
            c['text'] = fallback_text
        if body_text and not c.get('text') and not c.get('title'):
            c['text'] = body_text
    text = c.get('text', c.get('title', ''))
    style = c.get('style', 'label')
    size_map  = {'title': 40, 'subtitle': 22, 'label': 14, 'value': 28}
    color_map = {'title': p['title'], 'subtitle': p['subtitle'],
                 'label': p['label'], 'value': p['value']}
    body = {
        'text':       text,
        'color':      c.get('color', color_map.get(style, p['label'])),
        'fontSize':   c.get('fontSize', size_map.get(style, 14)),
        'fontWeight': c.get('fontWeight', 'bold' if style in ('title', 'value') else 'normal'),
        'textAlign':  c.get('align', 'center'),
    }
    if 'letterSpacing' in c:
        body['letterSpacing'] = c['letterSpacing']
    if 'fontStyle' in c:    body['fontStyle']  = c['fontStyle']
    if 'fontFamily' in c:   body['fontFamily'] = c['fontFamily']
    return 'JText', {'chartData': {'value': text}, 'option': {'body': body}}


def handle_JDragDecoration(c, p):
    return 'JDragDecoration', {'option': {
        'type':      str(c.get('variant', '1')),
        'mainColor': c.get('color', p['subtitle']),
        'subColor':  c.get('subColor', c.get('color', p['subtitle'])),
        'dur':       c.get('dur', 3),
    }}


def handle_JDragBorder(c, p):
    d = load_def('JDragBorder')
    opt = d['option']
    opt['type'] = str(c.get('variant', '1'))
    if 'color' in c:
        opt['mainColor'] = c['color']
        opt['subColor'] = c.get('subColor', c['color'])
    else:
        if 'mainColor' in c: opt['mainColor'] = c['mainColor']
        if 'subColor' in c:  opt['subColor'] = c['subColor']
    if 'title' in c:           opt['title'] = c['title']
    if 'titleWidth' in c:      opt['titleWidth'] = c['titleWidth']
    if 'backgroundColor' in c: opt['backgroundColor'] = c['backgroundColor']
    if 'reverse' in c:         opt['reverse'] = c['reverse']
    if 'dur' in c:             opt['dur'] = c['dur']
    return 'JDragBorder', {'option': opt}


def handle_JScrollList(c, p):
    """
    JScrollList passthrough 修正：AI 写的 option.fieldMapping[*] 通常只有 {name, key, width}，
    会整体覆盖 defaults 里的同名数组——丢失默认 textAlign:'center' 与 textStyle.fontColor:'#FFFFFF'，
    导致内容文字非白 + 与表头居中不对齐（实测 2026-04-27）。
    这里给每项补两个兜底字段；AI 显式写过则尊重原值。

    字段名防呆（实测 2026-04-28）：AI 易按 Vue/React/antd 习惯写错三个字段——
      · fieldMapping[*].label → 平台真实字段是 name（写错→表头列名空白）
      · option.header.color   → 平台真实字段是 fontColor（写错→表头字色失效）
      · fieldMapping[*].textStyle.color → 同上 fontColor（每列单元格字色）
    检测到这三种写法时自动转换并打印警告，让组件能正常渲染。

    width 防呆（实测 2026-05-13）：fieldMapping[*].width 是**数字像素**（不是百分比字符串）。
    平台规则：
      · width > 0 → 该列固定为 N 像素
      · width = 0 → 该列自动填充剩余宽度（其他列定宽后均分剩余空间）
      · 所有列 width 全 0 → 按列数均分容器宽度
    AI 易按 Bootstrap/Antd 习惯写 "50%"/"25%" → 平台只认数字，字符串被识别为无效后 fallback 0，
    若仅一列写百分比 + 其他列定宽，会得到意外的"自动列吞掉剩余宽度"效果。
    自动修正：检测字符串 width → 改为 0（自动均分），并打印警告。
    """
    variant = str(c.get('variant', '')).strip()
    cand = f'JScrollList_{variant}' if variant else 'JScrollList'
    if not os.path.exists(os.path.join(DEFAULTS_DIR, cand + '.json')):
        cand = 'JScrollList'
    cfg = load_def(cand)
    if 'data' in c:
        cfg['chartData'] = json.dumps(c['data'], ensure_ascii=False) \
            if not isinstance(c['data'], str) else c['data']
    if 'option' in c:
        cfg.setdefault('option', {}).update(c['option'])
    opt = cfg.setdefault('option', {})
    name_alias_hits = []
    color_alias_hits = []
    width_str_hits = []
    cols = opt.get('fieldMapping') or []
    for idx, col in enumerate(cols):
        if not isinstance(col, dict):
            continue
        if 'label' in col and 'name' not in col:
            col['name'] = col.pop('label')
            name_alias_hits.append(idx)
        w = col.get('width')
        if isinstance(w, str):
            width_str_hits.append(f'fieldMapping[{idx}].width="{w}"')
            col['width'] = 0
        col.setdefault('textAlign', 'center')
        ts = col.setdefault('textStyle', {})
        if 'color' in ts and 'fontColor' not in ts:
            ts['fontColor'] = ts.pop('color')
            color_alias_hits.append(f'fieldMapping[{idx}].textStyle')
        if not ts.get('fontColor'):
            ts['fontColor'] = '#FFFFFF'
    header = opt.get('header')
    if isinstance(header, dict) and 'color' in header and 'fontColor' not in header:
        header['fontColor'] = header.pop('color')
        color_alias_hits.append('option.header')
    if name_alias_hits:
        print(f'⚠️ JScrollList 字段名兼容：fieldMapping[{name_alias_hits}].label 已自动改写为 name '
              f'（平台真实字段是 name，参考 references/scroll-list-option-config.md）')
    if color_alias_hits:
        print(f'⚠️ JScrollList 字段名兼容：{color_alias_hits} 中 color 已自动改写为 fontColor '
              f'（平台真实字段是 fontColor）')
    if width_str_hits:
        print(f'⚠️ JScrollList 防呆：{width_str_hits} 是字符串/百分比无效，已改为 0（自动填充剩余宽度）；'
              f'width 是数字像素，0=自动填充，全 0=均分。参考 references/scroll-list-option-config.md')
    if 'commonOption' in c:
        cfg.setdefault('commonOption', {}).update(c['commonOption'])
    return cand, cfg


def handle_JScrollTable(c, p):
    """
    JScrollTable passthrough 修正（实测 2026-05-12）：

    AI 易踩四个坑（参考 comp-group-tables.md §JScrollTable 与 §踩坑 #160）：
      · fieldMapping[*].width 写成 "40%" 等百分比字符串 → 平台只认数字像素，
        百分比会被识别为无效后 fallback 默认 0，多列时一起塌缩看着像列错位
        自动修正：检测字符串 width → 改为 0（自动均分），并打印警告
      · fieldMapping[*].fontColor → JScrollTable 没有按列字色字段，全表只有
        option.bodyFontColor。AI 常按 JScrollList 习惯写每列 fontColor → 静默失效
        自动修正：删除每列 fontColor，并打印警告引导改写 option.bodyFontColor
      · oddColor / evenColor / borderColor 写带 alpha 的 #RRGGBBAA →
        斑马纹/边框近乎透明，表格看着像没条纹/无边框
        检测到 8 位带 alpha → 打印警告（不强改，留给用户决定）
      · scrollTime 写非 50 的值 → 前端 Vue 组件硬编码 50ms 间隔，写其它值无效
        打印 info 提示一次，不改值（不影响渲染）
    """
    cfg = load_def('JScrollTable')
    if 'data' in c:
        cfg['chartData'] = c['data']  # passthrough：list 直接挂 chartData（无需 json.dumps）
    if 'option' in c:
        cfg.setdefault('option', {}).update(c['option'])
    opt = cfg.setdefault('option', {})

    width_str_hits = []
    fontcolor_hits = []
    cols = opt.get('fieldMapping') or []
    for idx, col in enumerate(cols):
        if not isinstance(col, dict):
            continue
        # width 字符串 → 0（自动均分）
        w = col.get('width')
        if isinstance(w, str):
            width_str_hits.append(f'fieldMapping[{idx}].width="{w}"')
            col['width'] = 0
        # 删按列 fontColor（JScrollTable 不支持）
        if 'fontColor' in col:
            fontcolor_hits.append(f'fieldMapping[{idx}].fontColor')
            col.pop('fontColor', None)

    # alpha 颜色警告（不强改）
    def _has_alpha(v):
        return isinstance(v, str) and v.startswith('#') and len(v) == 9
    alpha_hits = [k for k in ('oddColor', 'evenColor', 'borderColor') if _has_alpha(opt.get(k))]

    if width_str_hits:
        print(f'⚠️ JScrollTable 防呆：{width_str_hits} 是百分比字符串无效，已改为 0（自动均分）；'
              f'固定列宽请用整数像素如 120，让 1 列用 0 自动撑满剩余空间')
    if fontcolor_hits:
        print(f'⚠️ JScrollTable 防呆：{fontcolor_hits} 不支持按列字色，已删除；'
              f'需要全表字色请写 option.bodyFontColor')
    if alpha_hits:
        print(f'⚠️ JScrollTable 提醒：{alpha_hits} 用了 8 位 #RRGGBBAA 颜色（带 alpha 透明），'
              f'会让斑马纹/边框近乎不可见。建议用不透明 #RRGGBB（如 oddColor=#0a2540 / evenColor=#0e3052 / borderColor=#1890ff）')
    if 'scrollTime' in opt and opt['scrollTime'] != 50:
        print(f'ℹ️ JScrollTable 说明：scrollTime={opt["scrollTime"]} 不生效——前端硬编码 50ms 滚动间隔（实测 2026-04-27）')

    if 'commonOption' in c:
        cfg.setdefault('commonOption', {}).update(c['commonOption'])
    return 'JScrollTable', cfg


def handle_JStatsSummary(c, p):
    variant = str(c.get('variant', '1'))
    d = load_def(f'JStatsSummary_{variant}')
    data = []
    for i, it in enumerate(c['data']):
        up = it.get('up')
        if up is None:
            cs = it.get('compareState', '1')
            up = (cs in (1, '1', True))
        data.append({
            'id':           str(i + 1),
            'name':         it['name'],
            'value':        it['value'],
            'suffix':       it.get('suffix', it.get('unit', '')),
            'compareLabel': it.get('compareLabel', '环比'),
            'compareValue': it.get('compareValue', ''),
            'compareState': '1' if up else '0',
        })
    d['chartData'] = json.dumps(data, ensure_ascii=False)
    # showCompare=false 隐藏中部同比/环比区域（option.sections.middle.show）
    if c.get('showCompare') is False:
        d.setdefault('option', {}).setdefault('sections', {}).setdefault('middle', {})['show'] = False

    # 变体 2/3 默认 layout.fill.type=image 但 image.url 为空 → 平台回退到纯色，看起来"没背景"
    # 自动填充平台内置素材 drag/lib/img/bg01.png（变体 2 用 layout 整层底图，变体 3 用 card 单卡片底图）
    # 用户可通过 spec 顶层 bgImageUrl 字段或 option.layout.fill.image.url / option.card.fill.image.url 覆盖
    if variant in ('2', '3'):
        DEFAULT_BG = c.get('bgImageUrl', 'drag/lib/img/bg01.png')
        target_section = 'layout' if variant == '2' else 'card'
        sec = d.setdefault('option', {}).setdefault(target_section, {})
        fill = sec.setdefault('fill', {})
        img = fill.setdefault('image', {})
        # 仅当用户未提供 url 时填默认值
        if not img.get('url'):
            img['url'] = DEFAULT_BG
            img.setdefault('size', '100% 100%')
            img.setdefault('repeat', 'no-repeat')
            img.setdefault('position', 'center')
        # 确保 fill.type=image（用户显式改 type=color/gradient 时不覆盖）
        if fill.get('type') not in ('color', 'gradient'):
            fill['type'] = 'image'

    # 折行高度回写：根据指标数量和组件宽度推算实际渲染行数，将 pos[3]（h）更新为正确值
    # 避免折行后下方组件被压盖（JStatsSummary 高度由 CSS 撑起，不受 h 字段控制，
    # 但 h 正确有助于 spec 后续组件的 y 坐标计算与布局检查）
    pos = c.get('pos')
    if pos and len(pos) >= 4:
        w = pos[2]
        n = len(data)
        show_cmp = c.get('showCompare', True)
        row_h    = 153 if show_cmp is False else 180
        MIN_CARD_W = 200
        cols = max(1, w // MIN_CARD_W) if w > 0 else n
        cols = min(cols, n) if n > 0 else cols
        rows = (n + cols - 1) // cols if cols else 1
        eff_h = rows * row_h
        if pos[3] != eff_h:
            pos[3] = eff_h   # 原地修正，build 循环会用 pos 写入 x/y/w/h

    return f'JStatsSummary_{variant}', d


def handle_JRingProgress(c, p):
    d = load_def('JRingProgress')
    d['chartData'] = json.dumps(
        [{'name': c.get('title', ''), 'value': c['value']}],
        ensure_ascii=False,
    )
    d['option'].update({
        'color':           c.get('color', p['subtitle']),
        'bgColor':         c.get('bgColor', '#1a3a5a'),
        'radius':          c.get('radius', 0.85),
        'innerRadius':     c.get('innerRadius', 0.85),
        'fontColor':       c.get('fontColor', p['axis']),
        'fontSize':        c.get('fontSize', 14),
        'fontWeight':      'normal',
        'lineHeight':      c.get('lineHeight', 24),
        'valueFontColor':  c.get('valueColor', p['title']),
        'valueFontSize':   c.get('valueFontSize', 22),
        'valueFontWeight': 'bold',
    })
    return 'JRingProgress', d


def handle_JScrollRankingBoard(c, p):
    d = load_def('JScrollRankingBoard')
    # chartData: [{name, value}] — auto sort desc
    d['chartData'] = json.dumps(c['data'], ensure_ascii=False)
    # option.color 必须是单色字符串（进度条颜色），传 list 会让 ECharts 报
    # "Color: Invalid Input of #a,#b" → 兼容旧 spec 传 list 时取首色
    _rk_color = c.get('color', p['subtitle'])
    if isinstance(_rk_color, (list, tuple)):
        _rk_color = _rk_color[0] if _rk_color else p['subtitle']
    d['option'].update({
        'rowNum':    c.get('rowNum', 10),
        'waitTime':  c.get('waitTime', 2000),
        'carousel':  c.get('carousel', 'single'),
        'sort':      c.get('sort', True),
        'fontSize':  c.get('fontSize', 14),
        'color':     _rk_color,
        'textColor': c.get('textColor', p['label']),
    })
    return 'JScrollRankingBoard', d


def handle_JColorGauge(c, p):
    d = load_def('JColorGauge')
    d['chartData'] = json.dumps(
        [{'name': c.get('name', c.get('title', '')), 'value': c['value']}],
        ensure_ascii=False,
    )
    # JColorGauge defaults already have a 3-color axisLine; allow override via `segments`.
    # segments: [[frac, color], ...] e.g. [[0.3, "#ff6b6b"], [0.7, "#ffa726"], [1, "#7ee8a2"]]
    if 'segments' in c:
        series = d['option'].setdefault('series', [{}])
        for s in series:
            s.setdefault('axisLine', {}).setdefault('lineStyle', {})['color'] = c['segments']
    if 'title' in c:
        d['option'].setdefault('title', {}).update({
            'show': True, 'text': c['title'],
            'textStyle': {'color': p['subtitle'], 'fontSize': 13},
        })
    return 'JColorGauge', d


def handle_JScrollBoard(c, p):
    d = load_def('JScrollBoard')
    d['chartData'] = json.dumps(c['rows'], ensure_ascii=False)
    headers = [{'label': col['label'], 'key': col.get('key', ''),
                'width': col.get('width', 100)} for col in c['columns']]
    d['option'].update({
        'header':       headers,
        'headShow':     c.get('headShow', True),
        'index':        c.get('index', False),
        'headerBGC':    c.get('headerBg', '#0a2a4a'),
        'headerHeight': c.get('headerHeight', 38),
        'oddRowBGC':    c.get('oddRowBg',  '#0d2640aa'),
        'evenRowBGC':   c.get('evenRowBg', '#071829aa'),
        'rowNum':       c.get('rowNum', 8),
        'waitTime':     c.get('waitTime', 2000),
        'align':        c.get('align', ['center'] * len(headers)),
    })
    return 'JScrollBoard', d


def handle_JListProgress(c, p):
    d = load_def('JListProgress')
    # Simplified schema: [{title, current, target, label, date}] → defaults [{title, value, total, endLabel, date}]
    rows = []
    for it in c['data']:
        rows.append({
            'title':    it.get('title', ''),
            'value':    it.get('current', it.get('value', 0)),
            'total':    it.get('target',  it.get('total', 100)),
            'endLabel': it.get('label',   it.get('endLabel', '')),
            'date':     it.get('date',    ''),
        })
    d['chartData'] = json.dumps(rows, ensure_ascii=False)
    # Apply dark theme defaults only; user can override via `option`.
    d['option'].setdefault('body', {}).update({'color': c.get('textColor', p['value']), 'fontSize': c.get('fontSize', 16)})
    d['option'].setdefault('bar',  {}).update({'background': '#1a3a5a', 'color': c.get('color', p['subtitle']),
                                                'height': c.get('barHeight', 12), 'radius': 6})
    d['option'].setdefault('beginInfo',     {}).update({'color': p['label'],    'fontSize': 16, 'fontWeight': 'bold'})
    d['option'].setdefault('centerTopInfo', {}).update({'color': p['title'],    'fontSize': 20, 'fontWeight': 'bold'})
    d['option'].setdefault('endInfo',       {}).update({'color': '#7ee8a2',     'fontSize': 16})
    d['option'].setdefault('row', {}).update({'height': c.get('rowHeight', 90), 'padding': 12})
    if 'option' in c:
        _deep_update(d['option'], c['option'])
    return 'JListProgress', d


def handle_JFlyLineMap(c, p):
    d = load_def('JFlyLineMap')
    # Simplified schema: [{from, to, value}] with city name lookup; or raw {fromName, fromLng, ...}.
    rows = []
    for it in c['data']:
        if 'from' in it and 'to' in it:
            fc = CITY_COORDS.get(it['from']);  tc = CITY_COORDS.get(it['to'])
            if not fc or not tc:
                raise ValueError(f"Unknown city in JFlyLineMap: {it}")
            rows.append({
                'fromName': it['from'], 'toName': it['to'],
                'fromLng': fc[0], 'fromLat': fc[1],
                'toLng':   tc[0], 'toLat':   tc[1],
                'value':   it.get('value', 1),
            })
        else:
            rows.append(it)   # raw fromLng/fromLat/... pass through
    d['chartData'] = json.dumps(rows, ensure_ascii=False)
    if c.get('title'):
        d['option'].setdefault('title', {}).update({
            'show': True, 'text': c['title'],
            'textStyle': {'color': p['subtitle'], 'fontSize': 13},
        })
    d.setdefault('commonOption', {}).setdefault('effect', {}).update({
        'trailLength': c.get('trailLength', 0.2),
        'symbolSize':  c.get('symbolSize', 6),
        'color':       c.get('effectColor', p['title']),
    })
    if 'option' in c:        _deep_update(d['option'], c['option'])
    if 'commonOption' in c:  _deep_update(d['commonOption'], c['commonOption'])
    return 'JFlyLineMap', d


def _handle_map_simple(comp_type, c, p):
    d = load_def(comp_type)
    if 'data' in c:
        d['chartData'] = json.dumps(c['data'], ensure_ascii=False)
    # else: 保留 defaults 的内置 chartData（演示用）
    if c.get('title'):
        d['option'].setdefault('title', {}).update({
            'show': True, 'text': c['title'],
            'textStyle': {'color': p['subtitle'], 'fontSize': 13},
        })
    if 'option' in c:       _deep_update(d['option'], c['option'])
    if 'commonOption' in c: _deep_update(d.setdefault('commonOption', {}), c['commonOption'])
    return comp_type, d


def handle_JAreaMap(c, p):   return _handle_map_simple('JAreaMap',   c, p)
def handle_JBubbleMap(c, p): return _handle_map_simple('JBubbleMap', c, p)
def handle_JBarMap(c, p):    return _handle_map_simple('JBarMap',    c, p)


def handle_JCountTo(c, p):
    d = load_def('JCountTo')
    d['chartData'] = {'value': c['value']}
    d['option'].update({
        'whole':      c.get('whole', True),
        'fontSize':   c.get('fontSize', 48),
        'color':      c.get('color', p['title']),
        'fontWeight': c.get('fontWeight', 'bold'),
        'textAlign':  c.get('align', 'center'),
    })
    if 'prefix' in c: d['option']['prefix'] = c['prefix']
    if 'suffix' in c: d['option']['suffix'] = c['suffix']
    return 'JCountTo', d


def handle_JNumber(c, p):
    d = load_def('JNumber')
    d['chartData'] = {'value': c['value']}
    d['option'].setdefault('body', {}).update({
        'color':      c.get('color', p['value']),
        'fontSize':   c.get('fontSize', 28),
        'fontWeight': c.get('fontWeight', 'bold'),
        'textAlign':  c.get('align', 'center'),
    })
    if 'prefix' in c: d['option']['body']['prefix'] = c['prefix']
    if 'suffix' in c: d['option']['body']['suffix'] = c['suffix']
    return 'JNumber', d


def handle_JCapsuleChart(c, p):
    d = load_def('JCapsuleChart')
    d['chartData'] = json.dumps(c['data'], ensure_ascii=False)
    d['option'].update({
        'showValue': c.get('showValue', True),
        'unit':      c.get('unit', ''),
    })
    if 'colors' in c:
        d['option']['customColor'] = [{'color1': col, 'color': col} for col in c['colors']]
    if c.get('title'):
        d['option'].setdefault('title', {}).update({
            'show': True, 'text': c['title'],
            'textStyle': {'color': p['subtitle'], 'fontSize': 13},
        })
    return 'JCapsuleChart', d


def handle_JSemiGauge(c, p):
    d = load_def('JSemiGauge')
    # Accept either {total,used} (raw defaults schema) or {value, max} (friendly)
    it = c.get('data') or {}
    if 'value' in c:
        it = {'used': c['value'], 'total': c.get('max', 100)}
    elif isinstance(it, list):
        it = it[0]
    d['chartData'] = json.dumps([{'total': it.get('total', it.get('max', 100)),
                                   'used':  it.get('used',  it.get('value', 0))}],
                                 ensure_ascii=False)
    if 'titlePrefix' in c: d['option']['titlePrefix'] = c['titlePrefix']
    if 'titleSuffix' in c: d['option']['titleSuffix'] = c['titleSuffix']
    if 'valuePrefix' in c: d['option']['valuePrefix'] = c['valuePrefix']
    if 'valueSuffix' in c: d['option']['valueSuffix'] = c['valueSuffix']
    return 'JSemiGauge', d


def handle_JGauge(c, p):
    d = load_def('JGauge')
    d['chartData'] = json.dumps(
        [{'name': c.get('name', c.get('title', '')),
          'value': c['value'], 'max': c.get('max', 100)}],
        ensure_ascii=False,
    )
    if c.get('title'):
        d['option'].setdefault('title', {}).update({
            'show': True, 'text': c['title'],
            'textStyle': {'color': p['subtitle'], 'fontSize': 13},
        })
    if 'option' in c:
        _deep_update(d['option'], c['option'])
    return 'JGauge', d


def handle_JAntvGauge(c, p):
    d = load_def('JAntvGauge')
    val = c['value']
    # 防御式告警：value 是 0-100 数字（78 表示 78%），传 0-1 小数会被当成 <1% 渲染
    if isinstance(val, (int, float)) and 0 < val < 1:
        print(f'⚠️ JAntvGauge value={val} 可能是 0-1 比例误用：本组件 value 为 0-100 整数，'
              f'如想表示 {val*100:.0f}% 请传 {val*100:.0f}')
    d['chartData'] = json.dumps(
        [{'label': c.get('label', c.get('title', '')), 'value': val}],
        ensure_ascii=False,
    )
    d['option'].update({
        'colorType':      c.get('colorType', 'gradient'),
        'valueColor':     c.get('valueColor', p['title']),
        'valueFontSize':  c.get('valueFontSize', 36),
        'axisLabelColor': c.get('axisLabelColor', p['axis']),
        'indicatorColor': c.get('indicatorColor', p['subtitle']),
    })
    if 'colors' in c: d['option']['colors'] = c['colors']
    if c.get('title'):
        d['option'].setdefault('title', {}).update({
            'show': True, 'text': c['title'],
            'textStyle': {'color': p['subtitle'], 'fontSize': 13},
        })
    return 'JAntvGauge', d


def handle_JLiquid(c, p):
    d = load_def('JLiquid')
    d['chartData'] = json.dumps([{'value': c['value']}], ensure_ascii=False)
    d['option'].update({
        'liquidType':  c.get('liquidType', 'circle'),
        'color':       c.get('color', p['subtitle']),
        'borderColor': c.get('borderColor', p['subtitle']),
        'textColor':   c.get('textColor', p['label']),
        'textFontSize': c.get('textFontSize', 28),
    })
    if c.get('title'):
        d['option'].setdefault('title', {}).update({
            'show': True, 'text': c['title'],
            'textStyle': {'color': p['subtitle'], 'fontSize': 13},
        })
    return 'JLiquid', d


def _deep_update(dst, src):
    for k, v in src.items():
        if isinstance(v, dict) and isinstance(dst.get(k), dict):
            _deep_update(dst[k], v)
        else:
            dst[k] = v


def _apply_series_shortcuts(opt, c, p, *, chart_type):
    # 若 defaults.series 留空（如 JBubble / JQuadrant / JStackBar / JMultipleBar 等），
    # 平台前端会按 componentName 自行推断渲染（散点 / 多柱 / 堆叠等）；
    # 此处注入 [{type:'bar'}] 会强制柱形，破坏散点等非柱形组件。
    # 仅在用户显式给出 series 级覆盖（barWidth/smooth/gradient/color）时才追加。
    if not opt.get('series'):
        if not any(k in c for k in ('barWidth', 'smooth', 'gradient', 'color')):
            return
        opt['series'] = [{}]
    s = opt['series'][0]
    s.setdefault('type', chart_type)
    if 'barWidth' in c:
        s['barWidth'] = c['barWidth']
    if 'smooth' in c:
        s['smooth'] = c['smooth']
    if 'gradient' in c:
        g = _gradient(*c['gradient'])
        if chart_type == 'bar':
            s.setdefault('itemStyle', {})['color'] = g
    if 'color' in c:
        col = c['color']
        if chart_type == 'line':
            s.setdefault('lineStyle', {}).setdefault('color', col)
            s.setdefault('itemStyle', {}).setdefault('color', col)
            opt['customColor'] = [{'color1': col, 'color': col}]
        elif chart_type == 'bar' and 'gradient' not in c:
            s.setdefault('itemStyle', {}).setdefault('color', col)


def handle_cartesian(c, p, comp_type):
    d = load_def(comp_type)
    d['chartData'] = json.dumps(c['data'], ensure_ascii=False)
    opt = d['option']
    if comp_type in ('JLine', 'JSmoothLine', 'JStepLine', 'JArea', 'JMultipleLine'):
        chart_type = 'line'
    elif comp_type in ('JScatter', 'JBubble', 'JQuadrant'):
        chart_type = 'scatter'
    else:
        chart_type = 'bar'
    _apply_echarts_theme(opt, p, has_axes=True, title_text=c.get('title'))
    _apply_series_shortcuts(opt, c, p, chart_type=chart_type)
    # 散点家族 x 轴默认隐藏纵向网格（JScatter / JBubble defaults 未显式设置，
    # ECharts 'value' 轴 splitLine 默认 show=true，会与平台原生拖拽渲染不一致）。
    if comp_type in ('JScatter', 'JBubble'):
        xa = opt.setdefault('xAxis', {})
        if isinstance(xa, dict):
            xa.setdefault('splitLine', {}).setdefault('show', False)

    if comp_type == 'JArea':
        col = c.get('color', p['subtitle'])
        s = opt['series'][0]
        as_ = s.get('areaStyle') or {}
        if not as_.get('color'):
            as_['color'] = _gradient('v', col + '60', col + '10')
        s['areaStyle'] = as_
        s.setdefault('lineStyle', {}).setdefault('color', col)
        s.setdefault('itemStyle', {}).setdefault('color', col)
        s['smooth'] = c.get('smooth', True)

    # Multi-series color palette (JMultipleLine / JMultipleBar / JStackBar, etc).
    if 'colors' in c:
        opt['customColor'] = [{'color1': col, 'color': col} for col in c['colors']]

    if 'yAxis' in c:
        y = opt.setdefault('yAxis', {})
        yo = c['yAxis']
        for k in ('min', 'max', 'type'):
            if k in yo:
                y[k] = yo[k]
        if 'formatter' in yo:
            y.setdefault('axisLabel', {})['formatter'] = yo['formatter']
    if 'xAxis' in c:
        xa = opt.setdefault('xAxis', {})
        xo = c['xAxis']
        if 'type' in xo:
            xa['type'] = xo['type']
        if 'interval' in xo or 'formatter' in xo or 'rotate' in xo:
            xa.setdefault('axisLabel', {}).update(
                {k: v for k, v in xo.items() if k in ('interval', 'formatter', 'rotate')}
            )
    # Allow spec-level option overrides (mirrors handle_polar behavior)
    if 'option' in c:
        _deep_update(opt, c['option'])
    return comp_type, d


def handle_polar(c, p, comp_type):
    d = load_def(comp_type)
    d['chartData'] = json.dumps(c['data'], ensure_ascii=False)
    opt = d['option']
    _apply_echarts_theme(opt, p, has_axes=False, title_text=c.get('title'))
    # Pitfall guard: pie family must NOT have xAxis/yAxis
    opt.pop('xAxis', None)
    opt.pop('yAxis', None)
    if 'colors' in c:
        opt['customColor'] = [{'color1': col, 'color': col} for col in c['colors']]

    # 自动布局：饼/环类组件根据容器尺寸决定 legend 方向和 series center，
    # 避免横排 legend 把图挤出容器底部被 overflow:hidden 裁掉。
    # JRadar / JFunnel 等不受此规则影响。
    PIE_RING_TYPES = {'JPie', 'JRose', 'JRotatePie', 'JRing', 'JBreakRing', 'JActiveRing'}
    if comp_type in PIE_RING_TYPES:
        pos = c.get('pos') or [0, 0, 480, 300]
        w, h = pos[2], pos[3]
        series = opt.setdefault('series', [{}])
        if not series:
            series = [{}]
            opt['series'] = series
        s0 = series[0]

        if h < 260:
            # 短容器（h<260）：legend 竖排到右侧，避免与标题/图表重叠
            opt['legend'] = {
                'orient':    'vertical',
                'right':     '2%',
                'top':       'middle',
                'left':      'auto',
                'itemGap':   8,
                'itemWidth': 10,
                'itemHeight':10,
            }
            # 钳制 radius 防止 overflow:hidden 裁图（实测 2026-04-28）
            # center_y ≈ h*0.55，可用最大半径 = center_y - 标题高(≈32px) - 底部缓冲(5px)
            max_r_px = max(20, int(h * 0.55) - 37)
            if comp_type in {'JRing', 'JBreakRing', 'JActiveRing'}:
                # ring.vue 用 option.outRadius/innerRadius（像素值）决定渲染半径
                # series[0].radius/center 在 ring.vue 被覆盖 → 不写；但必须保留 type:"pie"，否则 ECharts 不渲染
                opt.setdefault('outRadius', max_r_px)
                opt.setdefault('innerRadius', max(10, int(max_r_px * 0.55)))
                # ring.vue: center = [(grid.left||50)%, (grid.top||50)%]，图例右置时环心左移
                g = opt.setdefault('grid', {})
                g.setdefault('left', 38)
                g.setdefault('top', 50)
                # ECharts 必须有 type:"pie" 才能渲染环形，merge 时补入 chartOption.series
                series = opt.setdefault('series', [{}])
                if not series:
                    series = [{}]
                    opt['series'] = series
                series[0].setdefault('type', 'pie')
                series[0].setdefault('label', {'show': False, 'position': 'center'})
                series[0].setdefault('labelLine', {'show': False})
            else:  # JPie / JRose / JRotatePie
                s0.setdefault('center', ['36%', '55%'])
                s0.setdefault('radius', ['0', f'{max_r_px}px'])
        else:
            # 正常容器：legend 横排在底部，图/环心略上移留空间
            if comp_type not in {'JRing', 'JBreakRing', 'JActiveRing'}:
                opt['legend'] = opt.get('legend', {})
                opt['legend'].setdefault('orient', 'horizontal')
                opt['legend'].setdefault('bottom', '5%')
                s0.setdefault('center', ['50%', '46%'])
            if comp_type in {'JRing', 'JBreakRing', 'JActiveRing'}:
                # 正常容器：out_r ≈ h*0.35 为安全值，留底部图例约 30px 不重叠
                out_r = max(30, int(h * 0.35))
                opt.setdefault('outRadius', out_r)
                opt.setdefault('innerRadius', max(15, int(out_r * 0.6)))
                g = opt.setdefault('grid', {})
                g.setdefault('left', 50)
                g.setdefault('top', 46)
                series = opt.setdefault('series', [{}])
                if not series:
                    series = [{}]
                    opt['series'] = series
                series[0].setdefault('type', 'pie')
                series[0].setdefault('label', {'show': False, 'position': 'center'})
                series[0].setdefault('labelLine', {'show': False})

    # 允许 spec 里的 option 字段覆盖上面的计算结果（用户显式写的优先）
    if 'option' in c:
        _deep_update(opt, c['option'])

    return comp_type, d


SPECIAL_HANDLERS = {
    'JText':               handle_JText,
    'JDragDecoration':     handle_JDragDecoration,
    'JDragBorder':         handle_JDragBorder,
    'JStatsSummary':       handle_JStatsSummary,
    'JRingProgress':       handle_JRingProgress,
    'JScrollBoard':        handle_JScrollBoard,
    'JScrollRankingBoard': handle_JScrollRankingBoard,
    'JColorGauge':         handle_JColorGauge,
    'JListProgress':       handle_JListProgress,
    'JFlyLineMap':         handle_JFlyLineMap,
    'JAreaMap':            handle_JAreaMap,
    'JBubbleMap':          handle_JBubbleMap,
    'JBarMap':             handle_JBarMap,
    'JCountTo':            handle_JCountTo,
    'JNumber':             handle_JNumber,
    'JCapsuleChart':       handle_JCapsuleChart,
    'JSemiGauge':          handle_JSemiGauge,
    'JGauge':              handle_JGauge,
    'JAntvGauge':          handle_JAntvGauge,
    'JLiquid':             handle_JLiquid,
    'JScrollList':         handle_JScrollList,
    'JScrollTable':        handle_JScrollTable,
}


def compile_component(c, palette):
    t = c['type']
    if t in DISABLED_COMPONENTS:
        raise ValueError(
            f'组件 {t} 在大屏（bigScreen）中不受支持、无法渲染，已禁用。'
            f'请选择其他组件替代：'
            f'JRankingList→JScrollRankingBoard；'
            f'JTotalProgress→JListProgress / JCapsuleChart；'
            f'JPivotTable→JScrollBoard / JCommonTable；'
            f'JFly3dMap→JFlyLineMap / JTotalFlyLineMap。'
        )

    # 布局约束预警（首次做对率优化）—— 只提示不阻断
    pos = c.get('pos') or [0, 0, 0, 0]
    if len(pos) >= 4:
        w, h = pos[2], pos[3]
        if t in ECHARTS_POLAR and h < 220:
            print(f'⚠️ {t} "{c.get("title","")}" h={h}<220，饼/环图 legend 与 title 易重叠；'
                  f'短宽格建议改 JHorizontalBar / JCapsuleChart / JListProgress')
        if t == 'JStatsSummary':
            _n_stats  = len(c.get('data', []))
            _show_cmp = c.get('showCompare', True)
            _row_h    = 153 if _show_cmp is False else 180
            _MIN_W    = 200   # 每个 KPI 卡片最小宽度（实测约 200-280px）
            _cols     = max(1, w // _MIN_W) if w > 0 else _n_stats
            _cols     = min(_cols, _n_stats) if _n_stats > 0 else _cols
            _rows     = (_n_stats + _cols - 1) // _cols if _cols else 1
            _eff_h    = _rows * _row_h
            if h < _eff_h:
                _label = c.get('title') or c.get('name', '')
                _y     = pos[1]
                print(f'⚠️  JStatsSummary "{_label}": {_n_stats}项 w={w}px → '
                      f'估算折 {_rows} 行×{_cols} 列，实际渲染高约 {_eff_h}px'
                      f'（spec h={h}）。'
                      f'下方组件 y 建议 ≥ {_y + _eff_h + 10}，'
                      f'或将 spec h 改为 {_eff_h}')
        if t == 'JColorBlock':
            # 24 栅格强约束（colorBlock.vue:122-124 `span = ceil(24/lineNum)`）：
            # 数据项数必须能整除 24 才视觉饱满；否则折行错位（5 项→4+1、7 项→6+1）。
            # 实用 KPI 行项数 ∈ {2,3,4,6,8}（4-6 最佳），其余建议改 JStatsSummary。
            _n_blocks = len(c.get('data', []))
            _GRID_OK  = {1, 2, 3, 4, 6, 8, 12, 24}
            if _n_blocks > 0 and _n_blocks not in _GRID_OK:
                _label    = c.get('title') or c.get('name', '')
                _line_num = (c.get('option') or {}).get('lineNum', _n_blocks)
                _span     = -(-24 // _line_num) if _line_num else 0  # ceil(24/lineNum)
                _per_row  = 24 // _span if _span else 0
                _wrap     = f'{_per_row}+{_n_blocks - _per_row}' if _per_row and _n_blocks > _per_row else f'{_n_blocks}'
                print(f'⚠️  JColorBlock "{_label}": {_n_blocks} 项不能整除 24（实际折成 {_wrap}，'
                      f'lineNum={_line_num} → span={_span}）→ 视觉错位。'
                      f'KPI 行实用项数 ∈ {{2,3,4,6,8}}（4-6 最佳）；'
                      f'当前项数请改用 JStatsSummary（任意项数都正常排版）')

    if t in SPECIAL_HANDLERS:
        comp_key, cfg = SPECIAL_HANDLERS[t](c, palette)
    elif t in ECHARTS_CARTESIAN:
        comp_key, cfg = handle_cartesian(c, palette, t)
    elif t in ECHARTS_POLAR:
        comp_key, cfg = handle_polar(c, palette, t)
    else:
        # Passthrough fallback: load defaults (if any), accept raw option/chartData/commonOption
        # 变体支持：spec 里写 "variant":"2" 时优先加载 <type>_<variant>.json（如 JCardScroll_2 / JScrollList_3）
        comp_key = t
        variant = str(c.get('variant', '')).strip()
        if variant:
            cand = f'{t}_{variant}'
            if os.path.exists(os.path.join(DEFAULTS_DIR, cand + '.json')):
                comp_key = cand  # bi_utils.add_component 会去掉 _N 后缀转回真实 compType
                cfg = load_def(cand)
            else:
                path = os.path.join(DEFAULTS_DIR, t + '.json')
                cfg = load_def(t) if os.path.exists(path) else {}
        else:
            path = os.path.join(DEFAULTS_DIR, t + '.json')
            cfg = load_def(t) if os.path.exists(path) else {}
        if 'data' in c:
            cfg['chartData'] = json.dumps(c['data'], ensure_ascii=False) \
                if not isinstance(c['data'], str) else c['data']
        if 'option' in c:
            cfg.setdefault('option', {}).update(c['option'])
        if 'commonOption' in c:
            cfg.setdefault('commonOption', {}).update(c['commonOption'])
    cfg.setdefault('background',  '#FFFFFF00')
    cfg.setdefault('borderColor', '#FFFFFF00')
    # 规范化 chartData：list → JSON 字符串（前端期望字符串；JText 等 dict 形式保留）
    cd = cfg.get('chartData')
    if isinstance(cd, list):
        cfg['chartData'] = json.dumps(cd, ensure_ascii=False)
    return comp_key, cfg


def _apply_named_palette(components, palette_name):
    """应用命名色板到所有图表组件。

    复用 style_ops 的 3 层覆盖逻辑：
      - option.customColor（jmreport 自定义色板）
      - option.color（ECharts 原生 palette）
      - 清除 series[*].itemStyle/lineStyle/areaStyle.color（否则硬编码覆盖 palette）

    按组件 (y,x) 排序轮转色板（与 style_ops 默认行为一致）。
    未知色板名 → 打印警告但不中断。
    """
    try:
        from style_ops import NAMED_PALETTES, CHART_TYPES, STRING_COLOR_TYPES
    except ImportError:
        print('⚠️ 未能加载 style_ops.NAMED_PALETTES，跳过色板应用')
        return
    if palette_name not in NAMED_PALETTES:
        print(f'⚠️ 未知色板 "{palette_name}"；跳过。可选: {", ".join(NAMED_PALETTES.keys())}')
        return
    color_list   = list(NAMED_PALETTES[palette_name])
    custom_color = [{'color': c, 'color1': c} for c in color_list]

    chart_comps = [c for c in components if c.get('component') in CHART_TYPES]
    chart_comps.sort(key=lambda c: (c.get('y', 0), c.get('x', 0)))
    for order, comp in enumerate(chart_comps):
        # bi_utils.add_component 以及 query_page 返回的 comp['config'] 均为 JSON 字符串
        cfg = comp.get('config', {})
        if isinstance(cfg, str):
            try:
                cfg = json.loads(cfg) if cfg else {}
            except Exception:
                cfg = {}
        if not isinstance(cfg, dict):
            cfg = {}
        opt = cfg.setdefault('option', {})
        k = order % len(color_list)
        # 单值自定义渲染组件 option.color 写 string；其余写 array（兼容已存为 string 的）
        if comp.get('component') in STRING_COLOR_TYPES or isinstance(opt.get('color'), str):
            opt['color'] = color_list[k]
        else:
            opt['color'] = color_list[k:] + color_list[:k]
        opt['customColor'] = custom_color[k:] + custom_color[:k]
        for s in opt.get('series', []) or []:
            if isinstance(s, dict):
                for style_key in ('itemStyle', 'lineStyle', 'areaStyle'):
                    style = s.get(style_key)
                    if isinstance(style, dict):
                        style.pop('color', None)
        # 写回为 dict——save_page 会正确序列化（与 style_ops.save_template 行为一致）
        comp['config'] = cfg
    print(f'→ 应用命名色板 "{palette_name}"（{len(chart_comps)} 个图表）')


def _apply_delete_spec(components, delete_spec):
    """在 append 模式下按 delete spec 过滤既有组件。

    delete_spec 字段（全部可选、可共存）：
      - types: ["JPie", "JRing", ...]   按组件类型
      - names: ["组件名1", ...]          按 componentName
      - ids:   ["i1", "i2", ...]         按组件 i
    返回 (filtered_list, removed_count)。匹配任一条件即删除。
    """
    if not delete_spec:
        return components, 0
    del_types = set(delete_spec.get('types') or [])
    del_names = set(delete_spec.get('names') or [])
    del_ids   = set(delete_spec.get('ids')   or [])
    if not (del_types or del_names or del_ids):
        return components, 0
    filtered, removed = [], 0
    for comp in components:
        if (comp.get('component')     in del_types or
            comp.get('componentName') in del_names or
            comp.get('i')             in del_ids):
            removed += 1
            print(f'  删除: {comp.get("componentName","")} ({comp.get("component","")})')
        else:
            filtered.append(comp)
    return filtered, removed


def build(spec, api=None, token=None, dry=False, page_id=None):
    """生成大屏。
    - page_id=None：create_page 新建（默认）
    - page_id=<ID>：追加组件到已有页面（保留已有组件，不覆盖）

    顶层 spec 字段（新增）：
      - palette: "科技"  → 建完/追加完统一应用命名色板（省一次 set-palette 外部调用）
      - delete: {types/names/ids} → 仅 --page-id 模式有效，追加前过滤既有组件
    """
    t0 = time.time()
    page = spec.get('page') or {}
    bg_key = page.get('bg', 'bg4')
    palette = dict(PALETTES.get(bg_key, PALETTES['_dark']))
    if 'palette' in page:
        palette.update(page['palette'])

    if dry:
        compiled = []
        for c in spec['components']:
            comp_key, cfg = compile_component(c, palette)
            compiled.append({
                'type':  comp_key,
                'title': c.get('title') or c.get('text', ''),
                'pos':   c['pos'],
                'cfg':   cfg,
            })
        return compiled

    import bi_utils
    bi_utils.API_BASE = api.rstrip('/')
    bi_utils.TOKEN    = token

    is_append = page_id is not None

    if is_append:
        p = bi_utils.query_page(page_id)
        existing = list(p.get('template') or [])
        # 迭代模式：先过滤旧组件，再追加新组件
        existing, removed_cnt = _apply_delete_spec(existing, spec.get('delete'))
        if removed_cnt:
            print(f'共删除 {removed_cnt} 个旧组件，保留 {len(existing)} 个')
        bi_utils._page_components[page_id] = existing
        print(f'Append mode: page {page_id}, retained {len(existing)} components')
    else:
        if spec.get('delete'):
            print('⚠️ delete 仅在 --page-id 迭代模式下生效，新建模式忽略')
        page_id = bi_utils.create_page(
            page.get('name', 'untitled'),
            style=page.get('style', 'bigScreen'),
            theme=page.get('theme', 'dark'),
            background_image=BG_IMAGES.get(bg_key, page.get('bgImage', '/img/bg/bg4.png')),
        )
        print(f'Page ID: {page_id}')
        bi_utils._page_components[page_id] = []

    for c in spec['components']:
        comp_key, cfg = compile_component(c, palette)
        title = c.get('title') or c.get('name') or c.get('text', '')
        pos = c['pos']
        bi_utils.add_component(page_id, comp_key, title, pos[0], pos[1], pos[2], pos[3], config=cfg)

    if not is_append:
        bi_utils.query_page(page_id)   # 新建模式防御性同步 updateCount；追加模式开头已 query 过

    # 命名色板（若 spec 指定）——save 前一次性应用
    palette_name = spec.get('palette')
    if palette_name:
        _apply_named_palette(bi_utils._page_components[page_id], palette_name)

    bi_utils.save_page(page_id)
    print(f'\n预览地址：')
    print(f'{api}/drag/share/view/{page_id}?token={token}&tenantId=2')
    print(f'耗时：{time.time()-t0:.1f}s')
    return page_id


# ======================================================================
# Per-component SCHEMA metadata (hand-maintained semantic layer).
# Structural layer (chartData sample, option keys, default w/h) is read
# from defaults/*.json at query time and merged.
# ======================================================================
SCHEMAS = {
    'JText': {
        'category': '文字 · UI 装饰',
        'spec_fields': 'text, style("title"|"subtitle"|"label"|"value"), fontSize, color, fontWeight, align, letterSpacing',
        'variants': {
            'title':    '主标题（默认 40/金 #f0c040/bold）',
            'subtitle': '副标题（22/青 #00d4ff）',
            'label':    '一般文字（14/白）',
            'value':    '数值文本（28/淡蓝/bold）',
        },
        'pitfalls': [
            'chartData 必须是 dict {"value": "..."}，不能是 JSON 字符串',
            '⚠️ 字段位置：fontSize/color/fontWeight/align/letterSpacing 等是 spec **顶级**字段（handler 把它们放进 option.body）。'
            '不要嵌进 spec.option.{...}——SPECIAL_HANDLERS 不读 spec.option，错位字段被忽略，前端 fallback 到 #000000 14px。'
            'bi_utils 直调时也不要 add_component("JText", config={"option":{"color":...}})，用 add_text() helper 代替。'
            '源码 text.vue:164-168 显式从 option.body 取 color/fontSize/fontWeight/textAlign/letterSpacing/marginLeft/marginTop/fontStyle/fontFamily',
        ],
        'selection': '大标题/小标题/标签/独立数值展示。需动效翻牌器用 JCountTo，纯数字短展示用 JNumber',
    },
    'JDragDecoration': {
        'category': '装饰条 · UI',
        'spec_fields': 'variant("1"~"12"), color, subColor, dur',
        'variants': {
            '1':  '【动·密度高】点阵矩阵+游走亮条：4~5 行小方块阵列 + 高亮长条横移，雷达 ping/数据流感。推荐 400~600 × 150~260',
            '2':  '【动·密度极低】稀疏点阵+横线：少量点阵 + 1~2 根贯穿水平细线。推荐 600 × 60，放大容器会近乎空白',
            '3':  '【动·密度高】双行密集柱条：上下两排 10~15 列双层方柱（频谱/机柜感）。推荐 400~600 × 80~120',
            '4':  '【动·密度高】双行柱条变体：与 3 视觉几乎一致（仅密度/相位差），可互换。推荐尺寸同 3',
            '5':  '【动·密度中】U 形凹槽：单层细线勾勒的 U 形/凹陷轮廓。推荐 300~400 × 100~150',
            '6':  '【动·密度中】音频波形：中央高两端低纵向呼吸柱条，顶部装饰最常用。推荐 400~600 × 150~260',
            '7':  '⚠️【静·密度极低】双层 chevron 箭头（>>）：小尺寸方向指示。推荐 80~200 × 40~80，给大尺寸会显空',
            '8':  '⚠️【静·密度低】简洁科技角标（实测非"HUD 矩形面板"）：四角 L 形细线 + 上下细横线，无封闭面板感。推荐 280~440 × 150~260',
            '9':  '【动·密度高】圆形轨道仪表：同心圆 + 方块刻度环 + 游走扇形 + 顶部圆弧。**容器需近正方形** 280~440 × 220~280',
            '10': '【动·密度极低】水平连线+小端点：一根贯穿线 + 端点标记。推荐 400~600 × **40~60**，大容器中几乎看不见',
            '11': '⚠️【静·密度中】大切角矩形容器（唯一支持 title）：4 角切角矩形 + 半透明底色，title 显示在容器中央。推荐 440~880 × 260~400',
            '12': '【动·密度高】雷达扫描：极坐标网格 + 实心扫光扇形，最浓"指挥中心"风。**容器需近正方形** 280~440 × 260。⚠️ **实测最小 200×200**——低于此尺寸 SVG 直接被裁剪/不显示',
        },
        'selection': '大屏顶部左右/中间装饰、分区视觉分隔。\n'
                     '【按位置选】顶部宽幅装饰：1/6（最常用）；横向窄条：3/4/10；近正方形：9/12；小角标：5/7；带文字面板：11；简洁科技框：8\n'
                     '【按密度选】高密度（撑大容器）：1/3/4/9/12；中密度：5/6/8/11；低密度（必须小尺寸）：2/7/10\n'
                     '【按动效需求选】要动效避开 7/8/11；要可写文字仅 11 支持',
        'pitfalls': [
            '7/8/11 是静态装饰，传 dur 无效；如果用户要"动态/会动的"装饰，避开这三个',
            '只有 11 支持显示 option.title 文本；其它 11 个变体的 title 仅占位不可见',
            '⚠️ 低密度变体（2/7/10）放大容器会显得空旷——容器尺寸必须按 variants 推荐尺寸匹配，否则视觉效果差',
            '⚠️ 圆形元素变体（9/12）容器接近正方形最佳；横向矩形会留大块空白',
            '⚠️ variant 8 实测视觉是"四角 L 细线+上下细横线"的简洁科技角标，不是封闭面板/HUD 框；要"带边框的容器"应用 JDragBorder 而非此变体',
        ],
    },
    'JDragBorder': {
        'category': '边框 · UI',
        'spec_fields': 'variant("1"~"13"), color',
        'variants': {str(i): f'type {i} 边框样式' for i in range(1, 14)},
        'pitfalls': ['前端 component 必须是 JDragBorder（无后缀），变体由 option.type 区分（spec_builder 自动处理）'],
    },
    'JStatsSummary': {
        'category': 'KPI 统计概览',
        'spec_fields': 'variant("1"|"2"|"3"), data:[{name, value<number>, suffix|unit, compareLabel, compareValue, up:bool}], showCompare:bool(默认 true，false 隐藏中部同比/环比区), bgImageUrl:str(变体 2/3 底图 URL，默认 drag/lib/img/bg01.png)',
        'variants': {
            '1': '卡片分区式：top/middle/bottom 三层，最常用',
            '2': '背景色块式：整卡带色块底（layout 层背景图）',
            '3': '高亮强调式：数值高亮突出（card 层背景图）',
        },
        'pitfalls': [
            'value 必须是数字（"48,620" 含逗号→NaN）',
            'up:true/false 自动转 compareState:"1"/"0"（spec_builder 处理）',
            'compareState 不接受 "up"/"down"，只接受 "1"/"0"',
            '不需要同比/环比时 spec 写 "showCompare": false（handler 自动设 option.sections.middle.show=false 隐藏中部区）',
            '⚠️ 高度字段 h 不生效：组件高度由内部三层（top标签/middle数值/bottom对比）内容 + 上下内边距撑起；写 pos=[x,y,w,h] 的 h 只是占位，不是最终可视高度。**全显 180px**（与 defaults 对齐）；**showCompare=false 隐中部后实测 153px**。布局时下方组件的 y 坐标至少预留对应高度，否则会被压盖。缩小高度需手动改 option.card/sections 的 padding 与字号。',
            '⚠️ 数据集绑定走 option.fieldMap（B.1）。机制速查见 references/data-binding-mapping.md',
            '⚠️ 变体 2/3 默认 image.url 为空 → handler 自动注入平台内置素材 drag/lib/img/bg01.png（变体 2 写 layout 层、变体 3 写 card 层）。覆盖：spec 顶层 bgImageUrl="<URL>"，或显式写 option.layout.fill.image.url / option.card.fill.image.url。改纯色/渐变写 option.<layout|card>.fill.type="color"|"gradient" handler 不覆盖',
        ],
        'selection': '多指标 KPI 卡片带环比（4-6 项最佳）。仅数字用 JNumber/JCountTo。单大数字用 JCountTo',
    },
    'JRingProgress': {
        'category': '环形单值进度',
        'spec_fields': 'value<0-100>, title, color, bgColor, valueColor, radius, innerRadius, valueFontSize, fontSize, lineHeight',
        'pitfalls': [
            '⚠️ valueFontSize 默认 22（实测安全值）：超过 28 在 h<300 容器下数字底部会被组件下边沿裁掉，'
            '因为前端按行布局（标题→数值），lineHeight=0 默认时数值整体下移。'
            '需要更醒目的数字 → 同步加大组件 h 至 ≥ 360 再调字号',
            'lineHeight 控制标题与数值的行间距：0 时两行重叠，过大时数值下推。默认 24 兼顾大多数容器',
        ],
        'selection': '单指标完成率/达成率。多分类占比用 JRing；圆形数字动效用 JCountTo',
    },
    'JScrollBoard': {
        'category': 'DataV 轮播表格',
        'spec_fields': 'columns:[{label, key, width}], rows<二维数组>, rowNum, waitTime, headerBg, oddRowBg, evenRowBg, align, headShow, index',
        'pitfalls': [
            'header 必须是对象数组 [{label,key,width}]，字符串数组表头不显示',
            'rows 是二维数组（列表的列表），不是对象数组',
            '⚠️ 数据集绑定走 option.header[*].key（B.6）。机制速查见 references/data-binding-mapping.md',
        ],
        'selection': '设备/订单/日志类自动滚动表格。自定义样式用 JScrollTable；静态表格用 JCommonTable',
    },
    'JScrollRankingBoard': {
        'category': '排行榜 · DataV 风格',
        'spec_fields': 'data:[{name, value<number>}], rowNum, sort, color<进度条单色>, textColor, carousel("single"|"page")',
        'pitfalls': [
            'value 必须是数字，自动降序；若需要描述性字符串 value，改用 JCapsuleChart 搭配 unit',
            '⚠️ option.color 是**单色字符串**（进度条颜色，默认 #1370fb），不要传数组 — ECharts 拿到 list 会报 "Color: Invalid Input of #a,#b"（实测 2026-05-13）。handler 已兼容 list 输入自动取首色',
        ],
        'selection': '大屏唯一可用的排行榜组件。固定"名次+名称+数值"3 列；胶囊进度条样式用 JCapsuleChart',
    },
    'JColorGauge': {
        'category': '多色段仪表盘',
        'spec_fields': 'value<0-100 数字>, title, name, segments:[[frac<0-1 阈值>, color], ...]',
        'pitfalls': [
            'value 与 JAntvGauge/JLiquid/JRingProgress 一致：0-100 数字（92 = 92%）',
            'segments 每项是 [占比阈值 0-1, 色值]（如 [[0.6,"#ff4d4f"],[0.85,"#faad14"],[1.0,"#52c41a"]]）',
            '不传 segments 用默认红/黄/蓝三色',
        ],
        'selection': '带阈值分段的指标（恐慌/中立/贪婪、KPI 健康度）。渐变弧形用 JAntvGauge；单色单针用 JGauge',
    },
    'JListProgress': {
        'category': '列表进度条',
        'spec_fields': 'data:[{title, current, target, label, date}], color, textColor, fontSize, barHeight, rowHeight',
        'pitfalls': [
            'defaults schema 是 {title,value,total,endLabel,date}；handler 接受 current/target/label 别名自动映射',
            '⚠️ 数据集绑定走 option.{beginFields,centerTopFields,endFields}[*].key（B.5）。机制速查见 references/data-binding-mapping.md',
        ],
        'selection': '多行进度展示（合同进度、指数实时）。单条进度用 JCustomProgress；圆形用 JRingProgress',
    },
    'JFlyLineMap': {
        'category': '地图 · 飞线',
        'spec_fields': 'data:[{from, to, value}] 或 {fromName, fromLng, fromLat, toName, toLng, toLat, value}; trailLength, symbolSize, effectColor',
        'pitfalls': [
            'handler 内置 34 常用城市坐标查表，直接用 from/to 中文城市名',
            'commonOption.effect 必须有（spec_builder 自动保留 defaults 的）',
            '⚠️ 数据集绑定 filed 必须中文：[起点名称, 起点经度, 起点纬度, 终点名称, 终点经度, 终点纬度, 数值]（7 项）',
        ],
        'selection': '跨区域流向/迁移展示。散点用 JBubbleMap；带时间轴用 JTotalFlyLineMap',
    },
    'JAreaMap':   {'category': '地图 · 区域', 'spec_fields': 'data:[{name<省名>, value}], option, commonOption',
                   'selection': '省份 GDP/指标分布。省名必须精确匹配（见 map-static-data.md）'},
    'JBubbleMap': {'category': '地图 · 气泡散点', 'spec_fields': 'data:[{name<城市>, value}], option, commonOption',
                   'selection': '城市级散点分布'},
    'JBarMap':    {'category': '地图 · 柱形', 'spec_fields': 'data:[{name<省/市>, value}], option, commonOption',
                   'selection': '地图上立柱形展示，高度=数值'},
    'JCountTo': {
        'category': '翻牌器 · 数字滚动',
        'spec_fields': 'value<number>, whole:bool, fontSize, color, fontWeight, align, prefix, suffix',
        'variants': {'whole=true': '整体 count-up 动画', 'whole=false': '分格翻牌效果'},
        'pitfalls': ['⚠️ 数据集绑定 filed 是 `数值`（单项，中文）'],
        'selection': '大数字动效（KPI 总额）。静态数字用 JNumber；带比较的组合 KPI 用 JStatsSummary',
    },
    'JNumber': {
        'category': '数值文本',
        'spec_fields': 'value, color, fontSize, fontWeight, align, prefix, suffix',
        'selection': '简单数字展示（无动效）。动效用 JCountTo；带对比用 JStatsSummary',
    },
    'JCapsuleChart': {
        'category': '胶囊排行',
        'spec_fields': 'data:[{name, value<number>}], colors:[...], showValue, unit',
        'selection': '水平条+末尾数字排行（TOP 5-10）。数字单独列用 JScrollRankingBoard',
    },
    'JSemiGauge': {
        'category': '半圆仪表盘',
        'spec_fields': 'value, max, titlePrefix, titleSuffix, valuePrefix, valueSuffix（或 data:{total,used}）',
        'pitfalls': ['⚠️ 数据集绑定走 option.titleMapping/valueMapping（B.2）。机制速查见 references/data-binding-mapping.md'],
        'selection': '容量/使用率（内存、存储、额度）。完整圆用 JGauge；多色段用 JColorGauge',
    },
    'JGauge': {
        'category': '基础仪表盘',
        'spec_fields': 'value, max, name, title',
        'selection': '单针单色仪表。多色段用 JColorGauge；渐变弧形用 JAntvGauge',
    },
    'JAntvGauge': {
        'category': '渐变仪表盘 · AntV',
        'spec_fields': 'value<0-100 数字>, label, title, colorType("gradient"|"solid"), colors, valueColor, valueFontSize, indicatorColor',
        'pitfalls': [
            '⚠️ value 必须是 0-100 数字（如 78 表示 78%）；传 0-1 小数会被当成 <1%，渲染为 "1" 且指针贴 0',
            '想要渐变色传 colorType:"gradient"（默认）；纯色传 "solid" 并配 colors:[{color1, color2}]',
        ],
        'selection': 'AntV G2Plot 渲染，支持渐变色弧。ECharts 仪表用 JGauge/JColorGauge',
    },
    'JLiquid': {
        'category': '水波球',
        'spec_fields': 'value<0-100>, color, title, liquidType("circle"|"rect"), borderColor, textColor, textFontSize',
        'selection': '液态视觉效果进度。纯环形用 JRingProgress；条状用 JCustomProgress',
    },
}

# 扩展 SCHEMAS：从 schemas_extra.py 合并 passthrough 组件的 metadata。
# 主字典只收录有 builtin handler 的组件，其余纯元数据集中在 schemas_extra 便于维护。
try:
    from schemas_extra import EXTRA_SCHEMAS
    SCHEMAS.update(EXTRA_SCHEMAS)
except ImportError:
    pass

_CARTESIAN_SCHEMA_COMMON = {
    'category': 'ECharts cartesian（笛卡尔坐标，带 xAxis/yAxis）',
    'spec_fields': (
        'data:[{name, value<number>, type?<仅多系列组件>}], title, '
        'color<单色>, gradient:[v|h,c1,c2]<条状>, colors:[...]<多系列>, '
        'barWidth, smooth<折线>, '
        'xAxis:{interval,formatter,rotate,type}, yAxis:{min,max,formatter,type}'
    ),
    'pitfalls': [
        '⚠️ 多系列 type 字段仅以下组件支持：JStackBar / JMultipleBar / JMultipleLine / JMixLineBar（defaults 有"分组" filed）',
        '⚠️ 其他组件（JArea / JLine / JBar / JHorizontalBar 等）defaults 只 1 个 series，type 会被忽略，数据会按 name 聚合错位',
        '要多折线/堆叠趋势用 JMultipleLine / JStackBar，而非 JArea 多系列',
        'chartData 每项可加 itemStyle:{color} 单独着色（板块红涨绿跌）',
        'builder 自动注入轴色/分割线/tooltip/grid，无需手写 axisLabel.color 等',
        'JArea 不传 gradient 自动用 color 生成 areaStyle 渐变',
    ],
}

_POLAR_SCHEMA_COMMON = {
    'category': 'ECharts polar（饼/环/极坐标，无 xAxis/yAxis）',
    'spec_fields': 'data:[{name, value}], title, colors:[...]',
    'pitfalls': [
        'builder 强制 opt.pop("xAxis","yAxis")，禁止手写这两个字段',
    ],
    'selection': (
        'JPie 等半径不等角度 · JRose 等角度不等半径 · JRing 环形(中空 40~70%) · '
        'JBreakRing 数据差距悬殊用 · JActiveRing 悬停外扩 · JRadar/JCircleRadar 雷达'
    ),
}


def _load_defaults_info(comp_type):
    """Read defaults/<type>.json and extract structural info."""
    if comp_type in _DEFAULTS_CACHE:
        d = copy.deepcopy(_DEFAULTS_CACHE[comp_type])
    else:
        path = os.path.join(DEFAULTS_DIR, comp_type + '.json')
        if not os.path.exists(path):
            return None
        with open(path, encoding='utf-8') as f:
            d = json.load(f)
        _DEFAULTS_CACHE[comp_type] = d
        d = copy.deepcopy(d)
    info = {'w': d.get('w'), 'h': d.get('h'),
            'option_keys': list(d.get('option', {}).keys()) if isinstance(d.get('option'), dict) else None,
            'common_option_keys': list(d.get('commonOption', {}).keys()) if 'commonOption' in d else None}
    cd = d.get('chartData')
    if cd is not None:
        try:
            s = json.dumps(cd, ensure_ascii=False)
            info['chartData_sample'] = s if len(s) <= 300 else s[:280] + ' …(truncated)'
        except Exception:
            info['chartData_sample'] = str(cd)[:280]
    return info


def print_schema(comp_type, full=False):
    """Print full schema for one component: handler semantic layer + defaults structural layer.
    full=True → also dump complete defaults/<type>.json (for deep option customization)."""
    lines = []
    lines.append(f'===== {comp_type} =====')

    # Disabled check —— give a clear error upfront instead of leading users to a dead-end passthrough.
    if comp_type in DISABLED_COMPONENTS:
        lines.append('Handler: ⛔ DISABLED —— 大屏（bigScreen）平台不支持此组件，生成后不渲染')
        replacements = {
            'JRankingList':   'JScrollRankingBoard（DataV 排行榜，大屏唯一可用的排行榜组件）',
            'JTotalProgress': 'JListProgress / JCapsuleChart',
            'JPivotTable':    'JScrollBoard / JCommonTable',
            'JFly3dMap':      'JFlyLineMap（2D 飞线，chartData 格式相同）/ JTotalFlyLineMap（带时间轴多段飞线）',
        }
        lines.append(f'替代组件: {replacements.get(comp_type, "—")}')
        print('\n'.join(lines))
        return

    # Handler status
    if comp_type in SPECIAL_HANDLERS:
        handler_status = f'✓ builtin handler (handle_{comp_type})'
    elif comp_type in ECHARTS_CARTESIAN:
        handler_status = '✓ cartesian handler (通用折线/柱/散点处理)'
    elif comp_type in ECHARTS_POLAR:
        handler_status = '✓ polar handler (通用饼/环/雷达处理)'
    else:
        handler_status = '○ passthrough（传 option/chartData/commonOption 原生字段）'
    lines.append(f'Handler: {handler_status}')

    # Semantic layer
    meta = SCHEMAS.get(comp_type)
    if meta is None and comp_type in ECHARTS_CARTESIAN:
        meta = _CARTESIAN_SCHEMA_COMMON
    if meta is None and comp_type in ECHARTS_POLAR:
        meta = _POLAR_SCHEMA_COMMON
    if meta:
        if meta.get('category'):
            lines.append(f'Category: {meta["category"]}')
        if meta.get('spec_fields'):
            lines.append(f'Spec fields: {meta["spec_fields"]}')
        if meta.get('variants'):
            lines.append('Variants:')
            for k, v in meta['variants'].items():
                lines.append(f'  {k}: {v}')
        if meta.get('selection'):
            lines.append(f'Selection: {meta["selection"]}')
        if meta.get('pitfalls'):
            lines.append('Pitfalls:')
            for p in meta['pitfalls']:
                lines.append(f'  · {p}')

    # Structural layer (from defaults JSON) — try both raw and variant _1 if applicable
    info = _load_defaults_info(comp_type)
    if info is None and comp_type == 'JStatsSummary':
        info = _load_defaults_info('JStatsSummary_1')
        if info: info['_from'] = 'JStatsSummary_1'
    if info:
        src = info.get('_from', comp_type)
        lines.append(f'Defaults (from defaults/{src}.json):')
        if info.get('w') or info.get('h'):
            lines.append(f'  Default size: w={info.get("w")}, h={info.get("h")}')
        if info.get('option_keys'):
            lines.append(f'  option keys: {info["option_keys"]}')
        if info.get('common_option_keys'):
            lines.append(f'  commonOption keys: {info["common_option_keys"]}')
        if info.get('chartData_sample'):
            lines.append(f'  chartData sample: {info["chartData_sample"]}')
    else:
        lines.append(f'Defaults: (no defaults/{comp_type}.json found — write option/chartData manually in passthrough mode)')

    # Minimal spec example
    lines.append('Minimal spec:')
    if comp_type in SPECIAL_HANDLERS:
        lines.append(f'  {{"type":"{comp_type}","pos":[x,y,w,h],...<see spec fields above>}}')
    elif comp_type in ECHARTS_CARTESIAN:
        lines.append(f'  {{"type":"{comp_type}","pos":[...],"title":"...","data":[{{"name":"A","value":100}}],"color":"#00d4ff"}}')
    elif comp_type in ECHARTS_POLAR:
        lines.append(f'  {{"type":"{comp_type}","pos":[...],"title":"...","data":[{{"name":"A","value":1}}],"colors":["#00d4ff","#f0c040"]}}')
    else:
        lines.append(f'  {{"type":"{comp_type}","pos":[...],"data":[...],"option":{{...}}}}')

    if not full:
        lines.append('')
        lines.append(f'For full defaults dump (complete nested option/chartData/commonOption structure):')
        lines.append(f'  py spec_builder.py --schema {comp_type} --full')

    print('\n'.join(lines))

    # --full mode: dump complete defaults JSON for deep customization
    if full:
        print()
        print('===== Full defaults JSON =====')
        # Try main path, then variant fallback (e.g. JStatsSummary → JStatsSummary_1)
        paths_to_try = [comp_type]
        if comp_type == 'JStatsSummary':
            paths_to_try = ['JStatsSummary_1', 'JStatsSummary_2', 'JStatsSummary_3']
        elif comp_type == 'JCardScroll':
            paths_to_try = ['JCardScroll_1', 'JCardScroll_2', 'JCardScroll_3']
        elif comp_type == 'JScrollList':
            paths_to_try = ['JScrollList_1', 'JScrollList_2', 'JScrollList_3']
        dumped = False
        for p in paths_to_try:
            path = os.path.join(DEFAULTS_DIR, p + '.json')
            if os.path.exists(path):
                with open(path, encoding='utf-8') as f:
                    d = json.load(f)
                print(f'--- defaults/{p}.json ---')
                print(json.dumps(d, ensure_ascii=False, indent=2))
                dumped = True
        if not dumped:
            print(f'(no defaults/*.json found for {comp_type} — this is a pure passthrough compType; write option/chartData manually)')


def print_schema_list():
    """Print all supported compTypes categorized."""
    print('===== spec_builder 支持的 compType（按路径分组）=====\n')
    print(f'SPECIAL_HANDLERS（{len(SPECIAL_HANDLERS)} 个，内置字段映射）:')
    for t in sorted(SPECIAL_HANDLERS):
        meta = SCHEMAS.get(t, {})
        print(f'  {t:<24} {meta.get("category", "")}')
    print(f'\nECHARTS_CARTESIAN（{len(ECHARTS_CARTESIAN)} 个，通用折线/柱/散点）:')
    for t in sorted(ECHARTS_CARTESIAN):
        print(f'  {t}')
    print(f'\nECHARTS_POLAR（{len(ECHARTS_POLAR)} 个，通用饼/环/雷达）:')
    for t in sorted(ECHARTS_POLAR):
        print(f'  {t}')
    # Passthrough 组件：有 metadata 但没 handler（来自 schemas_extra.py）
    _listed = set(SPECIAL_HANDLERS) | set(ECHARTS_CARTESIAN) | set(ECHARTS_POLAR)
    passthrough_with_meta = sorted(
        t for t in SCHEMAS
        if t not in _listed and not t.endswith(('_1', '_2', '_3'))  # 变体别名不单列
    )
    if passthrough_with_meta:
        print(f'\nPassthrough 已登记（{len(passthrough_with_meta)} 个，metadata 在 schemas_extra.py）:')
        for t in passthrough_with_meta:
            meta = SCHEMAS.get(t, {})
            print(f'  {t:<24} {meta.get("category", "")}')
    print(f'\nPassthrough 其他：读 defaults/*.json → 传 option/chartData/commonOption 原生字段')
    print(f'\n⛔ DISABLED（{len(DISABLED_COMPONENTS)} 个，大屏平台不支持，生成会报错）:')
    for t in sorted(DISABLED_COMPONENTS):
        print(f'  {t}')
    print(f'\n用法: py spec_builder.py --schema <CompType>  — 查看某组件完整 schema')


def main():
    argv = sys.argv[1:]

    # --schema mode
    if '--schema' in argv:
        argv.remove('--schema')
        full = '--full' in argv
        if full:
            argv.remove('--full')
        if '--list' in argv or not argv:
            print_schema_list()
            return
        comp_type = argv[0]
        print_schema(comp_type, full=full)
        return

    dry = False
    if '--dry' in argv:
        argv.remove('--dry')
        dry = True

    append_page_id = None
    if '--page-id' in argv:
        idx = argv.index('--page-id')
        append_page_id = argv[idx + 1]
        del argv[idx:idx + 2]

    if dry:
        if len(argv) < 1:
            print('Usage: py spec_builder.py --dry <spec.json>', file=sys.stderr)
            sys.exit(1)
        spec_path = argv[0]
        with open(spec_path, encoding='utf-8') as f:
            spec = json.load(f)
        result = build(spec, dry=True)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return
    if len(argv) < 3:
        print('Usage: py spec_builder.py <API> <TOKEN> <spec.json> [--page-id <ID>]', file=sys.stderr)
        sys.exit(1)
    api, token, spec_path = argv[0], argv[1], argv[2]
    with open(spec_path, encoding='utf-8') as f:
        spec = json.load(f)
    build(spec, api, token, page_id=append_page_id)


if __name__ == '__main__':
    main()

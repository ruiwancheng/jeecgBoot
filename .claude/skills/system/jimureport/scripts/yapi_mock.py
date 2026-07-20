# -*- coding: utf-8 -*-
"""
YApi Mock 接口管理脚本

功能：
  - 登录 YApi 平台获取 Cookie
  - 创建 mock 接口
  - 更新 mock 数据
  - 删除 mock 接口
  - 查询接口列表

固定配置（api.jeecg.com 项目）：
  - project_id: 57
  - catid: 1157（公共分类）
  - basepath: /claude
  - mock 完整 URL：https://api.jeecg.com/mock/57/claude/{path后缀}

用法示例：
    from yapi_mock import init_yapi, create_mock

    init_yapi(email='', password='')
    mock_url = create_mock('/staff', '职员信息', [
        {"name": "张三", "salary": 18000},
        {"name": "李四", "salary": 15000},
    ])
    print(mock_url)  # https://api.jeecg.com/mock/57/claude/staff
"""

import json
import urllib.request
import ssl

# ── 固定配置 ──────────────────────────────────────────────────
_YAPI_BASE   = 'https://api.jeecg.com'
_PROJECT_ID  = '57'
_CAT_ID      = '1157'
_BASEPATH    = '/claude'
_MOCK_PREFIX = f'{_YAPI_BASE}/mock/{_PROJECT_ID}{_BASEPATH}'

_cookie = None
_ctx = ssl.create_default_context()
_ctx.check_hostname = False
_ctx.verify_mode = ssl.CERT_NONE


# ── 核心请求 ──────────────────────────────────────────────────
def _request(path, data=None, method=None):
    url = f'{_YAPI_BASE}{path}'
    headers = {'Content-Type': 'application/json; charset=UTF-8'}
    if _cookie:
        headers['Cookie'] = _cookie
    body = json.dumps(data, ensure_ascii=False).encode('utf-8') if data is not None else None
    if method is None:
        method = 'POST' if body else 'GET'
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    with urllib.request.urlopen(req, context=_ctx, timeout=15) as resp:
        return json.loads(resp.read().decode('utf-8'))


# ── 登录 ──────────────────────────────────────────────────────
def init_yapi(email='', password=''):
    """登录 YApi，获取 Cookie 供后续请求使用"""
    global _cookie
    url = f'{_YAPI_BASE}/api/user/login'
    body = json.dumps({'email': email, 'password': password}).encode('utf-8')
    req = urllib.request.Request(url, data=body,
          headers={'Content-Type': 'application/json'}, method='POST')
    with urllib.request.urlopen(req, context=_ctx, timeout=15) as resp:
        raw = resp.read()
        # 提取所有 Set-Cookie 头（urllib 每条独立，不能用 .get() 只取一条）
        cookie_headers = resp.headers.get_all('Set-Cookie') or []
        parts = []
        for c in cookie_headers:
            part = c.strip().split(';')[0]
            if '_yapi_token' in part or '_yapi_uid' in part:
                parts.append(part)
        _cookie = '; '.join(parts)
        result = json.loads(raw)
    if result.get('errcode') != 0:
        raise RuntimeError(f'YApi 登录失败: {result.get("errmsg")}')
    print(f'✓ YApi 登录成功，用户：{result["data"]["username"]}')
    return _cookie


# ── 创建 + 写入数据（一步完成）─────────────────────────────────
def create_mock(path, title, data):
    """
    创建 mock 接口并写入数据。

    Args:
        path:  接口路径后缀，不含 basepath，如 '/staff'（不要写 '/claude/staff'）
        title: 接口名称，如 '职员信息'
        data:  列表数据，会自动包装为 {"data": [...]}

    Returns:
        完整 mock URL，如 'https://api.jeecg.com/mock/57/claude/staff'
    """
    # 1. 创建接口（已存在则复用）
    add_r = _request('/api/interface/add', {
        'method': 'GET',
        'catid': _CAT_ID,
        'title': title,
        'path': path,
        'project_id': _PROJECT_ID,
    })
    if add_r.get('errcode') == 0:
        iface_id = str(add_r['data']['_id'])
        print(f'✓ 接口创建成功，id={iface_id}')
    elif '已存在' in (add_r.get('errmsg') or ''):
        # 已存在 → 查 id 后复用更新
        list_r = _request(f'/api/interface/list?project_id={_PROJECT_ID}&page=1&limit=200', method='GET')
        iface_id = None
        for item in list_r.get('data', {}).get('list', []):
            if item.get('path') == path and item.get('method') == 'GET':
                iface_id = str(item['_id'])
                break
        if not iface_id:
            raise RuntimeError(f'接口已存在但未找到 id: path={path}')
        print(f'✓ 接口已存在，复用 id={iface_id}')
    else:
        raise RuntimeError(f'创建接口失败: {add_r.get("errmsg")}')

    # 2. 写入 mock 数据（包装为 {"data": [...]}）
    update_mock(iface_id, path, title, data)

    mock_url = f'{_MOCK_PREFIX}{path}'
    print(f'✓ Mock URL：{mock_url}')
    return mock_url


def update_mock(iface_id, path, title, data):
    """
    更新已有接口的 mock 数据。

    Args:
        iface_id: 接口 ID
        path:     接口路径后缀（不含 basepath）
        title:    接口名称
        data:     列表数据，会自动包装为 {"data": [...]}
    """
    # 自动包装格式
    if isinstance(data, list):
        res_body = json.dumps({"data": data}, ensure_ascii=False, indent=2)
    else:
        res_body = json.dumps(data, ensure_ascii=False, indent=2)

    up_r = _request('/api/interface/up', {
        'id': str(iface_id),
        'title': title,
        'catid': _CAT_ID,
        'path': path,
        'method': 'GET',
        'project_id': _PROJECT_ID,
        'status': 'undone',
        'tag': [],
        'req_query': [], 'req_headers': [], 'req_body_form': [], 'req_params': [],
        'req_body_is_json_schema': True,
        'res_body_is_json_schema': False,
        'res_body_type': 'raw',
        'res_body': res_body,
        'switch_notice': True,
        'api_opened': False,
        'desc': '', 'markdown': '',
    })
    if up_r.get('errcode') != 0:
        raise RuntimeError(f'写入 mock 数据失败: {up_r.get("errmsg")}')
    print(f'✓ mock 数据写入成功')


def delete_mock(iface_id):
    """删除 mock 接口"""
    r = _request('/api/interface/del', {'id': int(iface_id)})
    if r.get('errcode') != 0:
        raise RuntimeError(f'删除失败: {r.get("errmsg")}')
    print(f'✓ 接口 {iface_id} 已删除')


def list_mocks():
    """列出项目下所有接口"""
    r = _request(f'/api/interface/list?project_id={_PROJECT_ID}&page=1&limit=200', method='GET')
    if r.get('errcode') != 0:
        raise RuntimeError(f'查询失败: {r.get("errmsg")}')
    items = r['data']['list']
    print(f'共 {len(items)} 个接口：')
    for item in items:
        print(f'  [{item["_id"]}] {item["title"]}  path={_BASEPATH}{item["path"]}')
    return items


def create_paginated_mock(path, title, data):
    """
    创建支持分页的 mock 接口（高级 Mock 脚本实现）。

    分页响应格式（固定规范）：
      {
        "data":     当前页记录列表,
        "total":    总页数（Math.ceil(count / pageSize)）,
        "count":    总记录数,
        "pageSize": 每页条数（取自 URL 参数，默认 10）,
        "pageNo":   当前页码（取自 URL 参数，默认 1）
      }

    URL 参数：pageNo（页码）、pageSize（每页条数）

    Args:
        path:  接口路径后缀，不含 basepath，如 '/staff_list_20260429'
        title: 接口名称
        data:  完整数据列表（所有记录，分页逻辑由高级脚本处理）

    Returns:
        完整 mock URL
    """
    import json as _json
    # 1. 创建接口（复用 create_mock 的建接口逻辑）
    url = create_mock(path, title, data)

    # 2. 找到接口 ID
    list_r = _request(f'/api/interface/list?project_id={_PROJECT_ID}&page=1&limit=200', method='GET')
    iface_id = None
    for item in list_r.get('data', {}).get('list', []):
        if item.get('path') == path:
            iface_id = str(item['_id'])
            break
    if not iface_id:
        raise RuntimeError(f'分页 mock 建立后未找到接口 id: path={path}')

    # 3. 写入分页高级脚本
    data_js = _json.dumps(data, ensure_ascii=False)
    script = f"""
var allData = {data_js};
var pageNo   = parseInt(params.pageNo)   || 1;
var pageSize = parseInt(params.pageSize) || 10;
var count    = allData.length;
var start    = (pageNo - 1) * pageSize;
var records  = allData.slice(start, Math.min(start + pageSize, count));
mockJson = {{"data": records, "total": Math.ceil(count / pageSize), "count": count, "pageSize": pageSize, "pageNo": pageNo}};
"""
    set_advmock(iface_id, script, enable=True)
    return url


def set_advmock(iface_id: str, script: str, enable: bool = True):
    """
    启用高级 Mock 脚本（正确 API: /api/plugin/advmock/save）。

    Args:
        iface_id: 接口 ID（字符串）
        script:   JavaScript mock 脚本，用 mockJson = {...} 赋值返回数据
        enable:   True=启用，False=禁用
    """
    r = _request('/api/plugin/advmock/save', {
        'project_id':   _PROJECT_ID,
        'interface_id': str(iface_id),
        'mock_script':  script,
        'enable':       enable,
    })
    if r.get('errcode') != 0:
        raise RuntimeError(f'高级 Mock 脚本写入失败: {r.get("errmsg")} | {r}')
    print(f'✓ 高级 Mock 脚本已{"启用" if enable else "禁用"}，interface_id={iface_id}')
    return r['data']


def mock_url(path):
    """根据 path 后缀生成完整 mock URL"""
    return f'{_MOCK_PREFIX}{path}'


# ── CLI 入口 ──────────────────────────────────────────────────
if __name__ == '__main__':
    import sys
    args = sys.argv[1:]
    init_yapi()
    if not args or args[0] == 'list':
        list_mocks()
    elif args[0] == 'delete' and len(args) > 1:
        delete_mock(args[1])
    else:
        print('用法：')
        print('  python yapi_mock.py list            # 列出所有接口')
        print('  python yapi_mock.py delete <id>     # 删除接口')

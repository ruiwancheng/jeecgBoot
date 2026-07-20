"""
JeecgBoot Online 表单菜单挂载 + 路由缓存配置脚本

用法:
  python onlform_menu.py --api-base <URL> --token <TOKEN> --config <config.json>

config.json 格式:

1. 挂载菜单（默认不开启缓存）:
{
  "action": "mount",
  "tableName": "test_order_main",
  "menuName": "测试订单主表",
  "parentId": "xxx",
  "menuType": 1,
  "sortNo": 1,
  "keepAlive": false,
  "roleCode": "admin"
}

menuType 说明（可不填，脚本自动推导）:
  - 0: 一级菜单（顶级，无 parentId）
  - 1: 子菜单（有 parentId，默认）
  - 2: 按钮权限（有 parentId，会额外传 status 字段）

2. 开启已有菜单的缓存路由:
{
  "action": "enable_cache",
  "menuId": "xxx"
}

3. 批量挂载:
{
  "action": "mount_batch",
  "tables": [
    {"tableName": "test_order_main", "menuName": "测试订单主表"},
    {"tableName": "test_enhance_select", "menuName": "三级联动控件"}
  ],
  "parentId": "",
  "keepAlive": false,
  "roleCode": "admin"
}

参数说明:
  - tableName: Online 表名（必填）
  - menuName: 菜单显示名称（可选，默认用表描述 tableTxt）
  - parentId: 父菜单ID（可选，空字符串=顶级菜单）
  - sortNo: 排序号（可选，默认 1）
  - keepAlive: 是否开启缓存路由（可选，默认 false）
  - roleCode: 授权角色编码（可选，如 "admin"；不填则不授权）
"""

from typing import Dict, List, Optional
import urllib.request
import json
import sys
import ssl
import argparse

sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

_ssl_ctx = ssl.create_default_context()
_ssl_ctx.check_hostname = False
_ssl_ctx.verify_mode = ssl.CERT_NONE

# ====== URL 路径 → 组件名称映射 ======

# themeTemplate → URL 路径关键词
THEME_TO_URL_KEY: Dict[str, str] = {
    'normal': 'cgformList',
    'erp': 'cgformErpList',
    'innerTable': 'cgformInnerTableList',
    'tab': 'cgformTabList',
    'tree': 'cgformTreeList',
}

# URL 路径关键词 → componentName
URL_KEY_TO_COMPONENT: Dict[str, str] = {
    'cgformList': 'OnlineAutoList',
    'cgformErpList': 'CgformErpList',
    'cgformInnerTableList': 'OnlCgformInnerTableList',
    'cgformTabList': 'OnlCgformTabList',
    'cgformTreeList': 'DefaultOnlineList',
}

# URL 路径关键词 → AUTO 菜单通配 URL 模式
URL_KEY_TO_AUTO_PATTERN: Dict[str, str] = {
    'cgformList': '/online/cgformList/:',
    'cgformErpList': '/online/cgformErpList/:',
    'cgformInnerTableList': '/online/cgformInnerTableList/:',
    'cgformTabList': '/online/cgformTabList/:',
    'cgformTreeList': '/online/cgformTreeList/:',
}


# ====== 工具函数 ======

def api_request(api_base: str, token: str, path: str, data: Optional[dict] = None, method: str = 'POST') -> dict:
    url = f'{api_base}{path}'
    if method == 'GET':
        import time as _time
        sep = '&' if '?' in url else '?'
        url += f'{sep}_t={int(_time.time() * 1000)}'
    headers = {
        'X-Access-Token': token,
        'Content-Type': 'application/json; charset=UTF-8'
    }
    if data is not None:
        json_data = json.dumps(data, ensure_ascii=False).encode('utf-8')
        req = urllib.request.Request(url, data=json_data, headers=headers, method=method)
    else:
        req = urllib.request.Request(url, headers=headers, method=method)
    resp = urllib.request.urlopen(req, context=_ssl_ctx)
    return json.loads(resp.read().decode('utf-8'))


def get_online_form_info(api_base: str, token: str, table_name: str) -> dict:
    """查询 Online 表单的 headId、tableTxt、themeTemplate 等信息"""
    resp = api_request(api_base, token,
                       f'/online/cgform/head/list?tableName={table_name}&pageNo=1&pageSize=1',
                       method='GET')
    records = (resp.get('result') or {}).get('records', [])
    if not records:
        raise ValueError(f'未找到 Online 表: {table_name}')
    return records[0]


def resolve_url_key(form_info: dict) -> str:
    """根据表单信息推导 URL 路径关键词"""
    theme = form_info.get('themeTemplate', 'normal') or 'normal'
    is_tree = form_info.get('isTree', 'N')
    if is_tree == 'Y':
        return 'cgformTreeList'
    return THEME_TO_URL_KEY.get(theme, 'cgformList')


def build_preview_url(url_key: str, head_id: str) -> str:
    return f'/online/{url_key}/{head_id}'


def get_all_menus(api_base: str, token: str) -> List[dict]:
    resp = api_request(api_base, token, '/sys/permission/list', method='GET')
    return resp.get('result', [])


def find_menu_by_url(menus: List[dict], url: str) -> Optional[dict]:
    """在菜单树中查找指定 url 的菜单"""
    for item in menus:
        if (item.get('url') or '') == url:
            return item
        for child in (item.get('children') or []):
            if (child.get('url') or '') == url:
                return child
            for grandchild in (child.get('children') or []):
                if (grandchild.get('url') or '') == url:
                    return grandchild
    return None


def find_auto_menu(menus: List[dict], auto_pattern: str) -> Optional[dict]:
    """在菜单第二层中查找 AUTO 通配路由菜单"""
    for item in menus:
        for child in (item.get('children') or []):
            url = child.get('url') or ''
            if auto_pattern in url:
                return child
    return None


def create_menu(api_base: str, token: str, menu_data: dict) -> dict:
    return api_request(api_base, token, '/sys/permission/add', menu_data)


def edit_menu(api_base: str, token: str, menu_data: dict) -> dict:
    return api_request(api_base, token, '/sys/permission/edit', menu_data, method='PUT')


def get_role_by_code(api_base: str, token: str, role_code: str) -> Optional[dict]:
    """精确匹配 roleCode 查询角色（API 模糊搜索，需客户端过滤）"""
    resp = api_request(api_base, token,
                       f'/sys/role/list?roleCode={role_code}&pageNo=1&pageSize=50',
                       method='GET')
    records = (resp.get('result') or {}).get('records', [])
    for r in records:
        if r.get('roleCode') == role_code:
            return r
    return None


def grant_menu_to_role(api_base: str, token: str, role_id: str, menu_id: str) -> dict:
    """将菜单授权给角色（追加，不覆盖已有权限）"""
    resp = api_request(api_base, token,
                       f'/sys/permission/queryRolePermission?roleId={role_id}',
                       method='GET')
    raw_ids: List[str] = resp.get('result', []) or []
    perm_ids: List[str] = list(dict.fromkeys(raw_ids))  # 去重并保留顺序
    if menu_id in perm_ids:
        return {'success': True, 'message': '菜单已授权，无需重复操作'}
    last_perm_ids = list(perm_ids)  # 授权前的权限集，作为 lastpermissionIds 传给后端
    perm_ids.append(menu_id)
    return api_request(api_base, token, '/sys/permission/saveRolePermission', {
        'roleId': role_id,
        'permissionIds': ','.join(perm_ids),
        'lastpermissionIds': ','.join(last_perm_ids)
    })


# ====== 核心流程 ======

def mount_to_menu(api_base: str, token: str, config: dict) -> dict:
    """将 Online 表单挂载到系统菜单"""
    import time as _t
    table_name = config['tableName']
    keep_alive = config.get('keepAlive', False)
    parent_id = config.get('parentId', '')
    sort_no = config['sortNo'] if 'sortNo' in config else (int(_t.time()) - 1777530600) % 999999
    role_code = config.get('roleCode', '')

    # Step 1: 查询表单信息
    form_info = get_online_form_info(api_base, token, table_name)
    head_id = form_info['id']
    table_txt = form_info.get('tableTxt', table_name)
    menu_name = config.get('menuName') or table_txt

    url_key = resolve_url_key(form_info)
    component_name = URL_KEY_TO_COMPONENT[url_key]
    preview_url = build_preview_url(url_key, head_id)

    print(f'[Step 1] 表: {table_name} | 描述: {table_txt} | headId: {head_id}')
    print(f'         预览地址: {preview_url} | 组件: {component_name}')

    # 检查菜单是否已存在
    menus = get_all_menus(api_base, token)
    existing = find_menu_by_url(menus, preview_url)
    if existing:
        print(f'[Step 2] 菜单已存在: {existing["name"]} (id={existing["id"]})，跳过创建')
        menu_id = existing['id']
    else:
        # Step 2: 创建菜单
        # menuType: 有 parentId 默认为 1(子菜单)，否则为 0(一级菜单)；config 可显式指定（如 2=按钮权限）
        menu_type = config.get('menuType', 1 if parent_id else 0)
        menu_data = {
            'name': menu_name,
            'url': preview_url,
            'component': '1',
            'componentName': component_name,
            'keepAlive': keep_alive,
            'menuType': menu_type,
            'sortNo': sort_no,
            'route': False,
            'hidden': 0,
            'hideTab': 0,
            'alwaysShow': False,
            'internalOrExternal': False,
        }
        if parent_id:
            menu_data['parentId'] = parent_id
        if menu_type == 2:
            menu_data['status'] = '1'

        resp = create_menu(api_base, token, menu_data)
        if not resp.get('success'):
            raise RuntimeError(f'创建菜单失败: {resp.get("message")}')
        print(f'[Step 2] 菜单创建成功: {menu_name} (keepAlive={keep_alive})')

        # 重新查询获取菜单ID
        menus = get_all_menus(api_base, token)
        created = find_menu_by_url(menus, preview_url)
        if not created:
            raise RuntimeError('创建菜单后未能查到，请检查')
        menu_id = created['id']

    # Step 3-4: 仅在开启缓存时执行
    if keep_alive:
        auto_pattern = URL_KEY_TO_AUTO_PATTERN[url_key]
        auto_menu = find_auto_menu(menus, auto_pattern)

        if not auto_menu:
            print(f'[Step 3] 未找到 AUTO 动态路由菜单（{auto_pattern}），Online 使用静态路由')
            print('         需手动修改前端代码 cgformRouter.ts 添加 keepAlive: true')
        else:
            print(f'[Step 3] 找到 AUTO 菜单: {auto_menu["name"]} (id={auto_menu["id"]})')

            # Step 4: 用完整参数编辑 AUTO 菜单
            if auto_menu.get('keepAlive') and auto_menu.get('componentName') == component_name:
                print(f'[Step 4] AUTO 菜单已配置 (componentName={component_name}, keepAlive=true)，跳过')
            else:
                auto_edit_data = {
                    'id': auto_menu['id'],
                    'menuType': auto_menu.get('menuType', 1),
                    'name': auto_menu['name'],
                    'url': auto_menu['url'],
                    'component': auto_menu.get('component', ''),
                    'componentName': component_name,
                    'icon': auto_menu.get('icon'),
                    'sortNo': auto_menu.get('sortNo', 25),
                    'route': auto_menu.get('route', True),
                    'hidden': auto_menu.get('hidden', True),
                    'hideTab': auto_menu.get('hideTab', False),
                    'keepAlive': True,
                    'alwaysShow': auto_menu.get('alwaysShow', False),
                    'internalOrExternal': auto_menu.get('internalOrExternal', False),
                    'parentId': auto_menu.get('parentId', ''),
                }
                resp = edit_menu(api_base, token, auto_edit_data)
                if not resp.get('success'):
                    raise RuntimeError(f'编辑 AUTO 菜单失败: {resp.get("message")}')
                print(f'[Step 4] AUTO 菜单已更新: componentName={component_name}, keepAlive=true')
    else:
        print('[Step 3-4] 未要求开启缓存，跳过路由缓存配置')

    # Step 5: 授权给角色
    if role_code:
        role = get_role_by_code(api_base, token, role_code)
        if not role:
            print(f'[Step 5] 未找到角色: {role_code}，跳过授权')
        else:
            resp = grant_menu_to_role(api_base, token, role['id'], menu_id)
            if resp.get('success'):
                print(f'[Step 5] 已授权给角色: {role["roleName"]} ({role_code})')
            else:
                print(f'[Step 5] 授权失败: {resp.get("message")}')
    else:
        print('[Step 5] 未指定角色，跳过授权')

    return {'success': True, 'menuId': menu_id, 'previewUrl': preview_url}


def enable_cache_for_menu(api_base: str, token: str, config: dict) -> dict:
    """为已有菜单开启缓存路由"""
    menu_id = config['menuId']

    menus = get_all_menus(api_base, token)

    # 查找目标菜单
    target = None
    for item in menus:
        if item['id'] == menu_id:
            target = item
            break
        for child in (item.get('children') or []):
            if child['id'] == menu_id:
                target = child
                break
        if target:
            break

    if not target:
        raise ValueError(f'未找到菜单: {menu_id}')

    url = target.get('url', '')
    # 推导 url_key
    url_key = None
    for key in URL_KEY_TO_COMPONENT:
        if key in url:
            url_key = key
            break
    if not url_key:
        raise ValueError(f'无法从 URL "{url}" 推导路由类型')

    component_name = URL_KEY_TO_COMPONENT[url_key]

    # 更新业务菜单
    existing_menu_type = target.get('menuType', 0)
    edit_data = {
        'id': target['id'],
        'menuType': existing_menu_type,
        'name': target['name'],
        'url': target['url'],
        'component': target.get('component', '1'),
        'componentName': component_name,
        'icon': target.get('icon'),
        'sortNo': target.get('sortNo', 1),
        'route': target.get('route', False),
        'hidden': target.get('hidden', 0),
        'hideTab': target.get('hideTab', 0),
        'keepAlive': True,
        'alwaysShow': target.get('alwaysShow', False),
        'internalOrExternal': target.get('internalOrExternal', False),
    }
    if target.get('parentId'):
        edit_data['parentId'] = target['parentId']
    if existing_menu_type == 2:
        edit_data['status'] = target.get('status', '1')

    resp = edit_menu(api_base, token, edit_data)
    if not resp.get('success'):
        raise RuntimeError(f'更新菜单失败: {resp.get("message")}')
    print(f'[1/2] 菜单 "{target["name"]}" 已开启 keepAlive')

    # 查找并更新 AUTO 菜单
    auto_pattern = URL_KEY_TO_AUTO_PATTERN[url_key]
    auto_menu = find_auto_menu(menus, auto_pattern)

    if not auto_menu:
        print(f'[2/2] 未找到 AUTO 动态路由，Online 使用静态路由，需手动改代码')
    elif auto_menu.get('keepAlive') and auto_menu.get('componentName') == component_name:
        print(f'[2/2] AUTO 菜单已配置，跳过')
    else:
        auto_edit_data = {
            'id': auto_menu['id'],
            'menuType': auto_menu.get('menuType', 1),
            'name': auto_menu['name'],
            'url': auto_menu['url'],
            'component': auto_menu.get('component', ''),
            'componentName': component_name,
            'icon': auto_menu.get('icon'),
            'sortNo': auto_menu.get('sortNo', 25),
            'route': auto_menu.get('route', True),
            'hidden': auto_menu.get('hidden', True),
            'hideTab': auto_menu.get('hideTab', False),
            'keepAlive': True,
            'alwaysShow': auto_menu.get('alwaysShow', False),
            'internalOrExternal': auto_menu.get('internalOrExternal', False),
            'parentId': auto_menu.get('parentId', ''),
        }
        resp = edit_menu(api_base, token, auto_edit_data)
        if not resp.get('success'):
            raise RuntimeError(f'编辑 AUTO 菜单失败: {resp.get("message")}')
        print(f'[2/2] AUTO 菜单 "{auto_menu["name"]}" 已更新: keepAlive=true')

    return {'success': True}


# ====== 入口 ======

def main():
    parser = argparse.ArgumentParser(description='Online 表单菜单挂载 + 路由缓存配置')
    parser.add_argument('--api-base', required=True, help='JeecgBoot 后端地址')
    parser.add_argument('--token', required=True, help='X-Access-Token')
    parser.add_argument('--config', required=True, help='JSON 配置文件路径')
    args = parser.parse_args()

    with open(args.config, 'r', encoding='utf-8') as f:
        config = json.load(f)

    action = config.get('action', 'mount')

    if action == 'mount':
        result = mount_to_menu(args.api_base, args.token, config)
        print(f'\n完成! menuId={result["menuId"]}, previewUrl={result["previewUrl"]}')

    elif action == 'mount_batch':
        tables = config.get('tables', [])
        for i, table_config in enumerate(tables, 1):
            print(f'\n===== [{i}/{len(tables)}] {table_config["tableName"]} =====')
            merged = {**config, **table_config, 'action': 'mount'}
            merged.pop('tables', None)
            result = mount_to_menu(args.api_base, args.token, merged)
            print(f'完成! menuId={result["menuId"]}')

    elif action == 'enable_cache':
        enable_cache_for_menu(args.api_base, args.token, config)
        print('\n完成!')

    else:
        print(f'未知操作: {action}')
        sys.exit(1)


if __name__ == '__main__':
    main()

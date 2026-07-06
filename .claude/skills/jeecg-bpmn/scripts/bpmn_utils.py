"""
bpmn_utils.py — JeecgBoot BPM 工具函数库

供临时脚本快速导入，避免读取完整的 bpmn_creator.py（2700+行）。

用法:
  import sys
  sys.path.insert(0, r'<skill目录>/scripts')
  from bpmn_utils import api_request, edit_node_config, set_node_field_permissions

"""

import urllib.request
import urllib.parse
import json
import sys
import time
import base64

# 修复 Windows 控制台中文乱码
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8')

# 以下所有函数均从 bpmn_creator.py 提取，逻辑完全一致：


# ====== API 工具 ======

def api_request(api_base, token, path, data=None, method='POST', content_type='application/json'):
    url = f'{api_base}{path}'
    headers = {
        'X-Access-Token': token,
        'X-Sign': '00000000000000000000000000000000',
        'X-Tenant-Id': '1',
        'X-Timestamp': str(int(time.time() * 1000)),
    }
    if content_type == 'application/x-www-form-urlencoded':
        headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
        encoded = urllib.parse.urlencode(data).encode('utf-8')
        req = urllib.request.Request(url, data=encoded, headers=headers, method=method)
    elif data is not None:
        headers['Content-Type'] = 'application/json; charset=UTF-8'
        json_data = json.dumps(data, ensure_ascii=False).encode('utf-8')
        req = urllib.request.Request(url, data=json_data, headers=headers, method=method)
    else:
        req = urllib.request.Request(url, headers=headers, method=method)
    proxy_handler = urllib.request.ProxyHandler({})
    opener = urllib.request.build_opener(proxy_handler)
    resp = opener.open(req)
    return json.loads(resp.read().decode('utf-8'))


def authorize_form(api_base, token, form_id, role_id='f6817f48af4fb3af11b9e8bf182f618b'):
    """为表单添加发起授权（保留已有授权）。

    form_id 取值：
    - formType=1 (Online): 传 Online 表单的 headId
    - formType=2 (DesForm): 传 DesForm 的表单记录 ID
    """
    import time as _time
    headers = {
        'X-Access-Token': token,
        'Content-Type': 'application/json; charset=UTF-8',
    }
    # 1. 查询已有授权
    ts = str(int(_time.time() * 1000))
    url = f'{api_base}/joa/designform/designFormCommuse/getAuthorizedDesignList?principalId={role_id}&authMode=role&_t={ts}'
    req = urllib.request.Request(url, headers=headers)
    resp = json.loads(urllib.request.urlopen(req).read().decode('utf-8'))
    existing_ids = [item['id'] for item in resp.get('result', []) or []]

    # 2. 追加新表单ID
    if form_id not in existing_ids:
        existing_ids.append(form_id)

    # 3. 保存授权
    url = f'{api_base}/joa/designform/designFormCommuse/saveWorkorderAuth/{role_id}'
    data = json.dumps({
        'authMode': 'role',
        'authId': ','.join(existing_ids),
        'subDepartIds': '',
    }, ensure_ascii=False).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers=headers, method='POST')
    resp = json.loads(urllib.request.urlopen(req).read().decode('utf-8'))
    return resp


def get_authorize_form_id(api_base, token, form_config):
    """根据 formLink 配置获取用于授权的表单 ID。

    - formType=1 (Online): 通过 /online/cgform/head/list 查询 headId
    - formType=2 (DesForm): 通过 /desform/queryByIdOrCode 查询表单 ID
    返回 form_id 字符串，查询失败返回 None。
    """
    form_type = str(form_config.get('formType', '2'))
    table_name = form_config.get('formTableName', '')

    if form_type == '1' and table_name:
        # Online 表单 — 查询 headId
        result = api_request(api_base, token,
                             f'/online/cgform/head/list?tableName={table_name}&pageNo=1&pageSize=1',
                             method='GET')
        if result.get('success'):
            records = result.get('result', {}).get('records', [])
            if records:
                return records[0]['id']
    elif form_type == '2' and table_name:
        # DesForm — 查询表单 ID
        result = api_request(api_base, token,
                             f'/desform/queryByIdOrCode?desformCode={table_name}',
                             method='GET')
        if result.get('success') and result.get('result'):
            return result['result']['id']
    return None


def deploy_process(api_base, token, process_id):
    """发布流程 — PUT /act/process/extActProcess/deployProcess"""
    result = api_request(api_base, token, '/act/process/extActProcess/deployProcess',
                         data={'id': process_id}, method='PUT')
    return result


def get_desform_fields(api_base, token, form_code):
    """查询设计器表单的所有字段，返回 {字段名: {model, key, type}} 映射。

    递归遍历 desformDesignJson 中所有控件（含 card/grid/tabs 嵌套），
    排除纯布局控件（text, grid, card, tabs, divider）。
    """
    result = api_request(api_base, token,
                         f'/desform/queryByIdOrCode?desformCode={form_code}',
                         method='GET')
    if not result.get('success') or not result.get('result'):
        return {}

    design = json.loads(result['result']['desformDesignJson'])
    fields = {}

    def _walk(items):
        for w in items:
            wtype = w.get('type', '')
            # 优先用 name，其次用 label（Word布局字段名在 name 中，label 为空）
            name = w.get('name', '') or w.get('label', '')
            model = w.get('model', '')
            key = w.get('key', '')
            # 排除纯布局控件
            if wtype not in ('text', 'grid', 'card', 'tabs', 'divider', '') and model and name:
                fields[name] = {'model': model, 'key': key, 'type': wtype}
            # 递归子节点
            if 'list' in w and w['list']:
                _walk(w['list'])
            if 'columns' in w and w['columns']:
                for col in w['columns']:
                    if 'list' in col and col['list']:
                        _walk(col['list'])

    _walk(design.get('list', []))
    return fields


def get_online_form_fields(api_base, token, table_name):
    """查询 Online 表单的所有字段，返回 {字段名: {model, key, type}} 映射。

    Args:
        api_base: JeecgBoot 后端地址
        token: X-Access-Token
        table_name: 数据库表名（如 'crm_customer_apply'）

    Returns:
        dict: {字段名: {model, key, type}}，失败返回 {}
    """
    # Step 1: 通过表名查询 headId
    head_result = api_request(api_base, token,
                              f'/online/cgform/head/list?tableName={table_name}&pageNo=1&pageSize=10',
                              method='GET')
    records = head_result.get('result', {})
    if isinstance(records, dict):
        records = records.get('records', [])
    if not records:
        return {}
    head_id = records[0].get('id', '')
    if not head_id:
        return {}

    # Step 2: 通过 headId 查询字段列表
    field_result = api_request(api_base, token,
                               f'/online/cgform/field/listByHeadId?headId={head_id}',
                               method='GET')
    field_list = field_result.get('result', []) or []
    if isinstance(field_list, dict):
        field_list = field_list.get('records', [])

    fields = {}
    skip_fields = {'id', 'create_by', 'create_time', 'update_by', 'update_time', 'sys_org_code'}
    for f in field_list:
        db_field = f.get('dbFieldName', '')
        label = f.get('dbFieldTxt', '') or db_field
        field_type = f.get('fieldShowType', 'text')
        if db_field and db_field not in skip_fields:
            fields[label] = {'model': db_field, 'key': '', 'type': field_type}
            # 同时建立 model → info 的别名，支持直接用字段名匹配
            fields[db_field] = {'model': db_field, 'key': '', 'type': field_type}
    return fields


def set_node_field_permissions(api_base, token, process_id, node_code, form_code,
                               field_permissions, form_type='2'):
    """批量设置节点字段权限。

    Args:
        api_base: JeecgBoot 后端地址
        token: X-Access-Token
        process_id: 流程ID
        node_code: 节点编码（如 'task_draft'）
        form_code: 表单编码/表名（DesForm传表单编码，Online传数据库表名）
        field_permissions: 字段权限配置列表，每项格式：
            {
                "field": "字段名称（中文）或字段model",
                "visible": true,     # 可见（默认true）
                "editable": true,    # 可编辑（默认true）
                "required": false    # 必填（默认false）
            }
            联动规则：
              - required=true 时自动强制 visible=true, editable=true
              - visible=false 时自动强制 editable=false, required=false
        form_type: 表单类型，'1'=Online, '2'=DesForm（默认'2'）

    Returns:
        dict: {success: bool, updated: int, errors: list}
    """
    # 根据表单类型查询字段映射
    if form_type == '1':
        fields_map = get_online_form_fields(api_base, token, form_code)
    else:
        fields_map = get_desform_fields(api_base, token, form_code)
    if not fields_map:
        return {'success': False, 'updated': 0, 'errors': ['无法获取表单字段信息']}

    # 也建一个 model → field_info 的映射，支持用 model 直接匹配
    model_map = {info['model']: {'label': name, **info} for name, info in fields_map.items()}

    batch_data = []
    errors = []

    for perm in field_permissions:
        field_ref = perm.get('field', '')
        visible = perm.get('visible', True)
        editable = perm.get('editable', True)
        required = perm.get('required', False)

        # 联动规则：
        # 1. 隐藏时强制不可编辑+非必填
        # 2. 可编辑时强制可见
        # 3. 必填时强制可见+可编辑
        if not visible:
            editable = False
            required = False
        if editable:
            visible = True
        if required:
            visible = True
            editable = True

        # 查找字段 model 和 key
        field_info = fields_map.get(field_ref) or model_map.get(field_ref)
        if not field_info:
            errors.append(f'字段 "{field_ref}" 未找到')
            continue

        model = field_info['model']
        key = field_info.get('key', '')
        label = field_ref if field_ref in fields_map else field_info.get('label', field_ref)

        # Online 表单 ruleCode 格式：online:{表名}:{字段名}；DesForm 直接用 model/key
        if form_type == '1':
            rule_code = f'online:{form_code}:{model}'
            desform_key = None
        else:
            rule_code = model
            desform_key = key

        base_record = {
            'formType': form_type,
            'formBizCode': form_code,
            'processId': process_id,
            'processNodeCode': node_code,
            'ruleCode': rule_code,
            'ruleName': label,
            'required': 1 if required else 0,
        }
        if desform_key is not None:
            base_record['desformComKey'] = desform_key

        # ruleType=1: 可见性
        batch_data.append({**base_record, 'ruleType': '1', 'status': '1' if visible else '0'})
        # ruleType=2: 可编辑性（注意：status 与勾选状态相反，'0'=勾选=可编辑，'1'=未勾选=禁用）
        batch_data.append({**base_record, 'ruleType': '2', 'status': '0' if editable else '1'})

    if not batch_data:
        return {'success': False, 'updated': 0, 'errors': errors or ['无有效字段权限配置']}

    # 查询已有权限记录，获取 id 和 ruleName 用于更新（避免"规则编码已存在"错误）
    existing_result = api_request(api_base, token,
        f'/act/process/extActProcessNodePermission/list?processId={process_id}'
        f'&processNodeCode={node_code}&pageNo=1&pageSize=200',
        method='GET')
    existing_records = existing_result.get('result', {})
    if isinstance(existing_records, dict):
        existing_records = existing_records.get('records', [])
    # 建立 (ruleCode, ruleType) → 完整记录 映射
    existing_map = {}
    for rec in existing_records:
        k = (rec.get('ruleCode', ''), str(rec.get('ruleType', '')))
        existing_map[k] = rec

    # 合并已有记录的 id，并保留原始 ruleName（不得覆盖已有名称）
    for item in batch_data:
        lookup_key = (item['ruleCode'], item['ruleType'])
        if lookup_key in existing_map:
            existing = existing_map[lookup_key]
            item['id'] = existing.get('id', '')
            # 保留原 ruleName，防止将中文名覆盖为英文 model
            if existing.get('ruleName'):
                item['ruleName'] = existing['ruleName']

    result = api_request(api_base, token,
                         '/act/process/extActProcessNodePermission/saveOrUpdateBatch',
                         data=batch_data)
    success = result.get('success', False)
    return {
        'success': success,
        'updated': len(batch_data) // 2,
        'errors': errors,
        'message': result.get('message', ''),
    }


def edit_node_config(api_base, token, process_id, node_code, node_settings):
    """编辑流程节点配置（表单可编辑、抄送、转办、加签、驳回等开关）。

    Args:
        api_base: JeecgBoot 后端地址
        token: X-Access-Token
        process_id: 流程ID
        node_code: 节点编码
        node_settings: 需要更新的属性字典，可选 key:
            formEditStatus: '1'=可编辑
            ccStatus: '1'=启用抄送
            selnextUserStatus: '1'=选择下一步处理人
            msgStatus: '1'=消息通知
            addSignStatus: '1'=加签
            transferStatus: '1'=转办
            rejectStatus: '1'=驳回
            modelAndView: PC端表单地址
            modelAndViewMobile: 移动端表单地址

    Returns:
        dict: API 返回结果
    """
    # 查询节点记录
    result = api_request(api_base, token,
        f'/act/process/extActProcessNode/list?processId={process_id}&pageNo=1&pageSize=50',
        method='GET')
    records = result.get('result', {})
    if isinstance(records, dict):
        records = records.get('records', [])

    for node in records:
        if node.get('processNodeCode') == node_code:
            # 合并更新属性
            node.update(node_settings)
            return api_request(api_base, token,
                '/act/process/extActProcessNode/edit',
                data=node, method='PUT')

    return {'success': False, 'message': f'节点 {node_code} 未找到'}

"""
JeecgBoot OA 应用一键创建脚本
==============================
一次性完成：表单创建 → 流程创建 → 流程发布 → 表单关联 → 角色授权

用法:
  python bpmn_oa.py --api-base <URL> --token <TOKEN> --config <config.json>
  python bpmn_oa.py --api-base <URL> --token <TOKEN> --config <config.json> --force

参数:
  --api-base       JeecgBoot 后端地址（如 http://localhost:8080/jeecgboot）
  --token          X-Access-Token
  --config         JSON 配置文件路径
  --force          强制覆盖已存在的表单
"""

import argparse
import json
import sys
import os
import urllib.request
import urllib.parse
import time

# 修复 Windows 控制台中文乱码
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
_SKILL_DIR = os.path.dirname(_SCRIPT_DIR)
_SKILLS_ROOT = os.path.dirname(_SKILL_DIR)

# 定位 desform 和 bpmn 脚本目录
_DESFORM_SCRIPTS = os.path.join(_SKILLS_ROOT, 'jeecg-desform', 'scripts')
_BPMN_SCRIPTS = os.path.join(_SKILLS_ROOT, 'jeecg-bpmn', 'scripts')

# 将 desform 脚本目录加入 path（需要 desform_utils）
sys.path.insert(0, _DESFORM_SCRIPTS)

# 导入 desform 和 bpmn 模块
import importlib.util


def _load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


desform_creator = _load_module('desform_creator', os.path.join(_DESFORM_SCRIPTS, 'desform_creator.py'))
bpmn_creator = _load_module('bpmn_creator', os.path.join(_BPMN_SCRIPTS, 'bpmn_creator.py'))

# 从 desform_utils 导入核心函数
from desform_utils import init_api, get_form_id, create_form

# ====== 授权相关 ======

DEFAULT_ROLE_ID = 'f6817f48af4fb3af11b9e8bf182f618b'


def auth_api_request(api_base, token, path, data=None, method='GET'):
    """调用授权 API"""
    url = f'{api_base}{path}'
    headers = {
        'X-Access-Token': token,
        'Content-Type': 'application/json; charset=UTF-8',
    }
    if data is not None:
        json_data = json.dumps(data, ensure_ascii=False).encode('utf-8')
        req = urllib.request.Request(url, data=json_data, headers=headers, method=method)
    else:
        req = urllib.request.Request(url, headers=headers, method=method)
    resp = urllib.request.urlopen(req)
    return json.loads(resp.read().decode('utf-8'))


def get_existing_auth_ids(api_base, token, role_id):
    """查询角色已有的授权表单ID列表"""
    ts = str(int(time.time() * 1000))
    path = f'/joa/designform/designFormCommuse/getAuthorizedDesignList?principalId={role_id}&authMode=role&_t={ts}'
    result = auth_api_request(api_base, token, path, method='GET')
    if result.get('success') and result.get('result'):
        return [item['id'] for item in result['result']]
    return []


def save_auth(api_base, token, role_id, auth_ids, auth_mode='role'):
    """保存授权（追加新表单ID，保留已有授权）"""
    path = f'/joa/designform/designFormCommuse/saveWorkorderAuth/{role_id}'
    data = {
        'authMode': auth_mode,
        'authId': ','.join(auth_ids),
        'subDepartIds': '',
    }
    return auth_api_request(api_base, token, path, data=data, method='POST')


def authorize_form(api_base, token, form_id, role_id=DEFAULT_ROLE_ID, auth_mode='role'):
    """为表单添加角色授权（保留已有授权）"""
    existing_ids = get_existing_auth_ids(api_base, token, role_id)
    if form_id not in existing_ids:
        existing_ids.append(form_id)
    result = save_auth(api_base, token, role_id, existing_ids, auth_mode)
    return result, len(existing_ids) - 1  # 返回结果和原有授权数量


# ====== OA 子流程（Scenario A）一键创建 ======

def _setup_oa_subprocess(api_base, token, sub_config, form_code):
    """创建并部署 Scenario A OA 子流程（与主流程共享同一 DesForm 表单）。

    Scenario A 规则（来自 bpmn-call-activity.md）：
    - 子流程节点不能有 draft:true（否则引发 FK 约束错误）
    - 不使用 inVars/outVars（字段通过 JG_SUB_MAIN_PROCESS_ID 透传共享）
    - 必须 deploy #1 → edit_node_config(formEditStatus=1) → deploy #2

    返回子流程 processKey（供主流程 callActivity.calledElement 使用），失败返回 None。
    """
    sub_name = sub_config.get('processName', '子流程')
    print(f'  创建子流程: {sub_name}')

    # 移除 draft:true（Scenario A 限制）
    for node in sub_config.get('nodes', []):
        if node.pop('draft', None):
            print(f'  [子流程] 警告：节点 {node["id"]} 含 draft:true，已自动移除（Scenario A 限制）')

    sub_config = bpmn_creator.expand_config(sub_config)
    sub_xml = bpmn_creator.build_bpmn_xml(sub_config)

    r = bpmn_creator.save_process(api_base, token, sub_config, sub_xml)
    if not r.get('success'):
        print(f'  [子流程] 创建失败: {r.get("msg", "")}')
        return None

    sub_pid = r.get('obj', '')
    sub_key = sub_config['processKey']
    if not sub_pid:
        try:
            import urllib.parse as _up
            q = _up.urlencode({'pageNo': 1, 'pageSize': 100})
            qr = bpmn_creator.api_request(api_base, token,
                                          f'/act/process/extActProcess/list?{q}', method='GET')
            for rec in (qr.get('result') or {}).get('records', []):
                if rec.get('processKey') == sub_key:
                    sub_pid = rec.get('id', '')
                    break
        except Exception as e:
            print(f'  [子流程] 查询 ID 失败: {e}')

    if not sub_pid:
        print(f'  [子流程] 无法获取子流程 ID，跳过后续配置')
        return None

    print(f'  [子流程] ID={sub_pid}, Key={sub_key}')

    # 发布 #1
    dr1 = bpmn_creator.deploy_process(api_base, token, sub_pid)
    if not dr1.get('success'):
        print(f'  [子流程] 初次发布失败: {dr1.get("message", "")}')

    # 关联表单（使用与主流程相同的 form_code）
    # 注意：此绑定是临时的——为了让 formEditStatus 生效必须先有表单关联，
    # 但 Scenario A 中主流程与子流程共用同一 form_code，后端有唯一约束，
    # 因此在本函数结尾会自动删除子流程的表单绑定，让主流程重新关联（见下方规则8修复）。
    sub_form_link = {
        'formType': '2',
        'relationCode': form_code,
        'formTableName': form_code,
        'flowStatusCol': 'bpm_status',
        'titleExp': sub_config.get('titleExp', sub_name),
    }
    bpmn_creator.link_form(api_base, token, sub_pid, sub_form_link)

    # 为所有用户任务节点设置 formEditStatus=1（Scenario A 必须，否则子流程审批时表单只读）
    pc_url, mobile_url = bpmn_creator._build_form_url_pair('desform', form_code, 'edit')
    node_list_r = bpmn_creator.api_request(
        api_base, token,
        f'/act/process/extActProcessNode/list?processId={sub_pid}&pageNo=1&pageSize=50',
        method='GET')
    node_records = (node_list_r.get('result') or {}).get('records', [])
    for nr in node_records:
        nc = nr.get('processNodeCode', '')
        if not nc:
            continue
        nr['formEditStatus'] = '1'
        nr['modelAndView'] = pc_url
        nr['modelAndViewMobile'] = mobile_url
        cfg_str = nr.get('nodeConfigJson', '{}') or '{}'
        try:
            cfg = json.loads(cfg_str)
            cfg['formEditStatus'] = True
            nr['nodeConfigJson'] = json.dumps(cfg, ensure_ascii=False)
        except Exception:
            pass
        r2 = bpmn_creator.api_request(
            api_base, token, '/act/process/extActProcessNode/edit', data=nr, method='PUT')
        status = '✓' if r2.get('success') else f'✗ {r2.get("message", "")}'
        print(f'  [子流程] {nc}: formEditStatus=1 {status}')

    # 发布 #2（使配置生效）
    dr2 = bpmn_creator.deploy_process(api_base, token, sub_pid)
    if dr2.get('success'):
        print(f'  [子流程] 配置发布成功')
    else:
        print(f'  [子流程] 配置发布失败: {dr2.get("message", "")}')

    # ── 规则8 修复 ──────────────────────────────────────────────────────────
    # Scenario A：子流程与主流程共用同一 form_code，后端 relationCode 唯一约束。
    # 子流程的表单绑定已不再需要（运行时通过 JG_SUB_MAIN_PROCESS_ID 共享数据），
    # 必须在此删除，否则主流程 link_form 会报"编码重复或表名已被授权流程！"。
    try:
        import urllib.parse as _up
        q = _up.urlencode({'processId': sub_pid, 'pageNo': 1, 'pageSize': 10})
        sf_r = bpmn_creator.api_request(
            api_base, token,
            f'/act/process/extActProcessForm/list?{q}', method='GET')
        for rec in (sf_r.get('result') or {}).get('records', []):
            del_r = bpmn_creator.api_request(
                api_base, token,
                f'/act/process/extActProcessForm/delete?id={rec["id"]}',
                method='DELETE')
            status = '✓' if del_r.get('success') else f'✗ {del_r.get("message","")}'
            print(f'  [子流程] 解除临时表单绑定 {status}（主流程稍后重新关联）')
    except Exception as _e:
        print(f'  [子流程] 解除表单绑定时出错: {_e}（可手动删除后重新关联主流程）')
    # ────────────────────────────────────────────────────────────────────────

    return sub_key


# ====== 主流程 ======

def main():
    parser = argparse.ArgumentParser(description='JeecgBoot OA 应用一键创建工具')
    parser.add_argument('--api-base', required=True, help='JeecgBoot 后端地址')
    parser.add_argument('--token', required=True, help='X-Access-Token')
    parser.add_argument('--config', required=True, help='JSON 配置文件路径')
    parser.add_argument('--force', action='store_true', help='强制覆盖已存在的表单')
    args = parser.parse_args()

    with open(args.config, 'r', encoding='utf-8') as f:
        config = json.load(f)

    app_name = config.get('appName', config['form']['formName'])
    form_config = config['form']
    process_config = config['process']
    auth_config = config.get('auth', {})
    role_id = auth_config.get('roleId', DEFAULT_ROLE_ID)
    auth_mode = auth_config.get('authMode', 'role')

    print(f'\n{"=" * 50}')
    print(f'开始创建 OA 应用: {app_name}')
    print(f'{"=" * 50}')

    # ========== 第0步：创建子流程（若配置了 subprocess 键）==========
    subprocess_config = config.get('subprocess')
    if subprocess_config:
        print(f'\n[子流程] 创建 Scenario A OA 子流程...')
        form_code_for_sub = config['form']['formCode']
        sub_key = _setup_oa_subprocess(args.api_base, args.token,
                                        subprocess_config, form_code_for_sub)
        if sub_key:
            # 自动填充主流程中未指定 calledElement 的 callActivity 节点
            for node in process_config.get('nodes', []):
                if node.get('type') == 'callActivity' and not node.get('calledElement'):
                    node['calledElement'] = sub_key
                    print(f'  [主流程] 已自动填充 callActivity "{node["id"]}" '
                          f'calledElement = {sub_key}')
        else:
            print(f'  [子流程] 创建失败，主流程 callActivity 将使用原配置中的 calledElement')

    # ========== 第1步：创建表单 ==========
    print(f'\n[1/4] 创建表单...')

    form_name = form_config['formName']
    form_code = form_config['formCode']
    layout = form_config.get('layout', 'auto')
    title_index = form_config.get('titleIndex', 0)

    init_api(args.api_base, args.token)

    # 防覆盖检查
    existing_id, _ = get_form_id(form_code)
    if existing_id and not args.force:
        print(f'  [阻止] 表单 {form_code} 已存在 (ID={existing_id})')
        print(f'  如需覆盖，请加 --force 参数')
        sys.exit(1)

    # 构建控件列表（预处理 oa-approval-comments 类型）
    fields = form_config.get('fields', [])
    widgets = []
    for fd in fields:
        if fd.get('type') == 'oa-approval-comments':
            # 将审批意见组件转换为禁用的 textarea（word 布局自动处理 grid）
            converted = {
                'name': fd['name'],
                'type': 'textarea',
                'required': False,
            }
            widget = desform_creator.build_widget(converted)
            # 设置 disabled=True（由流程节点控制启用）
            if isinstance(widget, tuple):
                w = widget[0]
            else:
                w = widget
            # 深入 card → list → widget 设置 disabled
            if 'list' in w:
                for item in w['list']:
                    if 'options' in item:
                        item['options']['disabled'] = True
            widgets.append(widget)
        else:
            widget = desform_creator.build_widget(fd)
            widgets.append(widget)

    form_id, title_model = create_form(form_name, form_code, widgets,
                                        title_index=title_index, layout=layout)
    print(f'  表单创建成功: ID={form_id}, 编码={form_code}')

    # ========== 第2步：创建流程 ==========
    print(f'\n[2/4] 创建流程...')

    # 自动补全 formLink（关联刚创建的表单）
    process_config['formLink'] = {
        'formType': '2',
        'relationCode': form_code,
        'formTableName': form_code,
        'flowStatusCol': 'bpm_status',
        'titleExp': process_config.get('titleExp', f'{app_name}'),
    }

    process_config = bpmn_creator.expand_config(process_config)
    bpmn_xml = bpmn_creator.build_bpmn_xml(process_config)

    result = bpmn_creator.save_process(args.api_base, args.token, process_config, bpmn_xml)
    if not result.get('success'):
        print(f'  流程创建失败: {result.get("msg", "")}')
        sys.exit(1)

    process_id = result.get('obj', '')
    process_key = process_config['processKey']
    # obj=null 说明是更新操作（key 已存在），按 processKey 精确查询真实 ID
    if not process_id:
        try:
            import urllib.parse as _up
            q = _up.urlencode({'pageNo': 1, 'pageSize': 100})
            qr = bpmn_creator.api_request(args.api_base, args.token,
                                          f'/act/process/extActProcess/list?{q}', method='GET')
            for rec in (qr.get('result') or {}).get('records', []):
                if rec.get('processKey') == process_key:
                    process_id = rec.get('id', '')
                    print(f'  [fallback] obj=null，按 processKey 查得 ID: {process_id}')
                    break
            if not process_id:
                print(f'  [警告] 按 processKey={process_key} 未找到流程ID，后续步骤可能失败')
        except Exception as _e:
            print(f'  [警告] 查询流程ID失败: {_e}')
    print(f'  流程创建成功: ID={process_id}, Key={process_key}')

    # ========== 第3步：发布流程 + 关联表单 ==========
    print(f'\n[3/4] 发布流程并关联表单...')

    # 发布
    deploy_result = bpmn_creator.deploy_process(args.api_base, args.token, process_id)
    if deploy_result.get('success'):
        print(f'  流程发布成功')
    else:
        print(f'  流程发布失败: {deploy_result.get("message", "")}')

    # 关联表单
    form_link_config = process_config.get('formLink')
    if form_link_config:
        link_result = bpmn_creator.link_form(args.api_base, args.token, process_id, form_link_config)
        if link_result.get('success'):
            print(f'  表单关联成功')
        else:
            print(f'  表单关联失败: {link_result.get("message", "")}')

    # 设置草稿节点表单可编辑 + 表单地址（调用 bpmn_creator 的通用函数）
    # 根据表单类型自动生成表单地址
    # ⚠️ 必须用 _build_form_url_pair() 生成 URL，禁止手动拼接 f-string。
    #    f-string 中 {{DOMAIN_URL}} 需要 4 个花括号，而 ${BPM_DES_DATA_ID} 只需 2 个，
    #    混用容易出现 ${{BPM_DES_DATA_ID}} 多余括号的 bug。
    form_type = process_config.get('formLink', {}).get('formType', '2')
    if form_type == '2':
        # 设计器表单(desform)：使用 _build_form_url_pair 生成正确 URL
        pc_url, mobile_url = bpmn_creator._build_form_url_pair('desform', form_code, 'edit')
        form_url_config = {
            'modelAndView': pc_url,
            'modelAndViewMobile': mobile_url,
        }
    elif form_type == '1':
        # Online表单
        form_url_config = {
            'modelAndView': 'super/bpm/process/components/OnlineFormOpt',
            'modelAndViewMobile': 'check/onlineForm/flowedit',
        }
    else:
        form_url_config = None

    updated = bpmn_creator.set_draft_nodes_editable(
        args.api_base, args.token, process_id, process_config,
        form_url_config=form_url_config)
    if updated:
        print(f'  节点表单可编辑已设置: {", ".join(updated)}')
        if form_url_config:
            print(f'  表单地址已设置: PC={form_url_config.get("modelAndView", "")}')

    # ========== 第4步：节点字段权限（可选） ==========
    node_permissions = config.get('nodePermissions', {})
    if node_permissions:
        print(f'\n[4/6] 配置节点字段权限...')
        for node_code, field_perms in node_permissions.items():
            perm_result = bpmn_creator.set_node_field_permissions(
                args.api_base, args.token, process_id, node_code, form_code,
                field_perms, form_type='2')
            if perm_result.get('success'):
                print(f'  {node_code}: {perm_result["updated"]} 个字段权限已设置')
                if perm_result.get('errors'):
                    for err in perm_result['errors']:
                        print(f'    [警告] {err}')
            else:
                print(f'  {node_code}: 设置失败 - {perm_result.get("errors", [])}')

        # ⚠️ 关键：为所有含可编辑字段的非 draft 节点开启表单可编辑（formEditStatus=1）
        # 字段级 editable 权限不会覆盖节点级 formEditStatus=0（只读锁），必须两层都打开
        draft_node_ids = {n['id'] for n in process_config.get('nodes', []) if n.get('draft')}
        editable_non_draft = [
            node_code for node_code, field_perms in node_permissions.items()
            if node_code not in draft_node_ids
            and any(p.get('editable', True) and p.get('visible', True) for p in field_perms)
        ]
        if editable_non_draft and form_url_config:
            print(f'\n[4.5/6] 为审批节点开启表单可编辑（formEditStatus）...')
            node_list_result = bpmn_creator.api_request(
                args.api_base, args.token,
                f'/act/process/extActProcessNode/list?processId={process_id}&pageNo=1&pageSize=50',
                method='GET')
            node_records = (node_list_result.get('result') or {}).get('records', [])
            for node_rec in node_records:
                nc = node_rec.get('processNodeCode', '')
                if nc in editable_non_draft:
                    node_rec['formEditStatus'] = '1'
                    node_rec['modelAndView'] = form_url_config.get('modelAndView', '')
                    node_rec['modelAndViewMobile'] = form_url_config.get('modelAndViewMobile', '')
                    cfg_str = node_rec.get('nodeConfigJson', '{}') or '{}'
                    try:
                        cfg = json.loads(cfg_str)
                        cfg['formEditStatus'] = True
                        node_rec['nodeConfigJson'] = json.dumps(cfg, ensure_ascii=False)
                    except Exception:
                        pass
                    r = bpmn_creator.api_request(
                        args.api_base, args.token,
                        '/act/process/extActProcessNode/edit', data=node_rec, method='PUT')
                    status = '✓' if r.get('success') else f'✗ {r.get("message","")}'
                    print(f'  {nc}: formEditStatus=1  {status}')

        step_label = '6/6'
    else:
        step_label = '5/5'

    # ========== 第5步：重新发布流程（节点配置修改后必须重新发布才生效） ==========
    redeploy_step = '5/5' if not node_permissions else '5/6'
    print(f'\n[{redeploy_step}] 重新发布流程（使节点配置生效）...')
    redeploy_result = bpmn_creator.deploy_process(args.api_base, args.token, process_id)
    if redeploy_result.get('success'):
        print(f'  重新发布成功')
    else:
        print(f'  重新发布失败: {redeploy_result.get("message", "")}')

    # ========== 角色授权 ==========
    print(f'\n[{step_label}] 授权给管理员角色...')

    auth_result, existing_count = authorize_form(
        args.api_base, args.token, form_id, role_id, auth_mode
    )
    if auth_result.get('success'):
        print(f'  授权成功（保留原有 {existing_count} 条授权）')
    else:
        print(f'  授权失败: {auth_result.get("message", "")}')

    # ========== 输出汇总 ==========
    print(f'\n{"=" * 50}')
    print(f'OA 应用创建完成')
    print(f'{"=" * 50}')
    print(f'  应用名称: {app_name}')
    print(f'')
    print(f'  [表单] ID: {form_id} | 编码: {form_code} | 布局: {layout}')
    print(f'  [流程] ID: {process_id} | Key: {process_key} | 已发布（含节点配置）')
    print(f'  [关联] 表单已关联到流程')
    if node_permissions:
        print(f'  [权限] 已配置 {len(node_permissions)} 个节点的字段权限')
    print(f'  [授权] 已授权给管理员角色（保留原有 {existing_count} 条授权）')
    print(f'{"=" * 50}')


if __name__ == '__main__':
    main()

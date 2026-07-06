"""
jimureport_core.py — Session、签名、ID生成等基础工具
"""
import json
import hashlib
import random
import string
import time

import requests

DEFAULT_BASE_URL = "<api_base>"
DEFAULT_TOKEN    = "<token>"
DEFAULT_TENANT   = "2"
SIGN_SECRET      = "dd05f1c54d63749eda95f9fa6d49v442a"

SIGNED_PATHS = [
    "/queryFieldBySql", "/executeSelectApi", "/loadTableData",
    "/testConnection",  "/download/image",   "/dictCodeSearch",
    "/getDataSourceByPage", "/getDataSourceById",
    "/exportReportConfig", "/exportAllExcelStream", "/exportPdfStream", "/export/word",
]


def _compute_sign(params: dict) -> str:
    sp: dict[str, str] = {}
    for k, v in params.items():
        if v is None:
            continue
        if isinstance(v, bool):
            sp[k] = str(v).lower()
        elif isinstance(v, (int, float)):
            sp[k] = str(v)
        elif isinstance(v, (dict, list)):
            sp[k] = json.dumps(v, ensure_ascii=False, separators=(",", ":"))
        else:
            sp[k] = str(v)
    sorted_json = json.dumps(dict(sorted(sp.items())), ensure_ascii=False, separators=(",", ":"))
    return hashlib.md5((sorted_json + SIGN_SECRET).encode()).hexdigest().upper()


class Session:
    """轻量封装：自动处理签名、Token、代理绕过。"""

    def __init__(self, base_url: str = DEFAULT_BASE_URL, token: str = DEFAULT_TOKEN):
        self.base_url = base_url.rstrip("/")
        self._s = requests.Session()
        self._s.trust_env = False
        adapter = requests.adapters.HTTPAdapter(pool_connections=5, pool_maxsize=10)
        self._s.mount("http://", adapter)
        self._s.mount("https://", adapter)
        self._s.headers.update({
            "X-Access-Token": token,
            "Content-Type": "application/json",
        })

    def upload(self, path: str, files: dict, params: dict | None = None) -> dict:
        """multipart 文件上传，临时移除 Content-Type 让 requests 自动生成 boundary。"""
        url = self.base_url + path
        p = dict(params) if params else {}
        p.setdefault("token", self._s.headers.get("X-Access-Token", ""))
        resp = self._s.post(url, files=files, params=p,
                            headers={"Content-Type": None})
        resp.raise_for_status()
        return resp.json()

    def request(self, path: str, data: dict | None = None, method: str = "POST") -> dict:
        for attempt in range(3):
            headers = {}
            need_sign = data is not None and any(path.endswith(p) for p in SIGNED_PATHS)
            url = self.base_url + path
            if method.upper() == "GET":
                params = dict(data) if data else {}
                if need_sign:
                    params["token"] = self._s.headers.get("X-Access-Token", "")
                    headers["X-TIMESTAMP"] = str(int(time.time() * 1000))
                    headers["X-Sign"] = _compute_sign(params)
                resp = self._s.request(method, url, params=params, headers=headers)
            else:
                if need_sign:
                    headers["X-TIMESTAMP"] = str(int(time.time() * 1000))
                    headers["X-Sign"] = _compute_sign(data)
                resp = self._s.request(method, url, json=data, headers=headers)
            resp.raise_for_status()
            result = resp.json()
            if not result.get("success"):
                msg = result.get("message", "")
                if path.endswith("/save") and "Duplicate entry" in msg and "uniq_jmreport_code" in msg:
                    if data and "designerObj" in data:
                        obj = json.loads(data["designerObj"])
                        obj["code"] = gen_code()
                        data = {**data, "designerObj": json.dumps(obj, ensure_ascii=False)}
                    time.sleep(1.1)
                    continue
                raise RuntimeError(f"[{path}] 失败: {msg}\n{result}")
            return result
        raise RuntimeError(f"[{path}] 重试3次仍失败")

    def get(self, path: str) -> dict:
        return self.request(path, method="GET")


def gen_id() -> str:
    return str(int(time.time() * 1000) * 1_000_000 + random.randint(100_000, 999_999))


def gen_code() -> str:
    return str(int(time.time() * 1000)) + str(random.randint(100, 999))


def gen_layer() -> str:
    return "lyr_" + "".join(random.choices(string.ascii_lowercase + string.digits, k=10))


def col_letter(idx: int) -> str:
    result, n = "", idx + 1
    while n:
        n, r = divmod(n - 1, 26)
        result = chr(65 + r) + result
    return result

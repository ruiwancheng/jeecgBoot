// harness 测试共享 API 客户端（api + login + check 断言带根因输出 + findDoc）
// 用法: const { createClient } = require('../helpers/api'); const c = createClient('http://localhost:8080/jeecg-boot');

function createClient(base) {
  let token = null;
  let lastReq = null;
  let lastRes = null;

  async function login(username = 'mes_admin', password = '123456') {
    const r = await api('POST', '/sys/login', { username, password });
    if (r.code !== 200) throw new Error('登录失败: ' + r.message);
    token = r.result.token;
    return token;
  }

  async function api(method, path, body) {
    const opts = { method, headers: { 'Content-Type': 'application/json' } };
    if (token) opts.headers['X-Access-Token'] = token;
    let url = base + path;
    if (body && (method === 'GET' || method === 'DELETE')) {
      url += (path.includes('?') ? '&' : '?') + new URLSearchParams(body).toString();
    } else if (body) {
      opts.body = JSON.stringify(body);
    }
    lastReq = `${method} ${path}${body ? ' ' + JSON.stringify(body).slice(0, 150) : ''}`;
    const res = await fetch(url, opts);
    lastRes = await res.json();
    return lastRes;
  }

  let passed = 0, failed = 0;
  function check(name, ok, detail) {
    if (ok) { passed++; console.log(`  ✅ ${name}: ${detail ?? ''}`); }
    else {
      failed++;
      console.error(`  ❌ ${name}: ${detail ?? ''}`);
      console.error(`     请求: ${lastReq}`);
      console.error(`     响应: ${JSON.stringify(lastRes)?.slice(0, 250)}`);
    }
  }

  async function findDoc(listPath, code) {
    const r = await api('GET', `${listPath}?pageNo=1&pageSize=5&code=${code}`);
    return r.result?.records?.[0];
  }

  function summary(title) {
    console.log(`\n===== ${title}: ${passed} 通过, ${failed} 失败 =====`);
    return failed === 0;
  }

  return { login, api, check, findDoc, summary, get token() { return token; } };
}

module.exports = { createClient };

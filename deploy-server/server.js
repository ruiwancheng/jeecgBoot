const express = require('express');
const { spawn } = require('child_process');
const http = require('http');
const { WebSocketServer } = require('ws');
const path = require('path');

const PORT = 3101;
const PROJECT_DIR = path.resolve(__dirname, '..');
const DEPLOY_SCRIPT = path.join(PROJECT_DIR, 'deploy.sh');
const DEPLOY_TIMEOUT = 15 * 60 * 1000; // 15分钟超时自动重置

const app = express();
app.use(express.static(path.join(__dirname, 'public')));

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

let deploying = false;
let lastDeploy = null;
let timeoutHandle = null;

const ERROR_DIAGNOSIS = [
  { pattern: /\[less\] timed-out/i, hint: 'Less 编译超时——可能是服务器内存不足，尝试重启后重试' },
  { pattern: /out of memory/i, hint: '内存溢出——增加 Docker 容器内存或减少并发任务' },
  { pattern: /Could not autowire/i, hint: 'Maven 依赖未注册——检查 pom.xml 是否缺少新模块的依赖声明' },
  { pattern: /Table.*doesn\'t exist/i, hint: '数据库表不存在——检查是否执行了对应的 SQL 初始化脚本' },
  { pattern: /Module.*not found/i, hint: 'pnpm 依赖缺失——运行 pnpm install 后重试' },
  { pattern: /Cannot find module/i, hint: 'npm 包缺失——检查 package.json 是否有新依赖' },
  { pattern: /ERR_NAME_NOT_RESOLVED/i, hint: 'Docker 容器主机名解析失败——检查 /etc/hosts 配置' },
];

function diagnose(text) {
  for (const d of ERROR_DIAGNOSIS) {
    if (d.pattern.test(text)) return d.hint;
  }
  return null;
}

function log(msg) {
  const ts = new Date().toISOString().slice(11, 19);
  console.log(`[${ts}] ${msg}`);
}

wss.on('connection', (ws) => {
  log('客户端已连接');

  ws.on('message', (data) => {
    const msg = data.toString();
    if (msg === 'deploy') {
      if (deploying) {
        ws.send(JSON.stringify({ type: 'error', message: '部署正在进行中，请稍后再试。如果确认上次部署已中断，可以手动重置状态。' }));
        return;
      }
      startDeploy(ws);
    } else if (msg === 'reset') {
      deploying = false;
      if (timeoutHandle) { clearTimeout(timeoutHandle); timeoutHandle = null; }
      log('部署状态已手动重置');
      ws.send(JSON.stringify({ type: 'ready', message: '部署状态已重置，可以开始新部署', history: lastDeploy }));
    } else if (msg === 'ping') {
      ws.send(JSON.stringify({ type: 'pong' }));
    }
  });

  ws.on('close', () => {
    log('客户端已断开');
  });

  const payload = { type: 'ready', message: deploying ? '警告：上次部署可能未正常结束，如确认已中断请手动重置' : '就绪，等待部署指令', history: lastDeploy };
  ws.send(JSON.stringify(payload));
});

const STEP_LABELS = {
  '1/6': '检查必要工具',
  '2/6': '拉取最新代码',
  '3/6': '配置 Hosts',
  '4/6': '编译后端项目',
  '5/6': '编译前端项目',
  '6/6': '启动 Docker 容器',
};
const STEP_PATTERN = /\[(\d\/6)\]/;

function startDeploy(ws) {
  deploying = true;
  const startTime = Date.now();

  // 超时自动重置
  timeoutHandle = setTimeout(() => {
    if (deploying) {
      deploying = false;
      log('部署超时（15分钟），自动重置状态');
      ws.send(JSON.stringify({ type: 'error', message: '部署超时（超过15分钟），状态已自动重置，请重试' }));
    }
  }, DEPLOY_TIMEOUT);

  log('开始部署...');
  ws.send(JSON.stringify({ type: 'start', message: '========== 开始部署 ==========' }));

  const proc = spawn('bash', [DEPLOY_SCRIPT], {
    cwd: PROJECT_DIR,
    env: { ...process.env, HOME: process.env.HOME },
  });

  proc.stdout.on('data', (data) => {
    const text = data.toString();
    ws.send(JSON.stringify({ type: 'log', line: text }));

    const hint = diagnose(text);
    if (hint) {
      ws.send(JSON.stringify({ type: 'hint', message: hint }));
    }

    const match = text.match(STEP_PATTERN);
    if (match) {
      const key = match[1];
      const label = STEP_LABELS[key] || '';
      const step = parseInt(key);
      ws.send(JSON.stringify({ type: 'step', step, total: 6, label: `[${key}] ${label}` }));
    }
  });

  proc.stderr.on('data', (data) => {
    const text = data.toString();
    ws.send(JSON.stringify({ type: 'log', line: text }));
    const hint = diagnose(text);
    if (hint) {
      ws.send(JSON.stringify({ type: 'hint', message: hint }));
    }
  });

  proc.on('close', (code) => {
    deploying = false;
    if (timeoutHandle) { clearTimeout(timeoutHandle); timeoutHandle = null; }
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    const result = { time: new Date().toISOString(), code, duration: elapsed + 's', status: code === 0 ? '成功' : '失败' };
    lastDeploy = result;
    if (code === 0) {
      const msg = `========== 部署成功 (耗时 ${elapsed}s) ==========`;
      log(msg);
      ws.send(JSON.stringify({ type: 'done', code: 0, message: msg, history: result }));
    } else {
      const msg = `========== 部署失败 (耗时 ${elapsed}s) ==========`;
      log(msg);
      ws.send(JSON.stringify({ type: 'done', code, message: msg, history: result }));
    }
  });

  proc.on('error', (err) => {
    deploying = false;
    if (timeoutHandle) { clearTimeout(timeoutHandle); timeoutHandle = null; }
    const msg = `进程启动失败: ${err.message}`;
    log(msg);
    ws.send(JSON.stringify({ type: 'error', message: msg }));
  });
}

server.listen(PORT, () => {
  log(`部署服务已启动: http://localhost:${PORT}`);
});

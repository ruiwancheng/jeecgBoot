const express = require('express');
const { spawn } = require('child_process');
const http = require('http');
const { WebSocketServer } = require('ws');
const path = require('path');

const PORT = 3101;
const PROJECT_DIR = path.resolve(__dirname, '..');
const DEPLOY_SCRIPT = path.join(PROJECT_DIR, 'deploy.sh');

const app = express();
app.use(express.static(path.join(__dirname, 'public')));

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

let deploying = false;

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
        ws.send(JSON.stringify({ type: 'error', message: '部署正在进行中，请稍后再试' }));
        return;
      }
      startDeploy(ws);
    } else if (msg === 'ping') {
      ws.send(JSON.stringify({ type: 'pong' }));
    }
  });

  ws.on('close', () => {
    log('客户端已断开');
  });

  ws.send(JSON.stringify({ type: 'ready', message: '就绪，等待部署指令' }));
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

  log('开始部署...');
  ws.send(JSON.stringify({ type: 'start', message: '========== 开始部署 ==========' }));

  const proc = spawn('bash', [DEPLOY_SCRIPT], {
    cwd: PROJECT_DIR,
    env: { ...process.env, HOME: process.env.HOME },
  });

  proc.stdout.on('data', (data) => {
    const text = data.toString();
    ws.send(JSON.stringify({ type: 'log', line: text }));
    // 检测步骤进度标记 [N/6]
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
  });

  proc.on('close', (code) => {
    deploying = false;
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    if (code === 0) {
      const msg = `========== 部署完成 (耗时 ${elapsed}s) ==========`;
      log(msg);
      ws.send(JSON.stringify({ type: 'done', code: 0, message: msg }));
    } else {
      const msg = `========== 部署失败，退出码: ${code} (耗时 ${elapsed}s) ==========`;
      log(msg);
      ws.send(JSON.stringify({ type: 'done', code, message: msg }));
    }
  });

  proc.on('error', (err) => {
    deploying = false;
    const msg = `进程启动失败: ${err.message}`;
    log(msg);
    ws.send(JSON.stringify({ type: 'error', message: msg }));
  });
}

server.listen(PORT, () => {
  log(`部署服务已启动: http://localhost:${PORT}`);
});

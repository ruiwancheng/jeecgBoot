const $ = (selector) => document.querySelector(selector);
const statusText = {
  running: '运行中',
  completed: '已完成',
  completed_with_failures: '有失败',
  blocked_environment: '环境阻断',
  stopped: '已停止',
  interrupted: '已中断',
};
const stateText = {
  passed: '通过',
  failed: '失败',
  timeout: '超时',
  pending: '待执行',
  running: '运行中',
  blocked_environment: '环境阻断',
  interrupted: '已中断',
};
const issueText = {
  pending_review: '待复核',
  suspected_bug: '疑似问题',
  false_positive: '误判',
  confirmed_bug: '已确认问题',
  test_defect: '测试脚本问题',
  data_precondition: '测试数据问题',
  environment_issue: '环境问题',
};

function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>'"]/g, (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[char]));
}

function renderStatus(value) {
  const text = statusText[value] || value || '未知';
  return `<span class="status-cell state-${escapeHtml(value)}">${escapeHtml(text)}</span>`;
}

function renderMetrics(progress) {
  const entries = [
    ['通过', progress.passed, 'state-passed'],
    ['失败', progress.failed, 'state-failed'],
    ['超时', progress.timeout, 'state-timeout'],
    ['待执行', progress.pending, 'state-pending'],
  ];
  $('#progress-detail').innerHTML = entries.map(([label, value, cls]) => `<span class="${cls}"><strong>${value}</strong>${label}</span>`).join('');
}

function renderServices(services) {
  const entries = Object.entries(services || {});
  $('#services').innerHTML = entries.length ? entries.map(([name, service]) => {
    const status = service.status || 'unknown';
    return `<div class="service"><div class="service-name">${escapeHtml(name)}</div><div class="service-${escapeHtml(status)}">● ${escapeHtml(status === 'healthy' ? 'Healthy' : status)}</div><div class="muted">${escapeHtml(service.message || '')}</div></div>`;
  }).join('') : '<span class="muted">尚未记录服务状态</span>';
}

function renderSlices(slices) {
  $('#slice-table').innerHTML = (slices || []).map((slice) => `<tr data-slice="${escapeHtml(slice.id)}">
    <td>${escapeHtml(slice.id)}</td>
    <td>${escapeHtml(slice.name)}</td>
    <td>${renderStatus(slice.status)}</td>
    <td>${slice.attempts ?? 0}</td>
    <td>${slice.duration_seconds == null ? '—' : `${slice.duration_seconds}s`}</td>
    <td>${slice.exit_code == null ? '—' : slice.exit_code}</td>
    <td>${escapeHtml(slice.message || '')}</td>
  </tr>`).join('');
  document.querySelectorAll('#slice-table tr').forEach((row) => row.addEventListener('click', () => loadLog(row.dataset.slice)));
}

function renderIssues(issues) {
  const candidates = issues?.candidates || [];
  const counts = issues?.counts || {};
  $('#issue-metrics').innerHTML = Object.entries(counts).length
    ? Object.entries(counts).map(([key, value]) => `<span class="state-${escapeHtml(key)}"><strong>${value}</strong>${escapeHtml(issueText[key] || key)}</span>`).join('')
    : '<span class="muted">暂无问题</span>';
  $('#issues').innerHTML = candidates.length ? candidates.map((item) => `<div class="issue issue-${escapeHtml(item.verdict)}">
    <div class="issue-title">${escapeHtml(item.title)}</div>
    <div class="issue-meta">${escapeHtml(issueText[item.verdict] || item.verdict)} · ${escapeHtml(item.route)} · 失败 ${item.failures} 次</div>
    <div class="issue-meta">${escapeHtml(item.lastError || '')}</div>
  </div>`).join('') : '<p class="muted">暂无复核问题</p>';
}

async function loadLog(sliceId) {
  $('#log-title').textContent = `运行日志 · ${sliceId}`;
  const response = await fetch(`/api/log?slice=${encodeURIComponent(sliceId)}`, { cache: 'no-store' });
  const data = await response.json();
  $('#log-content').textContent = data.content || data.error || '日志为空';
}

async function refresh() {
  try {
    const response = await fetch('/api/status', { cache: 'no-store' });
    const data = await response.json();
    const status = data.status || 'unknown';
    const statusNode = $('#run-status');
    statusNode.textContent = statusText[status] || status;
    statusNode.className = `status status-${status}`;
    $('#run-name').textContent = `${data.name || '回归任务'} · ${data.run_id || ''}`;
    $('#progress-text').textContent = `${data.progress.passed} / ${data.progress.total}`;
    $('#progress-bar').style.width = `${data.progress.percent}%`;
    $('#current-slice').textContent = data.current_slice || (status === 'running' ? '准备下一切片' : '—');
    $('#heartbeat').textContent = `最后心跳：${data.heartbeat_at || '—'}`;
    $('#refresh-time').textContent = `刷新：${new Date().toLocaleTimeString()}`;
    renderMetrics(data.progress);
    renderServices(data.services);
    renderSlices(data.slices);
    renderIssues(data.issues);
  } catch (error) {
    $('#run-status').textContent = '看板连接异常';
    $('#run-status').className = 'status status-failed';
    $('#heartbeat').textContent = String(error);
  }
}

$('#clear-log').addEventListener('click', () => {
  $('#log-title').textContent = '运行日志';
  $('#log-content').textContent = '点击切片行查看日志';
});
refresh();
setInterval(refresh, 3000);

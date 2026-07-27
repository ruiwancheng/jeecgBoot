---
name: visual-check
description: 浏览器可视化验证 — Orca browser 截图 + 基线对比 + 人工门控判定，/visual-check 命令的领域知识
version: 1.0.0
---

# visual-check — 浏览器可视化验证

## 截图基线目录

```
hermes/visual-baselines/
├── purchase/order/
│   ├── baseline.png              # 当前基线（最新通过审核的截图）
│   └── YYYY-MM-DD/
│       ├── screenshot.png        # 本次截图
│       └── diff.png              # 差异对比（如果 done 时录制）
├── sales/order/
│   └── ...
└── INDEX.md                      # 基线索引
```

## 模块到页面 URL 映射

从 `hermes/business-chains.json` 推测 URL。默认规则：

| 模块关键词 | 页面 URL 路径 |
|-----------|-------------|
| `purchase/order` | `/project/mes/purchase/order` |
| `purchase/receipt` | `/project/mes/purchase/receipt` |
| `purchase/apply` | `/project/mes/purchase/apply` |
| `sales/order` | `/project/mes/sales/order` |
| `sales/delivery` | `/project/mes/sales/delivery` |
| `sales/outbound` | `/project/mes/sales/outbound` |
| `manufacturing/bom` | `/project/mes/manufacturing/bom` |
| `manufacturing/order` | `/project/mes/manufacturing/order` |
| `basic/*` | `/project/mes/basic/*` |

> 如果没有匹配，通过 `src/router/routes/modules/mes.ts` 查找路由 path。
> 用户可通过 `--page <URL>` 直接指定。

## Orca browser 操作

### 打开并登录

```bash
# 打开页面
orca goto --url http://localhost:3100

# 等待登录页加载
orca wait --timeout 3000

# 获取可访问性树（元素 ref 每次页面加载后重新获取）
orca snapshot

# 查找登录表单的输入框 ref，填入凭据
orca fill --element <用户名ref> --value "admin"
orca fill --element <密码ref> --value "123456"

# 点击登录按钮
orca click --element <登录按钮ref>

# 等待页面跳转
orca wait --timeout 3000
```

> 元素 ref (e5, e7, e10) 每次页面加载后变化——必须先 snapshot 再交互。

### 导航到目标页面

```bash
# 方式 1：直接导航（如果已登录 session 有效）
orca goto --url http://localhost:3100/project/mes/<模块路径>

# 方式 2：通过菜单点击（如果登录后 session 丢失）
# 先 snapshot 拿到菜单树，再逐级点击展开
orca snapshot
orca click --element <菜单ref>
```

### 截图

```bash
orca screenshot --format png
# 截图保存到 orca 管理的输出，AI 需将其写入文件
```

### 保存截图

```bash
mkdir -p hermes/visual-baselines/<模块名>/YYYY-MM-DD/
# 将 orca screenshot 的输出写入
# hermes/visual-baselines/<模块名>/YYYY-MM-DD/screenshot.png
```

## 基线对比

### 首次检查（无基线）

`test -f hermes/visual-baselines/<模块名>/baseline.png` → 不存在：

```
📸 首次截图 — 建立基线

  模块：<模块名>
  页面：<URL>
  基线已保存：hermes/visual-baselines/<模块名>/baseline.png

  后续 /visual-check 将与此基线对比。
```

不触发 human-gate。

然后更新基线索引：

```bash
echo "| $(date '+%Y-%m-%d') | <模块名> | <URL> | baseline.png | 首次建立 |" >> hermes/visual-baselines/INDEX.md
```

### 已有基线

对比当前截图与基线。使用 `python` 做像素级对比：

```bash
# Windows: python3 可能是 WindowsApps 商店 stub → 必须 --version 实测过滤
PY_CMD=$(command -v python3 || command -v python || echo python)
$PY_CMD --version >/dev/null 2>&1 || PY_CMD=$(command -v python || echo python)

# 确保 Pillow 已安装
$PY_CMD -c "from PIL import Image" 2>/dev/null || pip3 install Pillow 2>/dev/null || pip install Pillow

$PY_CMD -c "
from PIL import Image
import numpy as np

baseline = np.array(Image.open('hermes/visual-baselines/<模块名>/baseline.png'))
current = np.array(Image.open('hermes/visual-baselines/<模块名>/YYYY-MM-DD/screenshot.png'))

if baseline.shape != current.shape:
    print('SIZE_MISMATCH', baseline.shape, current.shape)
else:
    diff = np.abs(baseline.astype(int) - current.astype(int))
    diff_pixels = np.sum(diff > 30)  # 阈值 30（0-255）
    total_pixels = diff.size
    ratio = diff_pixels / total_pixels
    print(f'DIFF_RATIO={ratio:.4f}')
    print(f'DIFF_PIXELS={diff_pixels}')
    print(f'TOTAL_PIXELS={total_pixels}')
"
```

### 差异判定

| diff_ratio | 判定 |
|:--:|------|
| < 0.1% | 🟢 无明显变化，输出"页面显示与基线一致" |
| 0.1% – 5% | 🟡 轻微变化，发 human-gate |
| > 5% | 🔴 显著变化，发 human-gate |

### human-gate 选项

```
🛑 UI 差异需人工判定 — <模块名>

  差异比例：X.XX%（N 像素）
  差异程度：🟡 轻微 / 🔴 显著

  选项：
  [1] 预期变更 → 更新基线（accept_baseline）
  [2] 问题需修复 → 标记（fix_required）
  [3] 已知问题，忽略 → 保留旧基线（ignore）

  等待判定中...
```

gate resolved 后：
- `accept_baseline` → `cp screenshot.png baseline.png`，更新基线
- `fix_required` → 输出差异区域，提示需要修复的页面和区域
- `ignore` → 不做任何变更，记录到 `hermes/visual-baselines/INDEX.md`

## 降级

Orca 不可用 → 直接退出，输出 "❌ Orca 不可用，/visual-check 需要 Orca browser 功能"。

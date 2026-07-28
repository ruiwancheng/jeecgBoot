# 验证部署是否含最新前端代码：bundle 特征串 grep

**场景**：用户说"部署完成"，但功能在生产端不生效——到底是代码问题还是没部署上？

**方法**：不猜，直接 grep 部署产物：

```bash
# 1. 拿主 bundle 名
curl -s http://server/ | grep -oE '/js/index-[^"]+\.js'
# 2. 主 bundle 里找目标页面的懒加载 chunk 名
curl -s http://server/js/index-XXX.js | grep -oE "OtherInDrawer[^\"']*\.js"
# 3. grep chunk 里的特征串（函数名会被压缩，属性名不会）
curl -s http://server/js/OtherInDrawer-YYY.js | grep -c "movingAvgCost"
# 4. 和本地 pnpm build 的 dist 同位置 chunk 对比
```

**要点**：
- 生产构建压缩**函数名**（onMaterialChange 查不到是正常的），但**属性名字符串**保留（`record.movingAvgCost`）
- 本地 build 一次拿"正确基线"，与服务器 chunk 对比特征串出现次数/上下文
- 本次实证：服务器 chunk 只有旧批量预填，无新单行预填 → 判定上次部署只更了后端

**适用**：任何"用户说部署了但行为没变"的争议，30 秒出铁证。

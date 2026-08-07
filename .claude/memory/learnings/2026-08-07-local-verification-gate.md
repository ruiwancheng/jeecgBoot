# 本地验证缺失 = 部署失败根因

**日期**：2026-08-07
**上下文**：v3 孤儿行清理方案 8 commits 派 codex 实施后，部署到生产失败
**教训**：派工 + 评审 + 落地 ≠ 验证完成

## TL;DR

派 codex worker 完成实施 + 3 轮 Codex 评审通过 + 5 轮 Slice 复评审通过 = **不等于** 部署就绪。

**真实教训**：实施完成 + 评审通过 后，**必须本地完整验证**（mvn compile + 起后端 + curl 实际接口 + 跑测试），否则部署必失败。

## 部署失败的根因链路

```
1. 派工完成（8 commits）
   ↓
2. Codex 评审 9.2/10 通过（看似完美）
   ↓
3. ❌ 跳过本地验证（直接信任 codex 自报"已编译通过"）
   ↓
4. 部署到生产
   ↓
5. 后端启动失败（Empty reply）
   ↓
6. P0 守卫白名单缺失 → audit 表 2 张 + 业务表 19 张 = 21 张期望，19 张实际
```

**外加 2 个 codex 实施疏漏**（本地没跑接口根本发现不了）：
- XML mapper 路径不在扫描路径 → `Invalid bound statement`
- XML 注释含 `--` → `SAXParseException`

## 哪些"验证"是假的

| 类型 | 价值 | 能否 catch XML 路径错？ |
|---|---|---|
| `git show --stat` 看文件改动 | ❌ 零 | ❌ |
| `grep` 检查代码模式 | ⚠️ 低 | ❌ |
| Codex 3 轮评审 | ⚠️ 中（评审代码，不跑） | ❌ |
| **本地 `mvn clean compile`** | ✅ 编译过 | ❌（XML 不编译） |
| **本地起后端 + curl** | ✅ 真实路径 | ✅ **✅** |
| **本地跑 harness 测试** | ✅ 真实路径 | ✅ |

## 必须的本地验证清单（v3 后端方案）

```bash
# 1. 编译
cd /Users/ruisuyun/Documents/GitHub/jeecgBoot/jeecg-boot
mvn clean install -DskipTests -pl jeecg-boot-module/project-mes -am

# 2. 启动
cd jeecg-module-system/jeecg-system-start
nohup mvn spring-boot:run -Dspring-boot.run.profiles=dev > /tmp/spring.log 2>&1 &

# 3. 等启动 + 健康检查
for i in $(seq 1 20); do
  sleep 8
  CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 http://localhost:8080/jeecg-boot/sys/getEncryptedString)
  echo "[$((i*8))s] HTTP $CODE"
  [[ "$CODE" == "200" ]] && break
done

# 4. 看启动日志（必须有 CoverageAssertor 通过 + 无 ERROR）
grep -E "守卫覆盖校验|ERROR" /tmp/spring.log | head -10

# 5. 跑端到端 curl
TOKEN=$(curl -s -X POST 'http://localhost:8080/jeecg-boot/sys/login' \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"123456"}' \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['token'])")

# 测试所有新端点
curl -H "X-Access-Token: $TOKEN" http://localhost:8080/jeecg-boot/mes/warehouse/inventory/orphanCount
curl -H "X-Access-Token: $TOKEN" http://localhost:8080/jeecg-boot/mes/warehouse/inventory/list?pageSize=2 | python3 -c "import json,sys; r=json.load(sys.stdin)['result']['records'][0]; print('isOrphan:', r.get('isOrphan'))"

# 测试守卫触发
MAT_ID=...  # 找有引用的物料
curl -X DELETE -H "X-Access-Token: $TOKEN" "http://localhost:8080/jeecg-boot/mes/basic/material/delete?id=$MAT_ID"

# 6. 跑 harness 测试（可选但强烈推荐）
node harness/tests/modules/inventory-orphan-edge.test.js
```

## 派 codex 后的检查清单（强制）

| 步骤 | 工具 | 验证什么 |
|---|---|---|
| 1 | `mvn install -DskipTests` | 编译 + 打 jar + 装到 M2 |
| 2 | 启动后端 + curl | 端到端真实路径 |
| 3 | 启动日志 grep ERROR/守卫覆盖校验 | 自检 fail-fast |
| 4 | curl 关键端点 | 业务功能 |
| 5 | 触发守卫场景 | 业务守门 |
| 6 | 跑 harness 测试 | 自动化覆盖 |

**任一步失败 → 修复后再上一步**。

## 派工 prompt 必须加的验证约束

```markdown
### 强制约束（防止 codex 偷懒）
- [ ] `mvn clean compile -DskipTests` PASS
- [ ] 启动后端无 ERROR
- [ ] curl 所有新端点返回 200
- [ ] 启动日志包含守卫覆盖校验通过
- [ ] 测试守卫触发（删有引用物料报错）

不要相信 codex 自报"已通过"，必须自己跑一遍。
```

## 不推荐做法

- ❌ 派工完成 + 评审通过就直接部署
- ❌ 用 `grep` 检查代码模式代替本地验证
- ❌ 信任 codex 自报 "已编译通过" "已测试"
- ❌ 跳过 curl 端到端
- ❌ 跳过后端启动日志检查
- ❌ 没看到自检通过日志就上

## 推荐做法

- ✅ 派工后本地完整验证（mvn install + 启动 + curl）
- ✅ 看到启动日志的自检通过消息
- ✅ curl 关键端点返回 200
- ✅ 触发守卫场景看到拦截
- ✅ 全部通过后才标记 slice done

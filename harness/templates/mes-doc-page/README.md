# MES 单据页黄金模板（master-detail 主子表版）

> @template-version: 1.0.0
> 蓝本：stock/other-in（其它入库），融合 stocktake（快照提示/差异红标）
> 生成方式：/new-module 复制本目录文件 → 替换占位符 → 输出后续清单

## 占位符规范（5 个核心，case 变体由替换脚本派生）

| 占位符 | 含义 | 示例（调拨入库） |
|--------|------|-----------------|
| `{{BIZ}}` | 业务名 kebab-case | `transfer-in` |
| `{{BIZ_NAME}}` | 业务中文名 | `调拨入库` |
| `{{MOD}}` | 模块目录路径 | `stock/transfer-in` |
| `{{PAGE_COMPONENT}}` | Vue 组件名 PascalCase | `MesTransferIn` |
| `{{API_PREFIX}}` | 后端 API 前缀 | `/mes/stock/transferIn` |

**脚本派生（模板里不出现，生成时计算）**：

| 派生 | 规则 | 示例 |
|------|------|------|
| `MENU_ID` | `mes_` + BIZ 的 snake_case | `mes_transfer_in` |
| `PERM_PREFIX` | `mes:` + BIZ 的 camelCase + `:` | `mes:transferIn:` |
| `BIZ_CODE` | 编码规则前缀（生成时询问用户，2 位大写） | `TI` |
| `DOC_NAME` | 单据中文名（生成时询问，默认=BIZ_NAME+单） | `调拨入库单` |
| `API_FILE` | BIZ camelCase + `.api.ts` | `transferIn.api.ts` |
| `DATA_FILE` | BIZ camelCase + `.data.ts` | `transferIn.data.ts` |
| `DRAWER_FILE` | PascalCase(BIZ) + `Drawer.vue` | `TransferInDrawer.vue` |
| `SUB_TABLE_FILE` | PascalCase(BIZ) + `ItemsSubTable.vue` | `TransferInItemsSubTable.vue` |

**命名约束**：占位符全大写+下划线；模板内禁止出现 `{{Module}}`/`{{module}}`/`{{MODULE}}` 三套变体（派生归脚本）。

## 内置 UX 模式（10/10，单表版为 1/2/4/7/10）

- [x] 1. 搜索区字典下拉（JDictSelectTag）+ 仓库下拉（ApiSelect）
- [x] 2. 复选框 rowSelection + 批量审核/反审核（状态守卫 disabled）
- [x] 3. 明细子表展开行（expandedRowRender + ItemsSubTable）
- [x] 4. 抽屉 + 自动编码接线（getNextCode + MES_BIZ_CODE，失败回退手工）
- [x] 5. 明细行编辑（JMaterialSelect + 数量/单价 InputNumber + 金额自动算）
- [x] 6. 批量添加物料弹窗（MaterialSelectModal multiple + 移动平均成本预填）
- [x] 7. 审核/反审核/删除状态机按钮（仅草稿可编辑/删除/审核）
- [x] 8. 快照/口径 Alert 提示（抽屉顶部，可删）
- [x] 9. 差异/异常红标高亮（diff≠0 红色加粗，可删）
- [x] 10. 删除 popConfirm + 操作列按 status 动态显隐

## 生成页标记（版本演进用）

生成文件头部必须带：
```
<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
```

## 文件清单

| 文件 | 说明 |
|------|------|
| `index.vue.template` | 列表页（模式 1/2/3/7/10） |
| `drawer.vue.template` | 抽屉（模式 4/5/6/8/9） |
| `items-sub-table.vue.template` | 明细展开子表（模式 3） |
| `api.ts.template` | API 封装 |
| `data.ts.template` | 列定义+搜索/表单 schema |

## 后续清单（生成后必做）

1. 后端 4 件套（Entity/Mapper/Service/Controller）+ SQL 迁移
2. `MesMenuRegistry.java` 注册菜单+权限码（PERM_PREFIX 派生）
3. `bizCodeMap.ts` 加 `MES_BIZ_CODE.XXX: '编码前缀'`
4. 路由 `mes.ts` 注册页面
5. 测试三件套（testing.md v2：API 业务流 + E2E 完整流 + payload 抓包）

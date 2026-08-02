# 实施计划：批次追溯页面列表粒度重做（批次级 + 聚合）

> 日期：2026-08-03
> 触发：用户反馈"批次追溯"页面字段空、看不出业务价值
> Claude 评审 P0 发现：当前 api.ts 实际调 master 端点，columns 引用 ledger 字段（全空）
> 方案：新建批次级聚合 VO + traceability 端点 + 重写 api.ts/columns + 改造 exportXls
> 工期：标准（原计划低估了 2 个改动量）

---

## 🎯 目标

### 业务目标
- **列表 = 批次级 + 聚合字段**：每行代表一个批次，加上累计入库/出库/流水条数等汇总
- **抽屉 = 流水详情**：保留流水表，点"查看追溯"看该批次的所有流水
- **修字段空 bug**：columns 字段对齐后端返回（关键 P0 修复）

### 验收标准
- 列表第一行能看到：批次号 + 物料 + 来源类型 + 来源单据 + 初始数量 + 累计入库 + 累计出库 + 流水条数 + 状态 + 最新发生时间
- 抽屉显示：批次主档 + 流水表（非空白）
- 搜索：批次号/物料/来源类型过滤
- 导出：与列表同步（批次级 + 聚合字段）

---

## 🔍 Claude 评审 P0 发现（关键事实修正）

**当前 traceability 页面实际行为：**

| 现状 | 真相 |
|---|---|
| `traceability.api.ts` 的 `queryBatchList` | **从 `../master/master.api` 重导出**，调 `/mes/batch/master/list` |
| 列表每一行 | `MesBatch` 记录（批次级） |
| columns 字段 | `bizType`/`bizNo`/`inQty`/`outQty`/`occurTime`/`remark`（ledger 字段，在 MesBatch 中不存在） |
| 字段显示 | **全空**（MesBatch 没这些字段） |
| 抽屉调用 | `queryBatchList({id: batchId})` → master list → `WHERE id = ?` → 找到 |

**用户看到的"空字段"根因**：columns 引用了不存在的字段。新方案需要让 columns 对齐后端返回。

---

## 📁 文件清单（10 个，Claude 评审修正）

| # | 路径 | 类型 | 改动 |
|---|---|---|---|
| 1 | `MesBatchTraceabilityVO.java` | 新建 | 批次级 + 聚合字段（@Dict + @Excel） |
| 2 | `MesBatchTraceabilityMapper.java` | 修改 | + `queryBatchPage` 接口 |
| 3 | `MesBatchTraceabilityMapper.xml` | 新建 | `queryBatchPage` SQL + 显式 `<resultMap>` |
| 4 | `IMesBatchTraceabilityService.java` | 修改 | + 接口方法 |
| 5 | `MesBatchTraceabilityServiceImpl.java` | 修改 | + 实现 |
| 6 | `MesBatchTraceabilityController.java` | 修改 | `/list` 改批次级；`/exportXls` 手写导出 |
| 7 | `traceability.data.ts` | **重写** | columns 全部对齐聚合字段 |
| 8 | `traceability.api.ts` | **拆分** | 移除 master 重导出，新增 traceability 端点函数 |
| 9 | `index.vue` | 微调 | `useListPage` 的 api 指向新函数 |
| 10 | `V10.0.3__mes_traceability_batch_level.sql` | 新建 | `(batch_id, del_flag)` 复合索引 + 锚点 |

---

## 📋 详细步骤

### 步骤 1: 新建 VO `MesBatchTraceabilityVO`

**位置：** `src/main/java/org/jeecg/modules/mes/batch/traceability/entity/`

**字段设计（驼峰命名，MyBatis 自动映射下划线）：**

```java
@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Schema(description = "MES-批次追溯(批次级汇总)")
public class MesBatchTraceabilityVO implements Serializable {
    private static final long serialVersionUID = 1L;

    // === 批次主档字段（来自 c_mes_batch） ===
    @Schema(description = "批次ID")
    private String id;  // ★ = batch_id（前端 drawer 期望）

    @Excel(name = "批次号", width = 25)
    @Schema(description = "批次号")
    private String batchNo;

    @Dict(dictTable = "c_mes_material", dicText = "name", dicCode = "id")
    @Excel(name = "物料ID", width = 15)
    @Schema(description = "物料ID")
    private String materialId;
    // 运行时 DictAspect 自动产出 materialId_dictText

    @Dict(dicCode = "mes_batch_origin_type")
    @Excel(name = "来源类型", width = 12)
    @Schema(description = "来源类型")
    private String originType;
    // 运行时 DictAspect 自动产出 originType_dictText

    @Excel(name = "来源单据号", width = 20)
    @Schema(description = "来源单据号")
    private String originBillNo;

    @Excel(name = "初始数量", width = 12)
    @Schema(description = "初始批次数量")
    private BigDecimal qty;

    @Excel(name = "生产日期", width = 12, format = "yyyy-MM-dd")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @Schema(description = "生产日期")
    private Date productionDate;

    @Excel(name = "有效期至", width = 12, format = "yyyy-MM-dd")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
    @Schema(description = "有效期至")
    private Date expiryDate;

    @Excel(name = "批次单位成本", width = 14)
    @Schema(description = "批次单位成本")
    private BigDecimal unitCost;

    @Dict(dicCode = "mes_batch_status")
    @Excel(name = "状态", width = 10)
    @Schema(description = "状态")
    private String status;
    // 运行时 DictAspect 自动产出 status_dictText

    // === 聚合字段（来自 GROUP BY c_mes_batch_ledger） ===
    @Excel(name = "累计入库", width = 12)
    @Schema(description = "累计入库数量")
    private BigDecimal totalInQty;

    @Excel(name = "累计出库", width = 12)
    @Schema(description = "累计出库数量")
    private BigDecimal totalOutQty;

    @Excel(name = "流水条数", width = 10)
    @Schema(description = "流水条数")
    private Integer ledgerCount;

    @Excel(name = "最新发生时间", width = 18, format = "yyyy-MM-dd HH:mm:ss")
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "最新发生时间")
    private Date lastOccurTime;
}
```

**关键点（Claude 评审验证）：**
- `@Dict` 在 VO 上生效（DictAspect 反射运行时 class，不依赖 @TableName）
- `@Excel` 用于导出（与项目导出模式一致）
- `id` 字段语义 = `batch_id`（与 drawer 期望一致）

---

### 步骤 2: 新建 Mapper XML + 接口

**位置：** `MesBatchTraceabilityMapper.java`（接口）

```java
public interface MesBatchTraceabilityMapper extends BaseMapper<MesBatchTraceability> {
    IPage<MesBatchTraceabilityVO> queryBatchPage(
        IPage<MesBatchTraceabilityVO> page,
        @Param("ew") QueryWrapper<MesBatchTraceabilityVO> wrapper
    );
}
```

**位置：** `MesBatchTraceabilityMapper.xml`（新增）

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="org.jeecg.modules.mes.batch.traceability.mapper.MesBatchTraceabilityMapper">

    <resultMap id="batchLevelMap" type="org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceabilityVO">
        <id column="id" property="id"/>
        <result column="batch_no" property="batchNo"/>
        <result column="material_id" property="materialId"/>
        <result column="origin_type" property="originType"/>
        <result column="origin_bill_no" property="originBillNo"/>
        <result column="qty" property="qty"/>
        <result column="production_date" property="productionDate"/>
        <result column="expiry_date" property="expiryDate"/>
        <result column="unit_cost" property="unitCost"/>
        <result column="status" property="status"/>
        <result column="total_in_qty" property="totalInQty"/>
        <result column="total_out_qty" property="totalOutQty"/>
        <result column="ledger_count" property="ledgerCount"/>
        <result column="last_occur_time" property="lastOccurTime"/>
    </resultMap>

    <select id="queryBatchPage" resultMap="batchLevelMap">
        SELECT
            b.id                        AS id,
            b.batch_no                  AS batch_no,
            b.material_id               AS material_id,
            b.origin_type               AS origin_type,
            b.origin_bill_no            AS origin_bill_no,
            b.qty                       AS qty,
            b.production_date           AS production_date,
            b.expiry_date               AS expiry_date,
            b.unit_cost                 AS unit_cost,
            b.status                    AS status,
            IFNULL(SUM(l.in_qty), 0)    AS total_in_qty,
            IFNULL(SUM(l.out_qty), 0)   AS total_out_qty,
            COUNT(l.id)                 AS ledger_count,
            MAX(l.occur_time)           AS last_occur_time
        FROM c_mes_batch b
        LEFT JOIN c_mes_batch_ledger l
            ON l.batch_id = b.id AND l.del_flag = 0
        <where>
            b.del_flag = 0
            <if test="ew != null and ew.sqlSegment != null and ew.sqlSegment != ''">
                AND ${ew.sqlSegment}
            </if>
        </where>
        GROUP BY b.id
        <if test="ew != null and ew.orderBy != null and ew.orderBy != ''">
            ORDER BY ${ew.orderBy}
        </if>
        <if test="ew == null or ew.orderBy == null or ew.orderBy == ''">
            ORDER BY last_occur_time DESC
        </if>
    </select>
</mapper>
```

**关键点（Claude 评审建议）：**
- 显式 `<resultMap>` 比纯自动映射更安全（避免字段名不一致静默漏）
- `IFNULL(SUM(...), 0)` 防 NULL 聚合
- 默认排序 `last_occur_time DESC`（NULL 排在最后，符合业务直觉）

---

### 步骤 3: Service 接口 + 实现

**位置：** `IMesBatchTraceabilityService.java`

```java
public interface IMesBatchTraceabilityService extends IService<MesBatchTraceability> {
    IPage<MesBatchTraceabilityVO> queryBatchPage(
        IPage<MesBatchTraceabilityVO> page,
        QueryWrapper<MesBatchTraceabilityVO> wrapper
    );
}
```

**位置：** `MesBatchTraceabilityServiceImpl.java`

```java
@Service
public class MesBatchTraceabilityServiceImpl
        extends ServiceImpl<MesBatchTraceabilityMapper, MesBatchTraceability>
        implements IMesBatchTraceabilityService {

    @Override
    public IPage<MesBatchTraceabilityVO> queryBatchPage(
            IPage<MesBatchTraceabilityVO> page,
            QueryWrapper<MesBatchTraceabilityVO> wrapper) {
        return baseMapper.queryBatchPage(page, wrapper);
    }
}
```

---

### 步骤 4: Controller 改造

**位置：** `MesBatchTraceabilityController.java`

**关键改动（P0 评审修正）：**
- `/list` 改用 `queryBatchPage`（批次级）
- `/exportXls` **手写导出**（不用 `super.exportXls`，因为泛型不一致）
- 加入参实体改为 `MesBatchTraceabilityVO`

```java
@GetMapping("/list")
@RequiresPermissions("mes:batchTraceability:list")
public Result<IPage<MesBatchTraceabilityVO>> queryPageList(
        MesBatchTraceabilityVO entity,
        @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
        @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize,
        HttpServletRequest req) {
    QueryWrapper<MesBatchTraceabilityVO> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
    return Result.ok(service.queryBatchPage(new Page<>(pageNo, pageSize), qw));
}

@GetMapping("/exportXls")
@RequiresPermissions("mes:batchTraceability:export")
public ModelAndView exportXls(MesBatchTraceabilityVO entity, HttpServletRequest req) {
    // 阈值检查：COUNT(DISTINCT batch_id)
    if (service.countBatchMasters() > QUERY_ALL_MAX) {
        throw new JeecgBootException("批次追溯记录超过" + QUERY_ALL_MAX + "条，请使用分页导出");
    }
    QueryWrapper<MesBatchTraceabilityVO> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
    List<MesBatchTraceabilityVO> data = service.queryBatchPage(new Page<>(1, QUERY_ALL_MAX), qw).getRecords();
    return exportExcel("批次追溯", "导出信息", MesBatchTraceabilityVO.class, data);
}
```

**注意：** `exportExcel` 方法（项目公共 EasyPoi 工具）需要确认存在。如果不存在，用 `ExcelUtil.exportExcel(...)` 或 `DefaultExcelExportUtil`。

---

### 步骤 5: 前端 `traceability.api.ts` 拆分（评审 P0 关键）

**位置：** `jeecgboot-vue3/src/views/project/mes/batch/traceability/traceability.api.ts`

**当前（混乱）：**
```ts
import { queryBatchList } from '../master/master.api';
export { queryBatchList };
// → 实际调 master/list
```

**改后（清晰）：**
```ts
import { defHttp } from '/@/utils/http/axios';

// 批次追溯：batch 级聚合列表（新增）
export function queryTraceabilityList(params: any) {
  return defHttp.get({ url: '/mes/batch/traceability/list', params });
}

// 批次追溯：batch 级导出（新增）
export function getTraceabilityExportUrl() {
  return '/mes/batch/traceability/exportXls';
}

// 抽屉用：复用批次主档 listById（保留）
export { queryBatchList } from '../master/master.api';

// 抽屉用：复用 ledger 的 listByBatchId（保留）
export function listLedgerByBatchId(params: any) {
  return defHttp.get({ url: '/mes/batch/ledger/listByBatchId', params });
}
```

---

### 步骤 6: 前端 `traceability.data.ts` 重写

**位置：** `jeecgboot-vue3/src/views/project/mes/batch/traceability/traceability.data.ts`

```ts
// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '批次号', dataIndex: 'batchNo', width: 180, fixed: 'left' },
  { title: '物料', dataIndex: 'materialId_dictText', width: 150 },
  { title: '来源类型', dataIndex: 'originType_dictText', width: 100 },
  { title: '来源单据', dataIndex: 'originBillNo', width: 140 },
  { title: '初始数量', dataIndex: 'qty', width: 100 },
  { title: '累计入库', dataIndex: 'totalInQty', width: 100 },
  { title: '累计出库', dataIndex: 'totalOutQty', width: 100 },
  { title: '流水条数', dataIndex: 'ledgerCount', width: 90 },
  { title: '状态', dataIndex: 'status_dictText', width: 90 },
  { title: '最新发生时间', dataIndex: 'lastOccurTime', width: 150 },
  { title: '操作', dataIndex: 'action', slots: { customRender: 'action' }, fixed: 'right', width: 120 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'batchNo', label: '批次号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'materialId', label: '物料', component: 'Input', colProps: { span: 6 } },
  { field: 'originType', label: '来源类型', component: 'Input', colProps: { span: 6 } },
];
```

**关键点：** dictText 字段已由 DictAspect 运行时反查填充。

---

### 步骤 7: `index.vue` 调整

```ts
// 改前
import { queryBatchList, getExportUrl } from './traceability.api';
const { tableContext, onExportXls } = useListPage({
  designScope: 'mes-batch-traceability',
  tableProps: {
    api: queryBatchList,
    // ...
  },
  exportConfig: { name: '批次追溯', url: getExportUrl },
});

// 改后
import { queryTraceabilityList, getTraceabilityExportUrl } from './traceability.api';
const { tableContext, onExportXls } = useListPage({
  designScope: 'mes-batch-traceability',
  tableProps: {
    api: queryTraceabilityList,
    // ...
  },
  exportConfig: { name: '批次追溯', url: getTraceabilityExportUrl },
});
```

---

### 步骤 8: SQL 锚点 + 索引

**位置：** `jeecg-boot/jeecg-boot-module/project-mes/db/V10.0.3__mes_traceability_batch_level.sql`

```sql
-- ============================================================
-- V10.0.3  MES批次追溯-批次级列表改造
-- 作者:ruiwancheng  日期:2026-08-03
--
-- 业务改动：
--   - 批次追溯页面(/mes/batch/traceability/list) 改为批次级
--   - 实体 MesBatchTraceabilityVO 聚合自 c_mes_batch + c_mes_batch_ledger
--   - 新增 idx_bl_batch_del 复合索引加速 LEFT JOIN (评审建议)
-- ============================================================

-- 1. 复合索引（MySQL 5.7 兼容：存储过程判定）
DROP PROCEDURE IF EXISTS mes_add_batch_ledger_idx;
DELIMITER //
CREATE PROCEDURE mes_add_batch_ledger_idx()
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.statistics 
                   WHERE table_schema = DATABASE() 
                     AND table_name = 'c_mes_batch_ledger' 
                     AND index_name = 'idx_bl_batch_del') THEN
        CREATE INDEX idx_bl_batch_del ON c_mes_batch_ledger(batch_id, del_flag);
    END IF;
END //
DELIMITER ;
CALL mes_add_batch_ledger_idx();
DROP PROCEDURE IF EXISTS mes_add_batch_ledger_idx;

-- 2. 版本锚点（无 DDL）
SELECT 1;
```

---

### 步骤 9: 验证

#### 单元测试（curl）

```bash
# 1. 编译（先 install 不能只 compile）
cd jeecg-boot && mvn clean install -DskipTests -pl jeecg-boot-module/project-mes -am

# 2. 重启后端（devtools 会自动热加载；如失败手动）

# 3. 测 /list 端点（应返回批次级 + 聚合字段）
curl -s "http://localhost:8080/jeecg-boot/mes/batch/traceability/list?pageNo=1&pageSize=10" \
  -H "X-Access-Token: $TOKEN" | jq '.result.records[0] | {id, batchNo, totalInQty, totalOutQty, ledgerCount, lastOccurTime}'
# 期望：id 是 batch_id；ledgerCount >= 1

# 4. 搜索
curl -s ".../list?batchNo=PC-20260802-001" | jq '.result.records | length'
# 期望：>= 1

# 5. 字典反查
curl -s ".../list" | jq '.result.records[0] | {materialId, materialId_dictText, originType_dictText, status_dictText}'
# 期望：dictText 字段有值

# 6. 抽屉
curl -s ".../mes/batch/ledger/listByBatchId?batchId=$BATCH_ID" | jq '.result | length'
# 期望：>= 1

# 7. 导出
curl -s ".../mes/batch/traceability/exportXls" -H "X-Access-Token: $TOKEN" -o /tmp/trace.xlsx
# 期望：xlsx 文件，每行一个批次
```

#### 浏览器端到端

```
1. 打开 /mes/batch/traceability
2. 列表第一行：批次号 + 物料 + 来源类型 + 累计入库 + 累计出库 + 流水条数 + 状态
3. 点击"查看追溯" → 抽屉打开
4. 抽屉顶部：批次主档（批次号/物料/初始数量/单位成本/生产日期/有效期/来源类型/来源单据）
5. 抽屉底部"批次流水"：每条 ledger 流水
6. 搜索 "PC-20260802-001" → 列表过滤该批次
7. 点击导出 → 下载批次级 xlsx
```

#### 回归测试
- [ ] 批次详情抽屉：流水表正确显示
- [ ] 导出 Excel：批次级数据（每个批次一行）
- [ ] 字段 dict 反查：materialId_dictText / originType_dictText / status_dictText 正常
- [ ] 空数据：c_mes_batch 有但 ledger 0 条 → 列表该批次仍出现（ledger_count=0）
- [ ] 多流水：采购入库 + 领料 + 销售出库 → 累计入/出库累加正确
- [ ] 默认排序：last_occur_time DESC（无流水批次排在最后）

---

## 📊 风险评估（评审加固后）

| 风险 | 等级 | 缓解 |
|---|---|---|
| 当前 api.ts 调 master 端点（前 P0 发现） | 已防 | 步骤 5 显式拆分 |
| Controller 泛型不一致 | 中 | 步骤 4 不 override 父类，独立声明 |
| exportXls 导出方式（旧 super 失效） | 中 | 步骤 4 手写导出 |
| @Dict 在 VO 上生效 | 已验证 | DictAspect 反射运行时 class |
| 索引覆盖 | 低 | 步骤 8 加 (batch_id, del_flag) 复合索引 |
| 现有 `MesBatchTraceability` 实体 | 低 | 保留不删，export 端点不再用 |

---

## 🚫 不做范围

- 不新建独立表（V10.0.2 init.sql 已说明）
- 不补"采购入库时没写 ledger"的 bug（用户说不排查）
- 不改 field/c_mes_batch_ledger 字段

---

## ✅ 完成标准

- [ ] MesBatchTraceabilityVO 新建（含 @Dict + @Excel）
- [ ] Mapper XML SQL 跑通（SQLyog / MySQL Workbench 验证）
- [ ] Controller /list 返回批次级（含聚合字段）
- [ ] Controller /exportXls 手写导出
- [ ] 前端 api.ts 拆分（master 重导出移除）
- [ ] 前端 data.ts columns 重写（聚合字段）
- [ ] index.vue 切换到 queryTraceabilityList + getTraceabilityExportUrl
- [ ] 复合索引 idx_bl_batch_del 创建
- [ ] mvn install 通过
- [ ] 端到端验证：列表 + 抽屉 + 搜索 + 导出
- [ ] 回归：抽屉流水表正常
- [ ] commit + push

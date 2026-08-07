//update-begin---author:ruiwancheng---date:2026-07-25---for: V9.7.1 库存总览-实时库存快照查询-----------
package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.SecurityUtils;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.basic.cleanup.service.IMesInventoryCleanupAuditService;
import org.jeecg.modules.mes.basic.mapper.MesInventoryMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Map;

@Slf4j
@Tag(name = "MES-库存总览")
@RestController
@RequestMapping("/mes/warehouse/inventory")
@Validated
public class MesInventoryController {

    @Autowired
    private MesInventoryMapper inventoryMapper;

    //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】注入审计 Service（阶段 2）-----------
    @Autowired
    private IMesInventoryCleanupAuditService cleanupAuditService;
    //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】审计 Service 注入-----------

    @Operation(summary = "库存总览列表(含物料成本+库存金额)")
    @GetMapping("/list")
    @RequiresPermissions("mes:inventory:list")
    public Result<IPage<Map<String, Object>>> queryPageList(
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize,
            HttpServletRequest req) {

        String keyword = req.getParameter("keyword");
        String warehouseId = req.getParameter("warehouseId");
        //update-begin---author:ruiwancheng---date:2026-07-29---for: /debug 盘点抽盘账面数拉取-materialId过滤支持-----------
        String materialId = req.getParameter("materialId");
        //update-end---author:ruiwancheng---date:2026-07-29---for: materialId过滤-----------

        List<Map<String, Object>> allRows = inventoryMapper.selectInventoryWithMaterial(
                (keyword != null && !keyword.isEmpty()) ? keyword : null,
                (warehouseId != null && !warehouseId.isEmpty()) ? warehouseId : null,
                //update-begin---author:ruiwancheng---date:2026-07-29---for: materialId过滤-----------
                (materialId != null && !materialId.isEmpty()) ? materialId : null);
                //update-end---author:ruiwancheng---date:2026-07-29---for: materialId过滤-----------

        // 计算库存金额 + 手动分页
        for (Map<String, Object> row : allRows) {
            Object qty = row.get("current_qty");
            Object cost = row.get("moving_avg_cost");
            BigDecimal bdQty = qty != null ? new BigDecimal(qty.toString()) : BigDecimal.ZERO;
            BigDecimal bdCost = cost != null ? new BigDecimal(cost.toString()) : BigDecimal.ZERO;
            row.put("inventory_amount", bdQty.multiply(bdCost).setScale(2, RoundingMode.HALF_UP));
        }

        int total = allRows.size();
        int from = (pageNo - 1) * pageSize;
        int to = Math.min(from + pageSize, total);
        List<Map<String, Object>> pageRows = from < total ? allRows.subList(from, to) : List.of();

        IPage<Map<String, Object>> page = new Page<>(pageNo, pageSize, total);
        page.setRecords(pageRows);
        return Result.ok(page);
    }

    //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】4 个端点（阶段 2）-----------

    /** 单删孤儿行：仅允许 qty=0 的孤儿行；material_del_flag 派生 risk_type */
    @DeleteMapping("/deleteOrphan")
    @RequiresPermissions("mes:inventory:deleteOrphan")
    @Transactional(rollbackFor = Exception.class)
    public Result<String> deleteOrphan(@RequestParam @NotNull String id) {
        Map<String, Object> row = inventoryMapper.selectOrphanById(id);
        if (row == null) {
            throw new JeecgBootException("该库存行不是孤儿行，禁止删除");
        }
        BigDecimal qty = (BigDecimal) row.get("current_qty");
        if (qty != null && qty.compareTo(BigDecimal.ZERO) > 0) {
            throw new JeecgBootException("孤儿行有库存(" + qty + ")，禁止删除");
        }
        inventoryMapper.deleteById(id);
        String riskType = deriveRiskType(row);
        String operator = getCurrentUsername();
        // P1-4：source 三元化（ui:<username> / sql-emergency / cron:<jobname>），避免 "system" 串扰
        cleanupAuditService.log("ui:" + operator, id,
                (String) row.get("material_id"),
                (String) row.get("warehouse_id"),
                qty, riskType, operator);
        return Result.ok("已删除孤儿行 " + id);
    }

    @Data
    public static class BatchDeleteOrphanRequest {
        @NotEmpty(message = "ids 不能为空")
        @Size(max = 500, message = "单批最多 500 条")
        private List<@NotNull String> ids;
    }

    /** 批量删孤儿行：@RequestBody + POST，避免 query string 超长触发 HTTP 414 */
    @PostMapping("/batchDeleteOrphan")
    @RequiresPermissions("mes:inventory:batchDeleteOrphan")
    @Transactional(rollbackFor = Exception.class)
    public Result<String> batchDeleteOrphan(@RequestBody @Valid BatchDeleteOrphanRequest req) {
        List<String> idList = req.getIds();
        List<Map<String, Object>> orphans = inventoryMapper.selectOrphansByIds(idList);
        if (orphans.isEmpty()) {
            return Result.ok("无可删除的孤儿行");
        }
        for (Map<String, Object> row : orphans) {
            BigDecimal qty = (BigDecimal) row.get("current_qty");
            if (qty != null && qty.compareTo(BigDecimal.ZERO) > 0) {
                throw new JeecgBootException("孤儿行 " + row.get("id") + " 有库存(" + qty + ")，禁止批量删");
            }
        }
        for (Map<String, Object> row : orphans) {
            inventoryMapper.deleteById((String) row.get("id"));
            String riskType = deriveRiskType(row);
            String operator = getCurrentUsername();
            // P1-4：source 三元化，与单删保持一致
            cleanupAuditService.log("ui:" + operator, (String) row.get("id"),
                    (String) row.get("material_id"),
                    (String) row.get("warehouse_id"),
                    (BigDecimal) row.get("current_qty"), riskType, operator);
        }
        return Result.ok("已删除 " + orphans.size() + " 条孤儿行");
    }

    /** 导出孤儿清单：EasyExcel 流式，LIMIT 由 Mapper 强制（防止 OOM） */
    @GetMapping("/exportOrphanXls")
    @RequiresPermissions("mes:inventory:export")
    public void exportOrphanXls(HttpServletResponse response) {
        // P0-2：旧实现披 xlsx 外衣写 plain text，Excel 打开报错。
        // 显式拒绝 + 指引用户走应急 SQL/CSV，避免浏览器下载坏文件。
        throw new UnsupportedOperationException(
                "exportOrphanXls 待 Slice 3+ 补齐 EasyExcel 实现。当前请走 SQL 应急脚本或前端 CSV 导出");
    }

    /** 孤儿行总数：权限沿用 list（轻量只读） */
    @GetMapping("/orphanCount")
    @RequiresPermissions("mes:inventory:list")
    public Result<Long> orphanCount() {
        return Result.ok(inventoryMapper.countOrphans());
    }

    /** risk_type 派生：material.del_flag=1 → B2（软删），否则 A2（硬删 LEFT JOIN miss） */
    private String deriveRiskType(Map<String, Object> row) {
        Integer materialDelFlag = (Integer) row.get("material_del_flag");
        boolean isSoftDeleted = materialDelFlag != null && materialDelFlag == 1;
        return isSoftDeleted ? "B2" : "A2";
    }

    private String getCurrentUsername() {
        try {
            LoginUser user = (LoginUser) SecurityUtils.getSubject().getPrincipal();
            return user != null ? user.getUsername() : "system";
        } catch (Exception e) {
            return "system";
        }
    }
    //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】4 个端点-----------
}
//update-end---author:ruiwancheng---date:2026-07-25---for: V9.7.1 库存总览-----------

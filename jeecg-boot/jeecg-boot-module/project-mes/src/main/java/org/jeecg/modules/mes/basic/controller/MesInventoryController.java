//update-begin---author:ruiwancheng---date:2026-07-25---for: V9.7.1 库存总览-实时库存快照查询-----------
package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.modules.mes.basic.mapper.MesInventoryMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
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
public class MesInventoryController {

    @Autowired
    private MesInventoryMapper inventoryMapper;

    @Operation(summary = "库存总览列表(含物料成本+库存金额)")
    @GetMapping("/list")
    @RequiresPermissions("mes:inventory:list")
    public Result<IPage<Map<String, Object>>> queryPageList(
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize,
            HttpServletRequest req) {

        String keyword = req.getParameter("keyword");
        String warehouseId = req.getParameter("warehouseId");

        List<Map<String, Object>> allRows = inventoryMapper.selectInventoryWithMaterial(
                (keyword != null && !keyword.isEmpty()) ? keyword : null,
                (warehouseId != null && !warehouseId.isEmpty()) ? warehouseId : null);

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
}
//update-end---author:ruiwancheng---date:2026-07-25---for: V9.7.1 库存总览-----------

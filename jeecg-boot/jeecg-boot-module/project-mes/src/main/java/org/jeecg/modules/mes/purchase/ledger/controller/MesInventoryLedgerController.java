//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-库存台账接口-----------
package org.jeecg.modules.mes.purchase.ledger.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.purchase.ledger.entity.MesInventoryLedger;
import org.jeecg.modules.mes.purchase.ledger.service.IMesInventoryLedgerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.List;

@Slf4j
@Tag(name = "MES-库存台账")
@RestController
@RequestMapping("/mes/warehouse/ledger")
public class MesInventoryLedgerController extends JeecgController<MesInventoryLedger, IMesInventoryLedgerService> {
    @Autowired
    private IMesInventoryLedgerService service;

    private static final int QUERY_ALL_MAX = 5000;

    @Operation(summary = "台账列表")
    @GetMapping("/list")
    @RequiresPermissions("mes:inventoryLedger:list")
    public Result<IPage<MesInventoryLedger>> queryPageList(MesInventoryLedger entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesInventoryLedger> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("record_date").orderByAsc("material_id");
        IPage<MesInventoryLedger> page = service.page(new Page<>(pageNo, pageSize), qw);
        //update-begin---author:ruiwancheng---date:2026-07-28---for: A+ 成本差异实时计算（与库存总览 inventory_amount 同模式）-----------
        fillCostDiff(page.getRecords());
        //update-end---author:ruiwancheng---date:2026-07-28---for: A+ 成本差异-----------
        return Result.ok(page);
    }

    //update-begin---author:ruiwancheng---date:2026-07-28---for: A+ 成本差异实时计算-----------
    @Autowired
    private org.jeecg.modules.mes.basic.service.IMesMaterialService materialService;

    /** 成本差异 = (单位成本 - 当前移动平均成本) × 数量；手工价与移动平均的漂移可度量可归因 */
    private void fillCostDiff(java.util.List<MesInventoryLedger> records) {
        if (records == null || records.isEmpty()) return;
        java.util.Set<String> matIds = records.stream().map(MesInventoryLedger::getMaterialId)
                .filter(java.util.Objects::nonNull).collect(java.util.stream.Collectors.toSet());
        if (matIds.isEmpty()) return;
        java.util.Map<String, java.math.BigDecimal> costMap = new java.util.HashMap<>();
        materialService.listByIds(matIds).forEach(m ->
                costMap.put(m.getId(), m.getMovingAvgCost() != null ? m.getMovingAvgCost() : java.math.BigDecimal.ZERO));
        for (MesInventoryLedger r : records) {
            java.math.BigDecimal avg = costMap.getOrDefault(r.getMaterialId(), java.math.BigDecimal.ZERO);
            r.setMovingAvgCost(avg);
            if (r.getUnitCost() != null) {
                java.math.BigDecimal qty = (r.getInQty() != null ? r.getInQty() : java.math.BigDecimal.ZERO)
                        .add(r.getOutQty() != null ? r.getOutQty() : java.math.BigDecimal.ZERO);
                r.setCostDiff(r.getUnitCost().subtract(avg).multiply(qty).setScale(2, java.math.RoundingMode.HALF_UP));
            }
        }
    }
    //update-end---author:ruiwancheng---date:2026-07-28---for: A+ 成本差异-----------

    @Operation(summary = "查询全部台账")
    @GetMapping("/queryAll")
    @RequiresPermissions("mes:inventoryLedger:list")
    public Result<List<MesInventoryLedger>> queryAll() {
        long total = service.count();
        if (total > QUERY_ALL_MAX) throw new JeecgBootException("台账超过" + QUERY_ALL_MAX + "条，请使用分页接口");
        return Result.ok(service.list());
    }

    @Operation(summary = "导出Excel")
    @GetMapping("/exportXls")
    @RequiresPermissions("mes:inventoryLedger:export")
    public ModelAndView exportXls(MesInventoryLedger entity, HttpServletRequest req) {
        long total = service.count(new QueryWrapper<>());
        if (total > QUERY_ALL_MAX) throw new JeecgBootException("台账超过" + QUERY_ALL_MAX + "条，请使用分页导出");
        return super.exportXls(req, entity, MesInventoryLedger.class, "库存台账");
    }
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-库存台账接口-----------

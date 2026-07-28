//update-begin---author:ruiwancheng---date:2026-07-28---for: V9.9.0 MES盘点单-Controller-----------
package org.jeecg.modules.mes.stock.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.stock.entity.MesStocktake;
import org.jeecg.modules.mes.stock.service.IMesStocktakeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;

@Slf4j
@Tag(name = "MES-盘点单")
@RestController
@RequestMapping("/mes/stock/stocktake")
public class MesStocktakeController extends JeecgController<MesStocktake, IMesStocktakeService> {
    @Autowired
    private IMesStocktakeService service;

    @Operation(summary = "盘点单列表")
    @GetMapping("/list")
    @RequiresPermissions("mes:stocktake:list")
    public Result<IPage<MesStocktake>> queryPageList(MesStocktake entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesStocktake> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @Operation(summary = "按ID查询（含盘点明细）")
    @GetMapping("/queryById")
    @RequiresPermissions("mes:stocktake:list")
    public Result<MesStocktake> queryById(@RequestParam String id) {
        return Result.ok(service.queryWithItems(id));
    }

    @Operation(summary = "新增盘点单（全盘自动快照账面库存为明细）")
    @PostMapping("/add")
    @RequiresPermissions("mes:stocktake:add")
    public Result<String> add(@RequestBody MesStocktake entity) {
        service.saveWithItems(entity);
        return Result.ok("添加成功");
    }

    @Operation(summary = "编辑盘点单（仅草稿，录入实盘数）")
    @PutMapping("/edit")
    @RequiresPermissions("mes:stocktake:edit")
    public Result<String> edit(@RequestBody MesStocktake entity) {
        service.updateWithItems(entity);
        return Result.ok("编辑成功");
    }

    @Operation(summary = "删除盘点单（仅草稿）")
    @DeleteMapping("/delete")
    @RequiresPermissions("mes:stocktake:delete")
    public Result<String> delete(@RequestParam String id) {
        service.removeWithItems(id);
        return Result.ok("删除成功");
    }

    @Operation(summary = "审核盘点单（差异自动生成盘盈入库/盘亏出库并审核）")
    @PutMapping("/audit")
    @RequiresPermissions("mes:stocktake:audit")
    public Result<String> audit(@RequestParam String id) {
        return Result.ok(service.audit(id));
    }
}
//update-end---author:ruiwancheng---date:2026-07-28---for: V9.9.0 MES盘点单-Controller-----------

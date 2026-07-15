//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售订单接口-----------
package org.jeecg.modules.mes.sales.controller;

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
import org.jeecg.modules.mes.sales.entity.MesSalesOrder;
import org.jeecg.modules.mes.sales.service.IMesSalesOrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-销售订单")
@RestController
@RequestMapping("/mes/sales/order")
public class MesSalesOrderController extends JeecgController<MesSalesOrder, IMesSalesOrderService> {
    @Autowired
    private IMesSalesOrderService service;

    private static final int QUERY_ALL_MAX = 1000;

    @Operation(summary = "订单列表")
    @GetMapping("/list")
    @RequiresPermissions("mes:salesOrder:list")
    public Result<IPage<MesSalesOrder>> queryPageList(MesSalesOrder entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesSalesOrder> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @Operation(summary = "按ID查询（含订单行）")
    @GetMapping("/queryById")
    @RequiresPermissions("mes:salesOrder:list")
    public Result<MesSalesOrder> queryById(@RequestParam String id) {
        MesSalesOrder entity = service.queryWithItems(id);
        return entity != null ? Result.ok(entity) : Result.error("订单不存在");
    }

    @Operation(summary = "新增订单（含订单行）")
    @PostMapping("/add")
    @RequiresPermissions("mes:salesOrder:add")
    public Result<String> add(@RequestBody MesSalesOrder entity) { service.saveWithItems(entity); return Result.ok("添加成功"); }

    @Operation(summary = "编辑订单（含订单行）")
    @PutMapping("/edit")
    @RequiresPermissions("mes:salesOrder:edit")
    public Result<String> edit(@RequestBody MesSalesOrder entity) { service.updateWithItems(entity); return Result.ok("编辑成功"); }

    @Operation(summary = "删除订单")
    @DeleteMapping("/delete")
    @RequiresPermissions("mes:salesOrder:delete")
    public Result<String> delete(@RequestParam String id) { service.removeWithItems(id); return Result.ok("删除成功"); }

    @Operation(summary = "批量删除")
    @DeleteMapping("/deleteBatch")
    @RequiresPermissions("mes:salesOrder:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) {
        if (ids == null || ids.isEmpty()) return Result.ok("无需删除");
        List<String> idList = Arrays.stream(ids.split(",")).filter(s -> !s.isEmpty()).collect(Collectors.toList());
        if (idList.isEmpty()) return Result.ok("无需删除");
        service.removeByIds(idList);
        return Result.ok("批量删除成功");
    }

    @Operation(summary = "查询全部订单")
    @GetMapping("/queryAll")
    @RequiresPermissions("mes:salesOrder:list")
    public Result<List<MesSalesOrder>> queryAll() {
        long total = service.count();
        if (total > QUERY_ALL_MAX) throw new JeecgBootException("订单超过" + QUERY_ALL_MAX + "条，请使用分页接口");
        return Result.ok(service.list());
    }

    @Operation(summary = "导出Excel")
    @GetMapping("/exportXls")
    @RequiresPermissions("mes:salesOrder:export")
    public ModelAndView exportXls(MesSalesOrder entity, HttpServletRequest req) {
        long total = service.count(new QueryWrapper<>());
        if (total > QUERY_ALL_MAX) throw new JeecgBootException("订单超过" + QUERY_ALL_MAX + "条，请使用分页导出");
        return super.exportXls(req, entity, MesSalesOrder.class, "销售订单");
    }
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售订单接口-----------

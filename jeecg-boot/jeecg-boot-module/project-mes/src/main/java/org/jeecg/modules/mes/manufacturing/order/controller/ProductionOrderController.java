//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产订单接口-----------
package org.jeecg.modules.mes.manufacturing.order.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.manufacturing.order.entity.MesProductionOrder;
import org.jeecg.modules.mes.manufacturing.order.service.IProductionOrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-生产订单")
@RestController
@RequestMapping("/mes/manufacturing/order")
public class ProductionOrderController extends JeecgController<MesProductionOrder, IProductionOrderService> {
    @Autowired private IProductionOrderService service;
    private static final int QUERY_ALL_MAX = 1000;

    @GetMapping("/list") @RequiresPermissions("mes:productionOrder:list")
    public Result<IPage<MesProductionOrder>> queryPageList(MesProductionOrder entity, @RequestParam(defaultValue = "1") Integer pageNo, @RequestParam(defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesProductionOrder> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @GetMapping("/queryById") @RequiresPermissions("mes:productionOrder:list")
    public Result<MesProductionOrder> queryById(@RequestParam String id) { MesProductionOrder e = service.getById(id); return e != null ? Result.ok(e) : Result.error("订单不存在"); }

    @PostMapping("/add") @RequiresPermissions("mes:productionOrder:add")
    public Result<String> add(@RequestBody MesProductionOrder entity) { service.save(entity); return Result.ok("添加成功"); }

    @PutMapping("/edit") @RequiresPermissions("mes:productionOrder:edit")
    public Result<String> edit(@RequestBody MesProductionOrder entity) { service.updateById(entity); return Result.ok("编辑成功"); }

    @DeleteMapping("/delete") @RequiresPermissions("mes:productionOrder:delete")
    public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }

    @DeleteMapping("/deleteBatch") @RequiresPermissions("mes:productionOrder:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) {
        if (ids == null || ids.isEmpty()) return Result.ok("无需删除");
        List<String> idList = Arrays.stream(ids.split(",")).filter(s -> !s.isEmpty()).collect(Collectors.toList());
        if (idList.isEmpty()) return Result.ok("无需删除");
        service.removeByIds(idList);
        return Result.ok("批量删除成功");
    }

    @GetMapping("/queryAll") @RequiresPermissions("mes:productionOrder:list")
    public Result<List<MesProductionOrder>> queryAll() {
        if (service.count() > QUERY_ALL_MAX) throw new JeecgBootException("订单超过" + QUERY_ALL_MAX + "条");
        return Result.ok(service.list());
    }

    @GetMapping("/exportXls") @RequiresPermissions("mes:productionOrder:export")
    public ModelAndView exportXls(MesProductionOrder entity, HttpServletRequest req) {
        if (service.count(new QueryWrapper<>()) > QUERY_ALL_MAX) throw new JeecgBootException("订单超过" + QUERY_ALL_MAX + "条");
        return super.exportXls(req, entity, MesProductionOrder.class, "生产订单");
    }
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产订单接口-----------

//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库接口-----------
package org.jeecg.modules.mes.purchase.receipt.controller;

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
import org.jeecg.modules.mes.purchase.receipt.entity.MesPurchaseReceipt;
import org.jeecg.modules.mes.purchase.receipt.service.IMesPurchaseReceiptService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-采购入库")
@RestController
@RequestMapping("/mes/purchase/receipt")
public class MesPurchaseReceiptController extends JeecgController<MesPurchaseReceipt, IMesPurchaseReceiptService> {
    @Autowired
    private IMesPurchaseReceiptService service;

    private static final int QUERY_ALL_MAX = 1000;

    @Operation(summary = "入库单列表")
    @GetMapping("/list")
    @RequiresPermissions("mes:purchaseReceipt:list")
    public Result<IPage<MesPurchaseReceipt>> queryPageList(MesPurchaseReceipt entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesPurchaseReceipt> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @Operation(summary = "按ID查询（含入库行）")
    @GetMapping("/queryById")
    @RequiresPermissions("mes:purchaseReceipt:list")
    public Result<MesPurchaseReceipt> queryById(@RequestParam String id) {
        MesPurchaseReceipt entity = service.queryWithItems(id);
        return entity != null ? Result.ok(entity) : Result.error("入库单不存在");
    }

    @Operation(summary = "新增入库单（含入库行）")
    @PostMapping("/add")
    @RequiresPermissions("mes:purchaseReceipt:add")
    public Result<String> add(@RequestBody MesPurchaseReceipt entity) { service.saveWithItems(entity); return Result.ok("添加成功"); }

    @Operation(summary = "编辑入库单（含入库行）")
    @PutMapping("/edit")
    @RequiresPermissions("mes:purchaseReceipt:edit")
    public Result<String> edit(@RequestBody MesPurchaseReceipt entity) { service.updateWithItems(entity); return Result.ok("编辑成功"); }

    @Operation(summary = "删除入库单")
    @DeleteMapping("/delete")
    @RequiresPermissions("mes:purchaseReceipt:delete")
    public Result<String> delete(@RequestParam String id) { service.removeWithItems(id); return Result.ok("删除成功"); }

    @Operation(summary = "批量删除")
    @DeleteMapping("/deleteBatch")
    @RequiresPermissions("mes:purchaseReceipt:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) {
        if (ids == null || ids.isEmpty()) return Result.ok("无需删除");
        List<String> idList = Arrays.stream(ids.split(",")).filter(s -> !s.isEmpty()).collect(Collectors.toList());
        if (idList.isEmpty()) return Result.ok("无需删除");
        service.removeByIds(idList);
        return Result.ok("批量删除成功");
    }

    @Operation(summary = "查询全部入库单")
    @GetMapping("/queryAll")
    @RequiresPermissions("mes:purchaseReceipt:list")
    public Result<List<MesPurchaseReceipt>> queryAll() {
        long total = service.count();
        if (total > QUERY_ALL_MAX) throw new JeecgBootException("入库单超过" + QUERY_ALL_MAX + "条，请使用分页接口");
        return Result.ok(service.list());
    }

    @Operation(summary = "导出Excel")
    @GetMapping("/exportXls")
    @RequiresPermissions("mes:purchaseReceipt:export")
    public ModelAndView exportXls(MesPurchaseReceipt entity, HttpServletRequest req) {
        long total = service.count(new QueryWrapper<>());
        if (total > QUERY_ALL_MAX) throw new JeecgBootException("入库单超过" + QUERY_ALL_MAX + "条，请使用分页导出");
        return super.exportXls(req, entity, MesPurchaseReceipt.class, "采购入库");
    }

    //update-begin---author:ruisuyun---date:2026-07-22---for: 采购入库单-选择采购单后从明细中选入库明细-----------
    @Operation(summary = "根据采购订单ID加载可入库明细行")
    @GetMapping("/loadOrderItemsForReceipt")
    @RequiresPermissions("mes:purchaseReceipt:list")
    public Result<java.util.List<org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrderItemForReceipt>> loadOrderItemsForReceipt(@RequestParam String orderId) {
        return Result.ok(service.loadOrderItemsForReceipt(orderId));
    }
    //update-end---author:ruisuyun---date:2026-07-22---for: 采购入库单-选择采购单后从明细中选入库明细-----------

    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 入库审核-采购收货-----------
    @PutMapping("/audit") @RequiresPermissions("mes:purchaseReceipt:edit")
    public Result<String> audit(@RequestParam String id) { service.audit(id); return Result.ok("审核成功，库存已更新"); }

    //update-begin---author:ruisuyun---date:2026-07-22---for: 链路P1-入库反审核-----------
    @Operation(summary = "反审核入库单")
    @PutMapping("/unaudit")
    @RequiresPermissions("mes:purchaseReceipt:edit")
    public Result<String> unaudit(@RequestParam String id) { service.unaudit(id); return Result.ok("反审核成功"); }
    //update-end---author:ruisuyun---date:2026-07-22---for: 链路P1-入库反审核-----------
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 入库审核-采购收货-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库接口-----------

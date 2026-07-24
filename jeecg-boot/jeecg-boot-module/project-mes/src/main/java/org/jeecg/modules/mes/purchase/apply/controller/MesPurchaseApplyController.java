//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请接口-----------
package org.jeecg.modules.mes.purchase.apply.controller;

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
import org.jeecg.modules.mes.purchase.apply.entity.MesPurchaseApply;
import org.jeecg.modules.mes.purchase.apply.service.IMesPurchaseApplyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-采购申请")
@RestController
@RequestMapping("/mes/purchase/apply")
public class MesPurchaseApplyController extends JeecgController<MesPurchaseApply, IMesPurchaseApplyService> {
    @Autowired
    private IMesPurchaseApplyService service;

    private static final int QUERY_ALL_MAX = 1000;

    @Operation(summary = "申请列表")
    @GetMapping("/list")
    @RequiresPermissions("mes:purchaseApply:list")
    public Result<IPage<MesPurchaseApply>> queryPageList(MesPurchaseApply entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesPurchaseApply> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @Operation(summary = "按ID查询（含申请行）")
    @GetMapping("/queryById")
    @RequiresPermissions("mes:purchaseApply:list")
    public Result<MesPurchaseApply> queryById(@RequestParam String id) {
        MesPurchaseApply entity = service.queryWithItems(id);
        return entity != null ? Result.ok(entity) : Result.error("申请不存在");
    }

    @Operation(summary = "新增申请（含申请行）")
    @PostMapping("/add")
    @RequiresPermissions("mes:purchaseApply:add")
    public Result<String> add(@RequestBody MesPurchaseApply entity) { service.saveWithItems(entity); return Result.ok("添加成功"); }

    @Operation(summary = "编辑申请（含申请行）")
    @PutMapping("/edit")
    @RequiresPermissions("mes:purchaseApply:edit")
    public Result<String> edit(@RequestBody MesPurchaseApply entity) { service.updateWithItems(entity); return Result.ok("编辑成功"); }

    @Operation(summary = "删除申请")
    @DeleteMapping("/delete")
    @RequiresPermissions("mes:purchaseApply:delete")
    public Result<String> delete(@RequestParam String id) { service.removeWithItems(id); return Result.ok("删除成功"); }

    @Operation(summary = "批量删除")
    @DeleteMapping("/deleteBatch")
    @RequiresPermissions("mes:purchaseApply:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) {
        if (ids == null || ids.isEmpty()) return Result.ok("无需删除");
        List<String> idList = Arrays.stream(ids.split(",")).filter(s -> !s.isEmpty()).collect(Collectors.toList());
        if (idList.isEmpty()) return Result.ok("无需删除");
        service.removeByIds(idList);
        return Result.ok("批量删除成功");
    }

    @Operation(summary = "查询全部申请")
    @GetMapping("/queryAll")
    @RequiresPermissions("mes:purchaseApply:list")
    public Result<List<MesPurchaseApply>> queryAll() {
        long total = service.count();
        if (total > QUERY_ALL_MAX) throw new JeecgBootException("申请超过" + QUERY_ALL_MAX + "条，请使用分页接口");
        return Result.ok(service.list());
    }

    @Operation(summary = "导出Excel")
    @GetMapping("/exportXls")
    @RequiresPermissions("mes:purchaseApply:export")
    public ModelAndView exportXls(MesPurchaseApply entity, HttpServletRequest req) {
        long total = service.count(new QueryWrapper<>());
        if (total > QUERY_ALL_MAX) throw new JeecgBootException("申请超过" + QUERY_ALL_MAX + "条，请使用分页导出");
        return super.exportXls(req, entity, MesPurchaseApply.class, "采购申请");
    }

    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.1 采购链路-审核+驳回+反审核-----------
    @Operation(summary = "审核申请(自动生成草稿采购订单)")
    @PutMapping("/audit")
    @RequiresPermissions("mes:purchaseApply:edit")
    public Result<String> audit(@RequestParam String id) { service.audit(id); return Result.ok("审核成功，已自动生成采购订单"); }

    @Operation(summary = "驳回申请")
    @PutMapping("/reject")
    @RequiresPermissions("mes:purchaseApply:edit")
    public Result<String> reject(@RequestParam String id) { service.reject(id); return Result.ok("驳回成功"); }

    @Operation(summary = "反审核申请(同步作废草稿订单)")
    @PutMapping("/unaudit")
    @RequiresPermissions("mes:purchaseApply:edit")
    public Result<String> unaudit(@RequestParam String id) { service.unaudit(id); return Result.ok("反审核成功"); }
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.1 采购链路-审核+驳回+反审核-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请接口-----------

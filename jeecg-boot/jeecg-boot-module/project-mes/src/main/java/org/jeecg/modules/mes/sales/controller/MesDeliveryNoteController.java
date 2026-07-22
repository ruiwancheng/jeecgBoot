//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单接口-----------
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
import org.jeecg.modules.mes.sales.entity.MesDeliveryNote;
import org.jeecg.modules.mes.sales.service.IMesDeliveryNoteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-发货单")
@RestController
@RequestMapping("/mes/sales/delivery")
public class MesDeliveryNoteController extends JeecgController<MesDeliveryNote, IMesDeliveryNoteService> {
    @Autowired
    private IMesDeliveryNoteService service;

    private static final int QUERY_ALL_MAX = 1000;

    @Operation(summary = "发货单列表")
    @GetMapping("/list")
    @RequiresPermissions("mes:delivery:list")
    public Result<IPage<MesDeliveryNote>> queryPageList(MesDeliveryNote entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesDeliveryNote> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @Operation(summary = "按ID查询（含明细）")
    @GetMapping("/queryById")
    @RequiresPermissions("mes:delivery:list")
    public Result<MesDeliveryNote> queryById(@RequestParam String id) {
        MesDeliveryNote entity = service.queryWithItems(id);
        return entity != null ? Result.ok(entity) : Result.error("发货单不存在");
    }

    @Operation(summary = "新增发货单（含明细）")
    @PostMapping("/add")
    @RequiresPermissions("mes:delivery:add")
    public Result<String> add(@RequestBody MesDeliveryNote entity) { service.saveWithItems(entity); return Result.ok("添加成功"); }

    @Operation(summary = "编辑发货单（含明细）")
    @PutMapping("/edit")
    @RequiresPermissions("mes:delivery:edit")
    public Result<String> edit(@RequestBody MesDeliveryNote entity) { service.updateWithItems(entity); return Result.ok("编辑成功"); }

    @Operation(summary = "删除发货单")
    @DeleteMapping("/delete")
    @RequiresPermissions("mes:delivery:delete")
    public Result<String> delete(@RequestParam String id) { service.removeWithItems(id); return Result.ok("删除成功"); }

    @Operation(summary = "批量删除")
    @DeleteMapping("/deleteBatch")
    @RequiresPermissions("mes:delivery:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) {
        if (ids == null || ids.isEmpty()) return Result.ok("无需删除");
        List<String> idList = Arrays.stream(ids.split(",")).filter(s -> !s.isEmpty()).collect(Collectors.toList());
        if (idList.isEmpty()) return Result.ok("无需删除");
        service.removeByIds(idList);
        return Result.ok("批量删除成功");
    }

    @Operation(summary = "查询全部")
    @GetMapping("/queryAll")
    @RequiresPermissions("mes:delivery:list")
    public Result<List<MesDeliveryNote>> queryAll() {
        long total = service.count();
        if (total > QUERY_ALL_MAX) throw new JeecgBootException("发货单超过" + QUERY_ALL_MAX + "条，请使用分页接口");
        return Result.ok(service.list());
    }

    @Operation(summary = "导出Excel")
    @GetMapping("/exportXls")
    @RequiresPermissions("mes:delivery:export")
    public ModelAndView exportXls(MesDeliveryNote entity, HttpServletRequest req) {
        long total = service.count(new QueryWrapper<>());
        if (total > QUERY_ALL_MAX) throw new JeecgBootException("发货单超过" + QUERY_ALL_MAX + "条，请使用分页导出");
        return super.exportXls(req, entity, MesDeliveryNote.class, "发货单");
    }

    //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-发货单-----------
    @Operation(summary = "提交发货单") @PutMapping("/submit") @RequiresPermissions("mes:delivery:edit")
    public Result<String> submit(@RequestParam String id) { service.submit(id); return Result.ok("提交成功"); }
    @Operation(summary = "签收") @PutMapping("/sign") @RequiresPermissions("mes:delivery:edit")
    public Result<String> sign(@RequestParam String id) { service.sign(id); return Result.ok("签收成功"); }
    @Operation(summary = "取消发货单") @PutMapping("/cancel") @RequiresPermissions("mes:delivery:edit")
    public Result<String> cancel(@RequestParam String id) { service.cancel(id); return Result.ok("已取消"); }
    //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-发货单-----------

    //update-begin selectPage 发货单下拉
    @Operation(summary = "发货单下拉选择")
    @GetMapping("/selectPage")
    @RequiresPermissions("mes:delivery:list")
    public Result<java.util.List<java.util.Map<String,String>>> selectPage(@RequestParam(required = false) String keyword) {
        com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<MesDeliveryNote> qw = new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
        if (org.springframework.util.StringUtils.hasText(keyword)) { qw.like(MesDeliveryNote::getCode, keyword); }
        qw.orderByDesc(MesDeliveryNote::getCreateTime).last("LIMIT 100");
        java.util.List<java.util.Map<String,String>> list = service.list(qw).stream().map(s -> {
            java.util.Map<String,String> m = new java.util.HashMap<>();
            m.put("label", s.getCode()); m.put("value", s.getId()); return m;
        }).collect(java.util.stream.Collectors.toList());
        return Result.ok(list);
    }
    //update-end selectPage
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单接口-----------

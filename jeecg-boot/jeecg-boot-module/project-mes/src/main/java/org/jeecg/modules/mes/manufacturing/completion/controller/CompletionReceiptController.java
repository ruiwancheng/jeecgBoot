//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-完工入库接口-----------
package org.jeecg.modules.mes.manufacturing.completion.controller;

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
import org.jeecg.modules.mes.manufacturing.completion.entity.MesCompletionReceipt;
import org.jeecg.modules.mes.manufacturing.completion.service.ICompletionReceiptService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-完工入库")
@RestController
@RequestMapping("/mes/manufacturing/completion")
public class CompletionReceiptController extends JeecgController<MesCompletionReceipt, ICompletionReceiptService> {
    @Autowired private ICompletionReceiptService service;
    private static final int QUERY_ALL_MAX = 1000;

    @GetMapping("/list") @RequiresPermissions("mes:completionReceipt:list")
    public Result<IPage<MesCompletionReceipt>> queryPageList(MesCompletionReceipt entity, @RequestParam(defaultValue = "1") Integer pageNo, @RequestParam(defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesCompletionReceipt> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @GetMapping("/queryById") @RequiresPermissions("mes:completionReceipt:list")
    public Result<MesCompletionReceipt> queryById(@RequestParam String id) { MesCompletionReceipt e = service.queryWithItems(id); return e != null ? Result.ok(e) : Result.error("入库单不存在"); }

    @PostMapping("/add") @RequiresPermissions("mes:completionReceipt:add")
    public Result<String> add(@RequestBody MesCompletionReceipt entity) { service.saveWithItems(entity); return Result.ok("添加成功"); }

    @PutMapping("/edit") @RequiresPermissions("mes:completionReceipt:edit")
    public Result<String> edit(@RequestBody MesCompletionReceipt entity) { service.updateWithItems(entity); return Result.ok("编辑成功"); }

    @DeleteMapping("/delete") @RequiresPermissions("mes:completionReceipt:delete")
    public Result<String> delete(@RequestParam String id) { service.removeWithItems(id); return Result.ok("删除成功"); }

    @DeleteMapping("/deleteBatch") @RequiresPermissions("mes:completionReceipt:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) {
        if (ids == null || ids.isEmpty()) return Result.ok("无需删除");
        List<String> idList = Arrays.stream(ids.split(",")).filter(s -> !s.isEmpty()).collect(Collectors.toList());
        if (idList.isEmpty()) return Result.ok("无需删除");
        service.removeByIds(idList);
        return Result.ok("批量删除成功");
    }

    @GetMapping("/queryAll") @RequiresPermissions("mes:completionReceipt:list")
    public Result<List<MesCompletionReceipt>> queryAll() {
        if (service.count() > QUERY_ALL_MAX) throw new JeecgBootException("入库单超过" + QUERY_ALL_MAX + "条");
        return Result.ok(service.list());
    }

    @GetMapping("/exportXls") @RequiresPermissions("mes:completionReceipt:export")
    public ModelAndView exportXls(MesCompletionReceipt entity, HttpServletRequest req) {
        if (service.count(new QueryWrapper<>()) > QUERY_ALL_MAX) throw new JeecgBootException("入库单超过" + QUERY_ALL_MAX + "条");
        return super.exportXls(req, entity, MesCompletionReceipt.class, "完工入库");
    }

    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 完工入库审核-----------
    @PutMapping("/audit") @RequiresPermissions("mes:completionReceipt:edit")
    public Result<String> audit(@RequestParam String id) { service.audit(id); return Result.ok("审核成功，库存已更新"); }
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 完工入库审核-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-完工入库接口-----------

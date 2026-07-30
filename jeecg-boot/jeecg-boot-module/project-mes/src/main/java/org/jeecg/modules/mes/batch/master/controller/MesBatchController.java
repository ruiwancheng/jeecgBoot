//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次主档Controller-----------
package org.jeecg.modules.mes.batch.master.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.batch.master.entity.MesBatch;
import org.jeecg.modules.mes.batch.master.service.IMesBatchService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@Slf4j
@Tag(name = "MES-批次主档")
@RestController
@RequestMapping("/mes/batch/master")
public class MesBatchController extends JeecgController<MesBatch, IMesBatchService> {
    @Autowired private IMesBatchService service;

    @GetMapping("/list")
    @RequiresPermissions("mes:batchMaster:list")
    public Result<IPage<MesBatch>> queryPageList(MesBatch entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesBatch> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @GetMapping("/queryById")
    @RequiresPermissions("mes:batchMaster:list")
    public Result<MesBatch> queryById(@RequestParam String id) {
        return Result.ok(service.getById(id));
    }

    @PostMapping("/add")
    @RequiresPermissions("mes:batchMaster:add")
    public Result<String> add(@RequestBody MesBatch entity) {
        // 由前端调 service.createBatch 自动生成 batchNo
        String id = service.createBatch(entity.getMaterialId(), entity.getOriginType(),
            entity.getOriginBillId(), entity.getOriginBillNo(),
            entity.getQty(), entity.getUnitCost(),
            entity.getProductionDate(), entity.getExpiryDate());
        return Result.ok("添加成功");
    }

    @PutMapping("/edit")
    @RequiresPermissions("mes:batchMaster:edit")
    public Result<String> edit(@RequestBody MesBatch entity) {
        service.updateById(entity);
        return Result.ok("编辑成功");
    }

    @DeleteMapping("/delete")
    @RequiresPermissions("mes:batchMaster:delete")
    public Result<String> delete(@RequestParam String id) {
        service.removeById(id);
        return Result.ok("删除成功");
    }

    @PutMapping("/freeze")
    @RequiresPermissions("mes:batchMaster:edit")
    public Result<String> freeze(@RequestParam String id) {
        service.freeze(id, getCurrentUsername());
        return Result.ok("冻结成功");
    }

    @PutMapping("/unfreeze")
    @RequiresPermissions("mes:batchMaster:edit")
    public Result<String> unfreeze(@RequestParam String id) {
        service.unfreeze(id, getCurrentUsername());
        return Result.ok("解冻成功");
    }

    private String getCurrentUsername() {
        try { return (String) org.apache.shiro.SecurityUtils.getSubject().getPrincipal(); } catch (Exception e) { return "system"; }
    }
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次主档Controller-----------

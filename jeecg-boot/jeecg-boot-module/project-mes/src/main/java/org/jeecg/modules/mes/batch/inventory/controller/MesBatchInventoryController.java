//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存Controller-----------
package org.jeecg.modules.mes.batch.inventory.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.batch.inventory.entity.MesBatchInventory;
import org.jeecg.modules.mes.batch.inventory.service.IMesBatchInventoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

@Slf4j
@Tag(name = "MES-批次库存")
@RestController
@RequestMapping("/mes/batch/inventory")
public class MesBatchInventoryController extends JeecgController<MesBatchInventory, IMesBatchInventoryService> {
    @Autowired private IMesBatchInventoryService service;
    //update-begin---author:ruiwancheng---date:2026-07-31---for: P0-4 铁拳团-批次库存导出端点-----------
    private static final int QUERY_ALL_MAX = 1000;
    //update-end---author:ruiwancheng---date:2026-07-31---for: P0-4 铁拳团-批次库存导出端点-----------

    @GetMapping("/list")
    @RequiresPermissions("mes:batchInventory:list")
    public Result<IPage<MesBatchInventory>> queryPageList(MesBatchInventory entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesBatchInventory> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @GetMapping("/queryById")
    @RequiresPermissions("mes:batchInventory:list")
    public Result<MesBatchInventory> queryById(@RequestParam String id) {
        return Result.ok(service.getById(id));
    }

    //update-begin---author:ruiwancheng---date:2026-07-31---for: P0-4 铁拳团-批次库存导出端点-----------
    @GetMapping("/exportXls")
    @RequiresPermissions("mes:batchInventory:export")
    public ModelAndView exportXls(MesBatchInventory entity, HttpServletRequest req) {
        if (service.count(new QueryWrapper<>()) > QUERY_ALL_MAX) {
            throw new JeecgBootException("批次库存超过" + QUERY_ALL_MAX + "条，请使用分页导出");
        }
        return super.exportXls(req, entity, MesBatchInventory.class, "批次库存");
    }
    //update-end---author:ruiwancheng---date:2026-07-31---for: P0-4 铁拳团-批次库存导出端点-----------
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存Controller-----------

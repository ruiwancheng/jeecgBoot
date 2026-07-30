//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存Controller-----------
package org.jeecg.modules.mes.batch.inventory.controller;

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
import org.jeecg.modules.mes.batch.inventory.entity.MesBatchInventory;
import org.jeecg.modules.mes.batch.inventory.service.IMesBatchInventoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@Slf4j
@Tag(name = "MES-批次库存")
@RestController
@RequestMapping("/mes/batch/inventory")
public class MesBatchInventoryController extends JeecgController<MesBatchInventory, IMesBatchInventoryService> {
    @Autowired private IMesBatchInventoryService service;

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
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次库存Controller-----------

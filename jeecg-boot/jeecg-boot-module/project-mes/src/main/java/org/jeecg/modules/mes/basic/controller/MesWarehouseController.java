//update-begin---author:admin---date:2026-07-06---for: MES基础设置-仓库管理接口-----------
package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.servlet.ModelAndView;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.basic.entity.MesWarehouse;
import org.jeecg.modules.mes.basic.service.IMesWarehouseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Arrays;
import java.util.List;

@Slf4j
@Tag(name = "MES-仓库管理")
@RestController
@RequestMapping("/mes/basic/warehouse")
@Validated
public class MesWarehouseController extends JeecgController<MesWarehouse, IMesWarehouseService> {
    @Autowired
    private IMesWarehouseService service;

    @GetMapping("/list")
    @RequiresPermissions("mes:warehouse:list")
    public Result<IPage<MesWarehouse>> queryPageList(MesWarehouse entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        return Result.ok(service.page(new Page<>(pageNo, pageSize), QueryGenerator.initQueryWrapper(entity, req.getParameterMap())));
    }
    @PostMapping("/add") @RequiresPermissions("mes:warehouse:add")
    public Result<String> add(@RequestBody @Valid MesWarehouse e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") @RequiresPermissions("mes:warehouse:edit")
    public Result<String> edit(@RequestBody @Valid MesWarehouse e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") @RequiresPermissions("mes:warehouse:delete")
    public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
    @DeleteMapping("/deleteBatch") @RequiresPermissions("mes:warehouse:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) { service.removeByIds(Arrays.asList(ids.split(","))); return Result.ok("批量删除"); }

    @PutMapping("/deactivate") @RequiresPermissions("mes:warehouse:edit")
    public Result<String> deactivate(@RequestParam String id) {
        MesWarehouse wh = service.getById(id);
        if (wh == null) {
            return Result.error("仓库不存在");
        }
        wh.setStatus(0);
        service.updateById(wh);
        return Result.ok("停用成功");
    }

    @PutMapping("/activate") @RequiresPermissions("mes:warehouse:edit")
    public Result<String> activate(@RequestParam String id) {
        MesWarehouse wh = service.getById(id);
        if (wh == null) {
            return Result.error("仓库不存在");
        }
        wh.setStatus(1);
        service.updateById(wh);
        return Result.ok("启用成功");
    }

    @GetMapping("/queryAll")
    @RequiresPermissions("mes:warehouse:list")
    public Result<List<MesWarehouse>> queryAll() {
        return Result.ok(service.list());
    }

    @GetMapping("/exportXls")
    @RequiresPermissions("mes:warehouse:export")
    public ModelAndView exportXls(MesWarehouse entity, HttpServletRequest req) {
        return super.exportXls(req, entity, MesWarehouse.class, "仓库管理");
    }

    @PostMapping("/importExcel")
    @RequiresPermissions("mes:warehouse:import")
    public Result<?> importExcel(HttpServletRequest request) throws Exception {
        return super.importExcel(request, null, MesWarehouse.class);
    }

    //update-begin selectPage 仓库下拉
    @Operation(summary = "仓库下拉选择")
    @GetMapping("/selectPage")
    @RequiresPermissions("mes:warehouse:list")
    public Result<java.util.List<java.util.Map<String,String>>> selectPage(@RequestParam(required = false) String keyword) {
        com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<MesWarehouse> qw = new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
        if (org.springframework.util.StringUtils.hasText(keyword)) { qw.like(MesWarehouse::getName, keyword).or().like(MesWarehouse::getCode, keyword); }
        qw.orderByAsc(MesWarehouse::getCode).last("LIMIT 100");
        java.util.List<java.util.Map<String,String>> list = service.list(qw).stream().map(s -> {
            java.util.Map<String,String> m = new java.util.HashMap<>();
            m.put("label", s.getCode() + " — " + s.getName()); m.put("value", s.getId()); return m;
        }).collect(java.util.stream.Collectors.toList());
        return Result.ok(list);
    }
    //update-end selectPage
}
//update-end---author:admin---date:2026-07-06---for: MES基础设置-仓库管理接口-----------

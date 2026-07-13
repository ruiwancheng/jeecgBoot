//update-begin---author:admin---date:2026-07-13---for: MES基础设置-库区管理接口-----------
package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
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
import org.jeecg.modules.mes.basic.entity.MesZone;
import org.jeecg.modules.mes.basic.service.IMesZoneService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Arrays;
import java.util.List;

@Slf4j
@Tag(name = "MES-库区管理")
@RestController
@RequestMapping("/mes/basic/zone")
@Validated
public class MesZoneController extends JeecgController<MesZone, IMesZoneService> {
    @Autowired
    private IMesZoneService service;

    @GetMapping("/list")
    @RequiresPermissions("mes:zone:list")
    public Result<IPage<MesZone>> queryPageList(MesZone entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        return Result.ok(service.page(new Page<>(pageNo, pageSize), QueryGenerator.initQueryWrapper(entity, req.getParameterMap())));
    }
    @PostMapping("/add") @RequiresPermissions("mes:zone:add")
    public Result<String> add(@RequestBody @Valid MesZone e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") @RequiresPermissions("mes:zone:edit")
    public Result<String> edit(@RequestBody @Valid MesZone e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") @RequiresPermissions("mes:zone:delete")
    public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
    @DeleteMapping("/deleteBatch") @RequiresPermissions("mes:zone:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) { service.removeByIds(Arrays.asList(ids.split(","))); return Result.ok("批量删除"); }

    @PutMapping("/deactivate") @RequiresPermissions("mes:zone:edit")
    public Result<String> deactivate(@RequestParam String id) {
        MesZone e = service.getById(id);
        if (e == null) return Result.error("库区不存在");
        e.setStatus(0);
        service.updateById(e);
        return Result.ok("停用成功");
    }

    @PutMapping("/activate") @RequiresPermissions("mes:zone:edit")
    public Result<String> activate(@RequestParam String id) {
        MesZone e = service.getById(id);
        if (e == null) return Result.error("库区不存在");
        e.setStatus(1);
        service.updateById(e);
        return Result.ok("启用成功");
    }

    @GetMapping("/tree")
    @RequiresPermissions("mes:zone:list")
    public Result<List<MesZone>> tree(@RequestParam String warehouseId) {
        QueryWrapper<MesZone> qw = new QueryWrapper<>();
        qw.eq("warehouse_id", warehouseId).orderByAsc("sort_no");
        return Result.ok(service.list(qw));
    }

    @GetMapping("/exportXls")
    @RequiresPermissions("mes:zone:export")
    public ModelAndView exportXls(MesZone entity, HttpServletRequest req) {
        return super.exportXls(req, entity, MesZone.class, "库区管理");
    }

    @PostMapping("/importExcel")
    @RequiresPermissions("mes:zone:import")
    public Result<?> importExcel(HttpServletRequest request) throws Exception {
        return super.importExcel(request, null, MesZone.class);
    }
}
//update-end---author:admin---date:2026-07-13---for: MES基础设置-库区管理接口-----------

//update-begin---author:admin---date:2026-07-06---for: MES基础设置-库位管理接口-----------
package org.jeecg.modules.mes.basic.controller;

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
import org.jeecg.modules.mes.basic.entity.MesLocation;
import org.jeecg.modules.mes.basic.service.IMesLocationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

@Slf4j
@Tag(name = "MES-库位管理")
@RestController
@RequestMapping("/mes/basic/location")
@Validated
public class MesLocationController extends JeecgController<MesLocation, IMesLocationService> {
    @Autowired
    private IMesLocationService service;

    @GetMapping("/list")
    @RequiresPermissions("mes:location:list")
    public Result<IPage<MesLocation>> queryPageList(MesLocation entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        return Result.ok(service.page(new Page<>(pageNo, pageSize), QueryGenerator.initQueryWrapper(entity, req.getParameterMap())));
    }
    @PostMapping("/add") @RequiresPermissions("mes:location:add")
    public Result<String> add(@RequestBody @Valid MesLocation e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") @RequiresPermissions("mes:location:edit")
    public Result<String> edit(@RequestBody @Valid MesLocation e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") @RequiresPermissions("mes:location:delete")
    public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
    @DeleteMapping("/deleteBatch") @RequiresPermissions("mes:location:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) { service.removeByIds(Arrays.asList(ids.split(","))); return Result.ok("批量删除"); }

    @PutMapping("/deactivate") @RequiresPermissions("mes:location:edit")
    public Result<String> deactivate(@RequestParam String id) {
        MesLocation e = service.getById(id);
        if (e == null) return Result.error("库位不存在");
        e.setStatus(0);
        service.updateById(e);
        return Result.ok("停用成功");
    }

    @PutMapping("/activate") @RequiresPermissions("mes:location:edit")
    public Result<String> activate(@RequestParam String id) {
        MesLocation e = service.getById(id);
        if (e == null) return Result.error("库位不存在");
        e.setStatus(1);
        service.updateById(e);
        return Result.ok("启用成功");
    }

    @PostMapping("/generate") @RequiresPermissions("mes:location:add")
    public Result<List<String>> generate(@RequestBody Map<String, Object> p) {
        return Result.ok(service.generateLocations(
            (String) p.get("shelfId"),
            Integer.parseInt(p.get("rows").toString()),
            Integer.parseInt(p.get("cols").toString())));
    }

    @GetMapping("/exportXls")
    @RequiresPermissions("mes:location:export")
    public ModelAndView exportXls(MesLocation entity, HttpServletRequest req) {
        return super.exportXls(req, entity, MesLocation.class, "库位管理");
    }

    @PostMapping("/importExcel")
    @RequiresPermissions("mes:location:import")
    public Result<?> importExcel(HttpServletRequest request) throws Exception {
        return super.importExcel(request, null, MesLocation.class);
    }
}
//update-end---author:admin---date:2026-07-06---for: MES基础设置-库位管理接口-----------

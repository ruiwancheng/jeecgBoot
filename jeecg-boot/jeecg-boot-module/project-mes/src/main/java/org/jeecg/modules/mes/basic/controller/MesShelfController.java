//update-begin---author:admin---date:2026-07-13---for: MES基础设置-货架管理接口-----------
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
import org.jeecg.modules.mes.basic.entity.MesShelf;
import org.jeecg.modules.mes.basic.service.IMesShelfService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Arrays;
import java.util.List;

@Slf4j
@Tag(name = "MES-货架管理")
@RestController
@RequestMapping("/mes/basic/shelf")
@Validated
public class MesShelfController extends JeecgController<MesShelf, IMesShelfService> {
    @Autowired
    private IMesShelfService service;

    @GetMapping("/list")
    @RequiresPermissions("mes:shelf:list")
    public Result<IPage<MesShelf>> queryPageList(MesShelf entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        return Result.ok(service.page(new Page<>(pageNo, pageSize), QueryGenerator.initQueryWrapper(entity, req.getParameterMap())));
    }
    @PostMapping("/add") @RequiresPermissions("mes:shelf:add")
    public Result<String> add(@RequestBody @Valid MesShelf e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") @RequiresPermissions("mes:shelf:edit")
    public Result<String> edit(@RequestBody @Valid MesShelf e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") @RequiresPermissions("mes:shelf:delete")
    public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
    @DeleteMapping("/deleteBatch") @RequiresPermissions("mes:shelf:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) { service.removeByIds(Arrays.asList(ids.split(","))); return Result.ok("批量删除"); }

    @PutMapping("/deactivate") @RequiresPermissions("mes:shelf:edit")
    public Result<String> deactivate(@RequestParam String id) {
        MesShelf e = service.getById(id);
        if (e == null) return Result.error("货架不存在");
        e.setStatus(0);
        service.updateById(e);
        return Result.ok("停用成功");
    }

    @PutMapping("/activate") @RequiresPermissions("mes:shelf:edit")
    public Result<String> activate(@RequestParam String id) {
        MesShelf e = service.getById(id);
        if (e == null) return Result.error("货架不存在");
        e.setStatus(1);
        service.updateById(e);
        return Result.ok("启用成功");
    }

    @GetMapping("/tree")
    @RequiresPermissions("mes:shelf:list")
    public Result<List<MesShelf>> tree(@RequestParam String zoneId) {
        QueryWrapper<MesShelf> qw = new QueryWrapper<>();
        qw.eq("zone_id", zoneId).orderByAsc("sort_no");
        return Result.ok(service.list(qw));
    }

    @GetMapping("/exportXls")
    @RequiresPermissions("mes:shelf:export")
    public ModelAndView exportXls(MesShelf entity, HttpServletRequest req) {
        return super.exportXls(req, entity, MesShelf.class, "货架管理");
    }

    @PostMapping("/importExcel")
    @RequiresPermissions("mes:shelf:import")
    public Result<?> importExcel(HttpServletRequest request) throws Exception {
        return super.importExcel(request, null, MesShelf.class);
    }
}
//update-end---author:admin---date:2026-07-13---for: MES基础设置-货架管理接口-----------

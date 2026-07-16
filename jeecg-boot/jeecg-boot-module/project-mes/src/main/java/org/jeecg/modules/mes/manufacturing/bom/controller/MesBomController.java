//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM接口-----------
package org.jeecg.modules.mes.manufacturing.bom.controller;

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
import org.jeecg.modules.mes.manufacturing.bom.entity.MesBom;
import org.jeecg.modules.mes.manufacturing.bom.service.IMesBomService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-BOM管理")
@RestController
@RequestMapping("/mes/manufacturing/bom")
public class MesBomController extends JeecgController<MesBom, IMesBomService> {
    @Autowired private IMesBomService service;
    private static final int QUERY_ALL_MAX = 1000;

    @GetMapping("/list") @RequiresPermissions("mes:bom:list")
    public Result<IPage<MesBom>> queryPageList(MesBom entity, @RequestParam(defaultValue = "1") Integer pageNo, @RequestParam(defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesBom> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @GetMapping("/queryById") @RequiresPermissions("mes:bom:list")
    public Result<MesBom> queryById(@RequestParam String id) { MesBom e = service.queryWithItems(id); return e != null ? Result.ok(e) : Result.error("BOM不存在"); }

    @PostMapping("/add") @RequiresPermissions("mes:bom:add")
    public Result<String> add(@RequestBody MesBom entity) { service.saveWithItems(entity); return Result.ok("添加成功"); }

    @PutMapping("/edit") @RequiresPermissions("mes:bom:edit")
    public Result<String> edit(@RequestBody MesBom entity) { service.updateWithItems(entity); return Result.ok("编辑成功"); }

    @DeleteMapping("/delete") @RequiresPermissions("mes:bom:delete")
    public Result<String> delete(@RequestParam String id) { service.removeWithItems(id); return Result.ok("删除成功"); }

    @DeleteMapping("/deleteBatch") @RequiresPermissions("mes:bom:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) {
        if (ids == null || ids.isEmpty()) return Result.ok("无需删除");
        List<String> idList = Arrays.stream(ids.split(",")).filter(s -> !s.isEmpty()).collect(Collectors.toList());
        if (idList.isEmpty()) return Result.ok("无需删除");
        service.removeByIds(idList);
        return Result.ok("批量删除成功");
    }

    @GetMapping("/queryAll") @RequiresPermissions("mes:bom:list")
    public Result<List<MesBom>> queryAll() {
        if (service.count() > QUERY_ALL_MAX) throw new JeecgBootException("BOM超过" + QUERY_ALL_MAX + "条");
        return Result.ok(service.list());
    }

    @GetMapping("/exportXls") @RequiresPermissions("mes:bom:export")
    public ModelAndView exportXls(MesBom entity, HttpServletRequest req) {
        if (service.count(new QueryWrapper<>()) > QUERY_ALL_MAX) throw new JeecgBootException("BOM超过" + QUERY_ALL_MAX + "条");
        return super.exportXls(req, entity, MesBom.class, "BOM管理");
    }
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM接口-----------

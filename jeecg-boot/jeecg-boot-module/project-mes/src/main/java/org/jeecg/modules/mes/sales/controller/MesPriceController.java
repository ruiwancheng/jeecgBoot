//update-begin---author:ruiwancheng---date:2026-07-14---for: MES销售管理-价格管理接口-----------
package org.jeecg.modules.mes.sales.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
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
import org.jeecg.modules.mes.sales.entity.MesPrice;
import org.jeecg.modules.mes.sales.service.IMesPriceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springframework.web.servlet.ModelAndView;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-价格管理")
@RestController
@RequestMapping("/mes/sales/price")
public class MesPriceController extends JeecgController<MesPrice, IMesPriceService> {
    @Autowired
    private IMesPriceService service;

    private static final int QUERY_ALL_MAX = 1000;

    @Operation(summary = "价格列表")
    @GetMapping("/list")
    @RequiresPermissions("mes:price:list")
    public Result<IPage<MesPrice>> queryPageList(MesPrice entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesPrice> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @Operation(summary = "按ID查询")
    @GetMapping("/queryById")
    @RequiresPermissions("mes:price:list")
    public Result<MesPrice> queryById(@RequestParam String id) {
        MesPrice entity = service.getById(id);
        return entity != null ? Result.ok(entity) : Result.error("价格记录不存在");
    }

    @Operation(summary = "新增价格")
    @PostMapping("/add")
    @RequiresPermissions("mes:price:add")
    public Result<String> add(@RequestBody MesPrice e) { service.save(e); return Result.ok("添加成功"); }

    @Operation(summary = "编辑价格")
    @PutMapping("/edit")
    @RequiresPermissions("mes:price:edit")
    public Result<String> edit(@RequestBody MesPrice e) { service.updateById(e); return Result.ok("编辑成功"); }

    @Operation(summary = "删除价格")
    @DeleteMapping("/delete")
    @RequiresPermissions("mes:price:delete")
    public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }

    @Operation(summary = "批量删除")
    @DeleteMapping("/deleteBatch")
    @RequiresPermissions("mes:price:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) {
        if (ids == null || ids.isEmpty()) return Result.ok("无需删除");
        List<String> idList = Arrays.stream(ids.split(",")).filter(s -> !s.isEmpty()).collect(Collectors.toList());
        if (idList.isEmpty()) return Result.ok("无需删除");
        service.removeByIds(idList);
        return Result.ok("批量删除成功");
    }

    @Operation(summary = "查询全部价格", description = "不分页，上限1000条")
    @GetMapping("/queryAll")
    @RequiresPermissions("mes:price:list")
    public Result<List<MesPrice>> queryAll() {
        long total = service.count();
        if (total > QUERY_ALL_MAX) throw new JeecgBootException("价格记录超过" + QUERY_ALL_MAX + "条，请使用分页接口");
        return Result.ok(service.list());
    }

    @Operation(summary = "导出Excel")
    @GetMapping("/exportXls")
    @RequiresPermissions("mes:price:export")
    public ModelAndView exportXls(MesPrice entity, HttpServletRequest req) {
        long total = service.count(new QueryWrapper<>());
        if (total > QUERY_ALL_MAX) throw new JeecgBootException("价格记录超过" + QUERY_ALL_MAX + "条，请使用分页导出");
        return super.exportXls(req, entity, MesPrice.class, "价格管理");
    }

    @Operation(summary = "导入Excel", description = "全量校验后统一导入")
    @PostMapping("/importExcel")
    @RequiresPermissions("mes:price:import")
    public Result<?> importExcel(HttpServletRequest request) throws Exception {
        MultipartHttpServletRequest multipartRequest = (MultipartHttpServletRequest) request;
        List<MesPrice> allList = new ArrayList<>();
        for (MultipartFile file : multipartRequest.getFileMap().values()) {
            org.jeecgframework.poi.excel.entity.ImportParams params = new org.jeecgframework.poi.excel.entity.ImportParams();
            params.setTitleRows(1); params.setHeadRows(1);
            List<MesPrice> list = org.jeecgframework.poi.excel.ExcelImportUtil.importExcel(file.getInputStream(), MesPrice.class, params);
            Set<String> importCodes = list.stream().map(MesPrice::getCode).filter(Objects::nonNull).collect(Collectors.toSet());
            if (importCodes.size() < list.stream().map(MesPrice::getCode).filter(Objects::nonNull).count())
                throw new JeecgBootException("导入文件中有重复的价格编码");
            if (!importCodes.isEmpty()) {
                LambdaQueryWrapper<MesPrice> existQw = new LambdaQueryWrapper<>();
                existQw.in(MesPrice::getCode, importCodes);
                if (service.count(existQw) > 0) throw new JeecgBootException("导入文件中有已存在的价格编码");
            }
            allList.addAll(list);
        }
        service.importFromExcel(allList);
        return Result.ok(String.format("导入完成：成功 %d 条", allList.size()));
    }
}
//update-end---author:ruiwancheng---date:2026-07-14---for: MES销售管理-价格管理接口-----------

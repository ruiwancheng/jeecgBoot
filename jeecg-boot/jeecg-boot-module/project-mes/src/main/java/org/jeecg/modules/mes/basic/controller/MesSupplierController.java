//update-begin---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商管理接口-----------
package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.basic.entity.MesSupplier;
import org.jeecg.modules.mes.basic.service.IMesSupplierService;
import org.jeecgframework.poi.excel.def.NormalExcelConstants;
import org.jeecgframework.poi.excel.entity.ImportParams;
import org.jeecgframework.poi.excel.view.JeecgEntityExcelView;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springframework.web.servlet.ModelAndView;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-供应商管理")
@RestController
@RequestMapping("/mes/basic/supplier")
public class MesSupplierController extends JeecgController<MesSupplier, IMesSupplierService> {
    @Autowired
    private IMesSupplierService service;

    @Operation(summary = "供应商列表", description = "分页查询供应商")
    @GetMapping("/list")
    public Result<IPage<MesSupplier>> queryPageList(MesSupplier entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesSupplier> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @Operation(summary = "新增供应商", description = "支持编码回收——删除后同编码可复用原ID")
    @PostMapping("/add") public Result<String> add(@RequestBody MesSupplier e) { service.save(e); return Result.ok("添加成功"); }

    @Operation(summary = "编辑供应商", description = "修改供应商信息并校验编码唯一性")
    @PutMapping("/edit") public Result<String> edit(@RequestBody MesSupplier e) { service.updateById(e); return Result.ok("编辑成功"); }

    @Operation(summary = "删除供应商", description = "软删除供应商")
    @DeleteMapping("/delete") public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }

    @Operation(summary = "批量删除", description = "批量软删除供应商")
    @DeleteMapping("/deleteBatch") public Result<String> deleteBatch(@RequestParam String ids) { service.removeByIds(Arrays.asList(ids.split(","))); return Result.ok("批量删除"); }

    @Operation(summary = "查询全部供应商", description = "不分页返回所有活跃供应商")
    @GetMapping("/queryAll")
    public Result<List<MesSupplier>> queryAll() {
        return Result.ok(service.list());
    }

    @Operation(summary = "导出Excel", description = "导出供应商数据为Excel文件")
    @GetMapping("/exportXls")
    public ModelAndView exportXls(MesSupplier entity, HttpServletRequest req) {
        return super.exportXls(req, entity, MesSupplier.class, "供应商管理");
    }

    @Operation(summary = "导入Excel", description = "从Excel导入供应商，自动校验编码重复")
    @PostMapping("/importExcel")
    public Result<?> importExcel(HttpServletRequest request) throws Exception {
        MultipartHttpServletRequest multipartRequest = (MultipartHttpServletRequest) request;
        Map<String, MultipartFile> fileMap = multipartRequest.getFileMap();
        int total = 0, skipped = 0;
        for (Map.Entry<String, MultipartFile> entry : fileMap.entrySet()) {
            MultipartFile file = entry.getValue();
            ImportParams params = new ImportParams();
            params.setTitleRows(1);
            params.setHeadRows(1);
            List<MesSupplier> list = org.jeecgframework.poi.excel.ExcelImportUtil.importExcel(file.getInputStream(), MesSupplier.class, params);
            Set<String> importCodes = list.stream().map(MesSupplier::getCode).filter(Objects::nonNull).collect(Collectors.toSet());
            if (importCodes.size() < list.stream().map(MesSupplier::getCode).filter(Objects::nonNull).count()) {
                throw new JeecgBootException("导入文件中有重复的供应商编码，请检查后重新导入");
            }
            LambdaQueryWrapper<MesSupplier> existQw = new LambdaQueryWrapper<>();
            existQw.in(MesSupplier::getCode, importCodes);
            long existCount = service.count(existQw);
            if (existCount > 0) {
                throw new JeecgBootException("导入文件中有 " + existCount + " 个供应商编码已存在，请检查后重新导入");
            }
            for (MesSupplier entity : list) {
                try {
                    service.save(entity);
                    total++;
                } catch (JeecgBootException e) {
                    log.warn("导入跳过: {} - {}", entity.getCode(), e.getMessage());
                    skipped++;
                }
            }
        }
        return Result.ok(String.format("导入完成：成功 %d 条，跳过 %d 条", total, skipped));
    }
}
//update-end---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商管理接口-----------

//update-begin---author:ruiwancheng---date:2026-07-14---for: MES基础设置-物料管理接口-----------
package org.jeecg.modules.mes.basic.controller;

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
import org.jeecg.modules.mes.basic.entity.MesMaterial;
import org.jeecg.modules.mes.basic.service.IMesMaterialService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.util.StringUtils;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-物料管理")
@RestController
@RequestMapping("/mes/basic/material")
public class MesMaterialController extends JeecgController<MesMaterial, IMesMaterialService> {
    @Autowired
    private IMesMaterialService service;

    private static final int QUERY_ALL_MAX = 1000;

    @Operation(summary = "物料列表")
    @GetMapping("/list")
    @RequiresPermissions("mes:material:list")
    public Result<IPage<MesMaterial>> queryPageList(MesMaterial entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesMaterial> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @Operation(summary = "按ID查询", description = "返回完整数据，供编辑表单使用")
    @GetMapping("/queryById")
    @RequiresPermissions("mes:material:list")
    public Result<MesMaterial> queryById(@RequestParam String id) {
        MesMaterial entity = service.getById(id);
        if (entity == null) {
            return Result.error("物料不存在");
        }
        return Result.ok(entity);
    }

    @Operation(summary = "新增物料")
    @PostMapping("/add")
    @RequiresPermissions("mes:material:add")
    public Result<String> add(@RequestBody MesMaterial e) { service.save(e); return Result.ok("添加成功"); }

    @Operation(summary = "编辑物料")
    @PutMapping("/edit")
    @RequiresPermissions("mes:material:edit")
    public Result<String> edit(@RequestBody MesMaterial e) { service.updateById(e); return Result.ok("编辑成功"); }

    @Operation(summary = "删除物料")
    @DeleteMapping("/delete")
    @RequiresPermissions("mes:material:delete")
    public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }

    @Operation(summary = "批量删除")
    @DeleteMapping("/deleteBatch")
    @RequiresPermissions("mes:material:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) {
        if (ids == null || ids.isEmpty()) return Result.ok("无需删除");
        List<String> idList = Arrays.stream(ids.split(",")).filter(s -> !s.isEmpty()).collect(Collectors.toList());
        if (idList.isEmpty()) return Result.ok("无需删除");
        service.removeByIds(idList);
        return Result.ok("批量删除成功");
    }

    @Operation(summary = "查询全部物料", description = "不分页，上限1000条")
    @GetMapping("/queryAll")
    @RequiresPermissions("mes:material:list")
    public Result<List<MesMaterial>> queryAll() {
        long total = service.count();
        if (total > QUERY_ALL_MAX) {
            throw new JeecgBootException("物料数量超过" + QUERY_ALL_MAX + "条，请使用分页接口查询");
        }
        return Result.ok(service.list());
    }

    //update-begin---author:ruiwancheng---date:2026-07-20  for：【物料选择窗口】新增分页查询接口，过滤del_flag+status-----------
    @Operation(summary = "物料选择分页查询", description = "用于物料选择弹窗，自动过滤已删除和已停用物料，支持keyword搜索")
    @GetMapping("/selectPage")
    @RequiresPermissions("mes:material:list")
    public Result<IPage<MesMaterial>> selectPage(
            @RequestParam(name = "keyword", defaultValue = "") String keyword,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "20") Integer pageSize) {
        QueryWrapper<MesMaterial> qw = new QueryWrapper<>();
        qw.eq("status", 1); // 仅启用的物料
        if (StringUtils.hasText(keyword)) {
            qw.and(w -> w.like("code", keyword).or().like("name", keyword).or().like("spec", keyword));
        }
        qw.orderByAsc("code");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }
    //update-end---author:ruiwancheng---date:2026-07-20  for：【物料选择窗口】新增分页查询接口，过滤del_flag+status-----------

    @Operation(summary = "导出Excel")
    @GetMapping("/exportXls")
    @RequiresPermissions("mes:material:export")
    public ModelAndView exportXls(MesMaterial entity, HttpServletRequest req) {
        long total = service.count(new QueryWrapper<>());
        if (total > QUERY_ALL_MAX) {
            throw new JeecgBootException("物料数量超过" + QUERY_ALL_MAX + "条，请使用分页导出");
        }
        return super.exportXls(req, entity, MesMaterial.class, "物料管理");
    }

    @Operation(summary = "导入Excel", description = "全量校验后统一导入")
    @PostMapping("/importExcel")
    @RequiresPermissions("mes:material:import")
    public Result<?> importExcel(HttpServletRequest request) throws Exception {
        MultipartHttpServletRequest multipartRequest = (MultipartHttpServletRequest) request;
        Map<String, MultipartFile> fileMap = multipartRequest.getFileMap();
        List<MesMaterial> allList = new ArrayList<>();
        for (MultipartFile file : fileMap.values()) {
            org.jeecgframework.poi.excel.entity.ImportParams params = new org.jeecgframework.poi.excel.entity.ImportParams();
            params.setTitleRows(1);
            params.setHeadRows(1);
            List<MesMaterial> list = org.jeecgframework.poi.excel.ExcelImportUtil.importExcel(file.getInputStream(), MesMaterial.class, params);
            Set<String> importCodes = list.stream().map(MesMaterial::getCode).filter(Objects::nonNull).collect(Collectors.toSet());
            if (importCodes.size() < list.stream().map(MesMaterial::getCode).filter(Objects::nonNull).count()) {
                throw new JeecgBootException("导入文件中有重复的物料编码");
            }
            if (!importCodes.isEmpty()) {
                LambdaQueryWrapper<MesMaterial> existQw = new LambdaQueryWrapper<>();
                existQw.in(MesMaterial::getCode, importCodes);
                long existCount = service.count(existQw);
                if (existCount > 0) {
                    throw new JeecgBootException("导入文件中有 " + existCount + " 个物料编码已存在");
                }
            }
            allList.addAll(list);
        }
        service.importFromExcel(allList);
        return Result.ok(String.format("导入完成：成功 %d 条", allList.size()));
    }
}
//update-end---author:ruiwancheng---date:2026-07-14---for: MES基础设置-物料管理接口-----------

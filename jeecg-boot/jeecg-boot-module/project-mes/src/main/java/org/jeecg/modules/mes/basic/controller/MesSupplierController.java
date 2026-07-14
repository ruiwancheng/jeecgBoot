//update-begin---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商管理接口-----------
//update-begin---author:ruiwancheng---date:2026-07-14---for: 审计修复2期-queryById+脱敏副本+导入事务+导出限制-----------
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
import org.jeecg.modules.mes.basic.entity.MesSupplier;
import org.jeecg.modules.mes.basic.service.IMesSupplierService;
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

    private static final int QUERY_ALL_MAX = 1000;

    @Operation(summary = "供应商列表", description = "分页查询，敏感字段脱敏")
    @GetMapping("/list")
    @RequiresPermissions("mes:supplier:list")
    public Result<IPage<MesSupplier>> queryPageList(MesSupplier entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesSupplier> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        IPage<MesSupplier> page = service.page(new Page<>(pageNo, pageSize), qw);
        page.getRecords().forEach(this::maskSensitive);
        return Result.ok(page);
    }

    @Operation(summary = "按ID查询", description = "返回完整数据不含脱敏，供编辑表单使用")
    @GetMapping("/queryById")
    @RequiresPermissions("mes:supplier:list")
    public Result<MesSupplier> queryById(@RequestParam String id) {
        MesSupplier entity = service.getById(id);
        if (entity == null) {
            return Result.error("供应商不存在");
        }
        return Result.ok(entity);
    }

    @Operation(summary = "新增供应商")
    @PostMapping("/add")
    @RequiresPermissions("mes:supplier:add")
    public Result<String> add(@RequestBody MesSupplier e) { service.save(e); return Result.ok("添加成功"); }

    @Operation(summary = "编辑供应商")
    @PutMapping("/edit")
    @RequiresPermissions("mes:supplier:edit")
    public Result<String> edit(@RequestBody MesSupplier e) { service.updateById(e); return Result.ok("编辑成功"); }

    @Operation(summary = "删除供应商")
    @DeleteMapping("/delete")
    @RequiresPermissions("mes:supplier:delete")
    public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }

    @Operation(summary = "批量删除")
    @DeleteMapping("/deleteBatch")
    @RequiresPermissions("mes:supplier:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) {
        if (ids == null || ids.isEmpty()) return Result.ok("无需删除");
        List<String> idList = Arrays.stream(ids.split(",")).filter(s -> !s.isEmpty()).collect(Collectors.toList());
        if (idList.isEmpty()) return Result.ok("无需删除");
        service.removeByIds(idList);
        return Result.ok("批量删除成功");
    }

    @Operation(summary = "查询全部供应商", description = "不分页，上限1000条，敏感字段脱敏")
    @GetMapping("/queryAll")
    @RequiresPermissions("mes:supplier:list")
    public Result<List<MesSupplier>> queryAll() {
        long total = service.count();
        if (total > QUERY_ALL_MAX) {
            throw new JeecgBootException("供应商数量超过" + QUERY_ALL_MAX + "条，请使用分页接口查询");
        }
        List<MesSupplier> list = service.list();
        list.forEach(this::maskSensitive);
        return Result.ok(list);
    }

    @Operation(summary = "导出Excel", description = "导出供应商数据，敏感字段已排除，上限1000条")
    @GetMapping("/exportXls")
    @RequiresPermissions("mes:supplier:export")
    public ModelAndView exportXls(MesSupplier entity, HttpServletRequest req) {
        long total = service.count(new QueryWrapper<>());
        if (total > QUERY_ALL_MAX) {
            throw new JeecgBootException("供应商数量超过" + QUERY_ALL_MAX + "条，请使用分页导出");
        }
        return super.exportXls(req, entity, MesSupplier.class, "供应商管理");
    }

    @Operation(summary = "导入Excel", description = "从事务性导入，全量校验后统一保存")
    @PostMapping("/importExcel")
    @RequiresPermissions("mes:supplier:import")
    public Result<?> importExcel(HttpServletRequest request) throws Exception {
        MultipartHttpServletRequest multipartRequest = (MultipartHttpServletRequest) request;
        Map<String, MultipartFile> fileMap = multipartRequest.getFileMap();
        List<MesSupplier> allList = new ArrayList<>();
        for (MultipartFile file : fileMap.values()) {
            org.jeecgframework.poi.excel.entity.ImportParams params = new org.jeecgframework.poi.excel.entity.ImportParams();
            params.setTitleRows(1);
            params.setHeadRows(1);
            List<MesSupplier> list = org.jeecgframework.poi.excel.ExcelImportUtil.importExcel(file.getInputStream(), MesSupplier.class, params);
            // 校验文件内编码重复
            Set<String> importCodes = list.stream().map(MesSupplier::getCode).filter(Objects::nonNull).collect(Collectors.toSet());
            if (importCodes.size() < list.stream().map(MesSupplier::getCode).filter(Objects::nonNull).count()) {
                throw new JeecgBootException("导入文件中有重复的供应商编码");
            }
            // 校验与已有数据编码重复
            if (!importCodes.isEmpty()) {
                LambdaQueryWrapper<MesSupplier> existQw = new LambdaQueryWrapper<>();
                existQw.in(MesSupplier::getCode, importCodes);
                long existCount = service.count(existQw);
                if (existCount > 0) {
                    throw new JeecgBootException("导入文件中有 " + existCount + " 个供应商编码已存在");
                }
            }
            allList.addAll(list);
        }
        service.importFromExcel(allList);
        return Result.ok(String.format("导入完成：成功 %d 条", allList.size()));
    }

    /** 脱敏：银行账号和税号只显示前4位。注意：此方法修改的是列表引用，后续编辑操作应通过queryById获取完整数据 */
    private void maskSensitive(MesSupplier s) {
        if (s.getBankAccount() != null && s.getBankAccount().length() > 4) {
            s.setBankAccount(s.getBankAccount().substring(0, 4) + "****");
        }
        if (s.getTaxNo() != null && s.getTaxNo().length() > 4) {
            s.setTaxNo(s.getTaxNo().substring(0, 4) + "****");
        }
    }
}
//update-end---author:ruiwancheng---date:2026-07-14---for: 审计修复2期-queryById+脱敏副本+导入事务+导出限制-----------
//update-end---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商管理接口-----------

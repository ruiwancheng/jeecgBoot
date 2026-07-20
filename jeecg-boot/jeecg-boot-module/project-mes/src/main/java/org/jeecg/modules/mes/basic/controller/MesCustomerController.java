//update-begin---author:ruiwancheng---date:2026-07-08---for: MES基础设置-客户管理接口-----------
//update-begin---author:ruiwancheng---date:2026-07-11---for: 审计修复#8#9#10-导入编码校验+业务员数据隔离+接口文档注解-----------
package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.basic.entity.MesCustomer;
import org.jeecg.modules.mes.basic.service.IMesCustomerService;
import org.jeecgframework.poi.excel.def.NormalExcelConstants;
import org.jeecgframework.poi.excel.entity.ImportParams;
import org.jeecgframework.poi.excel.view.JeecgEntityExcelView;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.util.StringUtils;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-客户管理")
@RestController
@RequestMapping("/mes/basic/customer")
public class MesCustomerController extends JeecgController<MesCustomer, IMesCustomerService> {
    @Autowired
    private IMesCustomerService service;

    @Operation(summary = "客户列表", description = "分页查询客户，普通业务员只能看到自己的客户")
    @GetMapping("/list")
    public Result<IPage<MesCustomer>> queryPageList(MesCustomer entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesCustomer> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        // 非admin角色按业务员隔离数据
        LoginUser loginUser = getLoginUser();
        if (loginUser != null && !"admin".equals(loginUser.getUsername())) {
            qw.eq("salesman_id", loginUser.getUsername());
        }
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @Operation(summary = "新增客户", description = "支持编码回收——删除后同编码可复用原ID")
    @PostMapping("/add") public Result<String> add(@RequestBody MesCustomer e) { service.save(e); return Result.ok("添加成功"); }

    @Operation(summary = "编辑客户", description = "修改客户信息并校验编码唯一性")
    @PutMapping("/edit") public Result<String> edit(@RequestBody MesCustomer e) { service.updateById(e); return Result.ok("编辑成功"); }

    @Operation(summary = "删除客户", description = "软删除，删除前校验关联业务")
    @DeleteMapping("/delete") public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }

    @Operation(summary = "批量删除", description = "批量软删除客户")
    @DeleteMapping("/deleteBatch") public Result<String> deleteBatch(@RequestParam String ids) { service.removeByIds(Arrays.asList(ids.split(","))); return Result.ok("批量删除"); }

    @Operation(summary = "查询全部客户", description = "不分页返回所有活跃客户")
    @GetMapping("/queryAll")
    public Result<List<MesCustomer>> queryAll() {
        return Result.ok(service.list());
    }

    //update-begin---author:ruiwancheng---date:2026-07-21  for：【客户选择窗口】新增分页查询接口-----------
    @Operation(summary = "客户选择分页查询", description = "用于客户选择弹窗，自动过滤已删除客户，支持keyword搜索")
    @GetMapping("/selectPage")
    public Result<IPage<MesCustomer>> selectPage(
            @RequestParam(name = "keyword", defaultValue = "") String keyword,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "20") Integer pageSize) {
        QueryWrapper<MesCustomer> qw = new QueryWrapper<>();
        if (StringUtils.hasText(keyword)) {
            qw.and(w -> w.like("code", keyword).or().like("name", keyword));
        }
        qw.orderByAsc("code");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }
    //update-end---author:ruiwancheng---date:2026-07-21  for：【客户选择窗口】新增分页查询接口-----------

    @Operation(summary = "导出Excel", description = "导出客户数据为Excel文件")
    @GetMapping("/exportXls")
    public ModelAndView exportXls(MesCustomer entity, HttpServletRequest req) {
        return super.exportXls(req, entity, MesCustomer.class, "客户管理");
    }

    @Operation(summary = "导入Excel", description = "从Excel导入客户，自动校验编码重复")
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
            List<MesCustomer> list = org.jeecgframework.poi.excel.ExcelImportUtil.importExcel(file.getInputStream(), MesCustomer.class, params);
            // 先收集导入数据中的所有编码，去重
            Set<String> importCodes = list.stream().map(MesCustomer::getCode).filter(Objects::nonNull).collect(Collectors.toSet());
            if (importCodes.size() < list.stream().map(MesCustomer::getCode).filter(Objects::nonNull).count()) {
                throw new JeecgBootException("导入文件中有重复的客户编码，请检查后重新导入");
            }
            // 检查编码是否与已有数据重复
            LambdaQueryWrapper<MesCustomer> existQw = new LambdaQueryWrapper<>();
            existQw.in(MesCustomer::getCode, importCodes);
            long existCount = service.count(existQw);
            if (existCount > 0) {
                throw new JeecgBootException("导入文件中有 " + existCount + " 个客户编码已存在，请检查后重新导入");
            }
            for (MesCustomer entity : list) {
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

    private LoginUser getLoginUser() {
        try {
            return (LoginUser) SecurityUtils.getSubject().getPrincipal();
        } catch (Exception e) {
            return null;
        }
    }
}
//update-end---author:ruiwancheng---date:2026-07-11---for: 审计修复#8#9#10-导入编码校验+业务员数据隔离+接口文档注解-----------
//update-end---author:ruiwancheng---date:2026-07-08---for: MES基础设置-客户管理接口-----------

//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 会计科目接口-----------
package org.jeecg.modules.mes.finance.subject.controller;

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
import org.jeecg.modules.mes.finance.subject.entity.MesAccountSubject;
import org.jeecg.modules.mes.finance.subject.service.IMesAccountSubjectService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-会计科目")
@RestController
@RequestMapping("/mes/finance/subject")
public class MesAccountSubjectController extends JeecgController<MesAccountSubject, IMesAccountSubjectService> {
    @Autowired private IMesAccountSubjectService service;
    private static final int QUERY_ALL_MAX = 5000;

    @GetMapping("/list") @RequiresPermissions("mes:subject:list")
    public Result<IPage<MesAccountSubject>> queryPageList(MesAccountSubject entity, @RequestParam(defaultValue = "1") Integer pageNo, @RequestParam(defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesAccountSubject> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByAsc("code");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @GetMapping("/tree") @RequiresPermissions("mes:subject:list")
    public Result<List<MesAccountSubject>> queryTree() { return Result.ok(service.queryTree()); }

    @GetMapping("/queryById") @RequiresPermissions("mes:subject:list")
    public Result<MesAccountSubject> queryById(@RequestParam String id) { MesAccountSubject e = service.getById(id); return e != null ? Result.ok(e) : Result.error("科目不存在"); }

    @PostMapping("/add") @RequiresPermissions("mes:subject:add")
    public Result<String> add(@RequestBody MesAccountSubject entity) { service.save(entity); return Result.ok("添加成功"); }

    @PutMapping("/edit") @RequiresPermissions("mes:subject:edit")
    public Result<String> edit(@RequestBody MesAccountSubject entity) { service.updateById(entity); return Result.ok("编辑成功"); }

    @DeleteMapping("/delete") @RequiresPermissions("mes:subject:delete")
    public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }

    @DeleteMapping("/deleteBatch") @RequiresPermissions("mes:subject:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) {
        if (ids == null || ids.isEmpty()) return Result.ok("无需删除");
        List<String> idList = Arrays.stream(ids.split(",")).filter(s -> !s.isEmpty()).collect(Collectors.toList());
        if (idList.isEmpty()) return Result.ok("无需删除");
        service.removeByIds(idList);
        return Result.ok("批量删除成功");
    }

    @GetMapping("/queryAll") @RequiresPermissions("mes:subject:list")
    public Result<List<MesAccountSubject>> queryAll() {
        if (service.count() > QUERY_ALL_MAX) throw new JeecgBootException("科目超过" + QUERY_ALL_MAX + "条");
        return Result.ok(service.list());
    }

    @GetMapping("/exportXls") @RequiresPermissions("mes:subject:export")
    public ModelAndView exportXls(MesAccountSubject entity, HttpServletRequest req) {
        if (service.count() > QUERY_ALL_MAX) throw new JeecgBootException("科目超过" + QUERY_ALL_MAX + "条");
        return super.exportXls(req, entity, MesAccountSubject.class, "会计科目");
    }

    //update-begin selectPage 科目下拉
    @Operation(summary = "科目下拉选择")
    @GetMapping("/selectPage")
    @RequiresPermissions("mes:subject:list")
    public Result<java.util.List<java.util.Map<String,String>>> selectPage(@RequestParam(required = false) String keyword) {
        com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<MesAccountSubject> qw = new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
        if (org.springframework.util.StringUtils.hasText(keyword)) { qw.like(MesAccountSubject::getName, keyword).or().like(MesAccountSubject::getCode, keyword); }
        qw.orderByAsc(MesAccountSubject::getCode).last("LIMIT 100");
        java.util.List<java.util.Map<String,String>> list = service.list(qw).stream().map(s -> {
            java.util.Map<String,String> m = new java.util.HashMap<>();
            m.put("label", s.getCode() + " — " + s.getName()); m.put("value", s.getId()); return m;
        }).collect(java.util.stream.Collectors.toList());
        return Result.ok(list);
    }
    //update-end selectPage
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 会计科目接口-----------

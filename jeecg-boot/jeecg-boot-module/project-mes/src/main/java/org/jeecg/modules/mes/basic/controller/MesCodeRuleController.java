//update-begin---author:ruiwancheng---date:2026-07-21  for：【编码规则】Controller-----------
package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.basic.entity.MesCodeRule;
import org.jeecg.modules.mes.basic.service.IMesCodeRuleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-编码规则")
@RestController
@RequestMapping("/mes/basic/codeRule")
public class MesCodeRuleController extends JeecgController<MesCodeRule, IMesCodeRuleService> {
    @Autowired
    private IMesCodeRuleService service;

    @Operation(summary = "编码规则列表")
    @GetMapping("/list")
    @RequiresPermissions("mes:codeRule:list")
    public Result<IPage<MesCodeRule>> queryPageList(MesCodeRule entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesCodeRule> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @Operation(summary = "按ID查询")
    @GetMapping("/queryById")
    @RequiresPermissions("mes:codeRule:list")
    public Result<MesCodeRule> queryById(@RequestParam String id) {
        return Result.ok(service.getById(id));
    }

    @Operation(summary = "新增")
    @PostMapping("/add")
    @RequiresPermissions("mes:codeRule:add")
    public Result<String> add(@RequestBody MesCodeRule e) { service.save(e); return Result.ok("添加成功"); }

    @Operation(summary = "编辑")
    @PutMapping("/edit")
    @RequiresPermissions("mes:codeRule:edit")
    public Result<String> edit(@RequestBody MesCodeRule e) { service.updateById(e); return Result.ok("编辑成功"); }

    @Operation(summary = "删除")
    @DeleteMapping("/delete")
    @RequiresPermissions("mes:codeRule:delete")
    public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }

    @Operation(summary = "批量删除")
    @DeleteMapping("/deleteBatch")
    @RequiresPermissions("mes:codeRule:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) {
        if (ids == null || ids.isEmpty()) return Result.ok("无需删除");
        List<String> idList = Arrays.stream(ids.split(",")).filter(s -> !s.isEmpty()).collect(Collectors.toList());
        if (idList.isEmpty()) return Result.ok("无需删除");
        service.removeByIds(idList);
        return Result.ok("批量删除成功");
    }

    @Operation(summary = "查询全部")
    @GetMapping("/queryAll")
    @RequiresPermissions("mes:codeRule:list")
    public Result<List<MesCodeRule>> queryAll() { return Result.ok(service.list()); }

    @Operation(summary = "获取下一个编码", description = "根据规则编码生成下一个业务编码")
    @GetMapping("/nextCode")
    // 权限说明：本接口故意不加 @RequiresPermissions——所有开单用户（销售/采购/生产/财务）都需取号，
    // 若限定 mes:codeRule:list 会导致无规则管理权限的业务人员自动编号静默失效。平台已强制登录即可，刷号风险可接受（2026-07-21 审计 P2 决议）
    public Result<String> nextCode(@RequestParam String ruleCode) {
        return Result.ok(service.nextCode(ruleCode));
    }

    @Operation(summary = "导出Excel")
    @GetMapping("/exportXls")
    @RequiresPermissions("mes:codeRule:export")
    public ModelAndView exportXls(MesCodeRule entity, HttpServletRequest req) {
        return super.exportXls(req, entity, MesCodeRule.class, "编码规则");
    }
}
//update-end---author:ruiwancheng---date:2026-07-21  for：【编码规则】Controller-----------

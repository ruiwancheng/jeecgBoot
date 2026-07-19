//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 应付单接口-----------
package org.jeecg.modules.mes.finance.payable.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.finance.payable.entity.MesPayable;
import org.jeecg.modules.mes.finance.payable.service.IMesPayableService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "MES-应付账款")
@RestController
@RequestMapping("/mes/finance/payable")
public class MesPayableController extends JeecgController<MesPayable, IMesPayableService> {
    @Autowired private IMesPayableService service;
    private static final int QUERY_ALL_MAX = 5000;

    @GetMapping("/list") @RequiresPermissions("mes:payable:list")
    public Result<IPage<MesPayable>> queryPageList(MesPayable entity, @RequestParam(defaultValue = "1") Integer pageNo, @RequestParam(defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesPayable> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @GetMapping("/queryById") @RequiresPermissions("mes:payable:list")
    public Result<MesPayable> queryById(@RequestParam String id) { MesPayable e = service.getById(id); return e != null ? Result.ok(e) : Result.error("应付单不存在"); }

    @GetMapping("/queryAll") @RequiresPermissions("mes:payable:list")
    public Result<List<MesPayable>> queryAll() {
        if (service.count() > QUERY_ALL_MAX) throw new JeecgBootException("应付单超过" + QUERY_ALL_MAX + "条");
        return Result.ok(service.list());
    }

    @GetMapping("/exportXls") @RequiresPermissions("mes:payable:export")
    public ModelAndView exportXls(MesPayable entity, HttpServletRequest req) {
        if (service.count() > QUERY_ALL_MAX) throw new JeecgBootException("应付单超过" + QUERY_ALL_MAX + "条");
        return super.exportXls(req, entity, MesPayable.class, "应付账款");
    }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 应付单接口-----------

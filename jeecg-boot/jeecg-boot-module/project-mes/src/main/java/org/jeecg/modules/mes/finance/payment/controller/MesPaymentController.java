//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 付款单接口-----------
package org.jeecg.modules.mes.finance.payment.controller;

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
import org.jeecg.modules.mes.finance.payment.entity.MesPayment;
import org.jeecg.modules.mes.finance.payment.service.IMesPaymentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j @Tag(name = "MES-付款管理") @RestController @RequestMapping("/mes/finance/payment")
public class MesPaymentController extends JeecgController<MesPayment, IMesPaymentService> {
    @Autowired private IMesPaymentService service;
    private static final int QUERY_ALL_MAX = 5000;

    @GetMapping("/list") @RequiresPermissions("mes:payment:list")
    public Result<IPage<MesPayment>> queryPageList(MesPayment entity, @RequestParam(defaultValue = "1") Integer pageNo, @RequestParam(defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesPayment> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap()); qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }
    @GetMapping("/queryById") @RequiresPermissions("mes:payment:list")
    public Result<MesPayment> queryById(@RequestParam String id) { MesPayment e = service.getById(id); return e != null ? Result.ok(e) : Result.error("付款单不存在"); }
    @Operation(summary = "新增付款") @PostMapping("/add") @RequiresPermissions("mes:payment:add")
    public Result<String> add(@RequestBody MesPayment entity) { service.save(entity); return Result.ok("付款成功，应付已更新"); }
    @GetMapping("/queryAll") @RequiresPermissions("mes:payment:list")
    public Result<List<MesPayment>> queryAll() { if (service.count() > QUERY_ALL_MAX) throw new JeecgBootException("付款单超过" + QUERY_ALL_MAX + "条"); return Result.ok(service.list()); }
    @GetMapping("/exportXls") @RequiresPermissions("mes:payment:export")
    public ModelAndView exportXls(MesPayment entity, HttpServletRequest req) { return super.exportXls(req, entity, MesPayment.class, "付款单"); }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 付款单接口-----------

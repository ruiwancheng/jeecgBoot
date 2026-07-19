//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 凭证接口-----------
package org.jeecg.modules.mes.finance.voucher.controller;

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
import org.jeecg.modules.mes.finance.voucher.entity.MesVoucher;
import org.jeecg.modules.mes.finance.voucher.service.IMesVoucherService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j @Tag(name = "MES-凭证管理") @RestController @RequestMapping("/mes/finance/voucher")
public class MesVoucherController extends JeecgController<MesVoucher, IMesVoucherService> {
    @Autowired private IMesVoucherService service;
    private static final int QUERY_ALL_MAX = 5000;

    @GetMapping("/list") @RequiresPermissions("mes:voucher:list")
    public Result<IPage<MesVoucher>> queryPageList(MesVoucher entity, @RequestParam(defaultValue = "1") Integer pageNo, @RequestParam(defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesVoucher> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap()); qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }
    @GetMapping("/queryById") @RequiresPermissions("mes:voucher:list")
    public Result<MesVoucher> queryById(@RequestParam String id) { MesVoucher e = service.queryWithItems(id); return e != null ? Result.ok(e) : Result.error("凭证不存在"); }
    @Operation(summary = "新增凭证") @PostMapping("/add") @RequiresPermissions("mes:voucher:add")
    public Result<String> add(@RequestBody MesVoucher entity) { service.saveWithItems(entity); return Result.ok("添加成功"); }
    @Operation(summary = "编辑凭证") @PutMapping("/edit") @RequiresPermissions("mes:voucher:edit")
    public Result<String> edit(@RequestBody MesVoucher entity) { service.updateWithItems(entity); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") @RequiresPermissions("mes:voucher:delete")
    public Result<String> delete(@RequestParam String id) { service.removeWithItems(id); return Result.ok("删除成功"); }
    @DeleteMapping("/deleteBatch") @RequiresPermissions("mes:voucher:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) { if (ids == null || ids.isEmpty()) return Result.ok("无需删除"); List<String> idList = Arrays.stream(ids.split(",")).filter(s -> !s.isEmpty()).collect(Collectors.toList()); if (idList.isEmpty()) return Result.ok("无需删除"); service.removeByIds(idList); return Result.ok("批量删除成功"); }
    @Operation(summary = "审核凭证") @PutMapping("/audit") @RequiresPermissions("mes:voucher:edit")
    public Result<String> audit(@RequestParam String id) { service.audit(id); return Result.ok("审核成功"); }
    @GetMapping("/queryAll") @RequiresPermissions("mes:voucher:list")
    public Result<List<MesVoucher>> queryAll() { if (service.count() > QUERY_ALL_MAX) throw new JeecgBootException("凭证超过" + QUERY_ALL_MAX + "条"); return Result.ok(service.list()); }
    @GetMapping("/exportXls") @RequiresPermissions("mes:voucher:export")
    public ModelAndView exportXls(MesVoucher entity, HttpServletRequest req) { return super.exportXls(req, entity, MesVoucher.class, "凭证"); }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 凭证接口-----------

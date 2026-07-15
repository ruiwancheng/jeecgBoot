//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库接口-----------
package org.jeecg.modules.mes.sales.controller;

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
import org.jeecg.modules.mes.sales.entity.MesSalesOutbound;
import org.jeecg.modules.mes.sales.service.IMesSalesOutboundService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j @Tag(name = "MES-销售出库") @RestController @RequestMapping("/mes/sales/outbound")
public class MesSalesOutboundController extends JeecgController<MesSalesOutbound, IMesSalesOutboundService> {
    @Autowired private IMesSalesOutboundService service;
    private static final int QUERY_ALL_MAX = 1000;

    @GetMapping("/list") @RequiresPermissions("mes:outbound:list")
    public Result<IPage<MesSalesOutbound>> list(MesSalesOutbound e, @RequestParam(defaultValue="1") Integer pageNo, @RequestParam(defaultValue="10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesSalesOutbound> qw = QueryGenerator.initQueryWrapper(e, req.getParameterMap()); qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @GetMapping("/queryById") @RequiresPermissions("mes:outbound:list")
    public Result<MesSalesOutbound> queryById(@RequestParam String id) { MesSalesOutbound o = service.queryWithItems(id); return o != null ? Result.ok(o) : Result.error("不存在"); }

    @PostMapping("/add") @RequiresPermissions("mes:outbound:add")
    public Result<String> add(@RequestBody MesSalesOutbound e) { service.saveWithItems(e); return Result.ok("添加成功"); }

    @PutMapping("/edit") @RequiresPermissions("mes:outbound:edit")
    public Result<String> edit(@RequestBody MesSalesOutbound e) { service.updateWithItems(e); return Result.ok("编辑成功"); }

    @DeleteMapping("/delete") @RequiresPermissions("mes:outbound:delete")
    public Result<String> delete(@RequestParam String id) { service.removeWithItems(id); return Result.ok("删除成功"); }

    @DeleteMapping("/deleteBatch") @RequiresPermissions("mes:outbound:deleteBatch")
    public Result<String> deleteBatch(@RequestParam String ids) { List<String> l = Arrays.stream(ids.split(",")).filter(s->!s.isEmpty()).collect(Collectors.toList()); if(l.isEmpty()) return Result.ok("无需删除"); service.removeByIds(l); return Result.ok("批量删除成功"); }

    @PutMapping("/audit") @RequiresPermissions("mes:outbound:edit")
    public Result<String> audit(@RequestParam String id) { service.audit(id); return Result.ok("审核成功"); }

    @PutMapping("/cancel") @RequiresPermissions("mes:outbound:edit")
    public Result<String> cancel(@RequestParam String id) { service.cancel(id); return Result.ok("已取消"); }

    @GetMapping("/queryAll") @RequiresPermissions("mes:outbound:list")
    public Result<List<MesSalesOutbound>> queryAll() { if(service.count()>QUERY_ALL_MAX) throw new JeecgBootException("超"+QUERY_ALL_MAX+"条"); return Result.ok(service.list()); }

    @GetMapping("/exportXls") @RequiresPermissions("mes:outbound:export")
    public ModelAndView exportXls(MesSalesOutbound e, HttpServletRequest req) { if(service.count(new QueryWrapper<>())>QUERY_ALL_MAX) throw new JeecgBootException("超"+QUERY_ALL_MAX+"条"); return super.exportXls(req, e, MesSalesOutbound.class, "销售出库"); }
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库接口-----------

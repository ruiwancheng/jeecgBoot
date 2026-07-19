//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 收款单接口-----------
package org.jeecg.modules.mes.finance.collection.controller;

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
import org.jeecg.modules.mes.finance.collection.entity.MesCollection;
import org.jeecg.modules.mes.finance.collection.service.IMesCollectionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j @Tag(name = "MES-收款管理") @RestController @RequestMapping("/mes/finance/collection")
public class MesCollectionController extends JeecgController<MesCollection, IMesCollectionService> {
    @Autowired private IMesCollectionService service;
    private static final int QUERY_ALL_MAX = 5000;

    @GetMapping("/list") @RequiresPermissions("mes:collection:list")
    public Result<IPage<MesCollection>> queryPageList(MesCollection entity, @RequestParam(defaultValue = "1") Integer pageNo, @RequestParam(defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesCollection> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap()); qw.orderByDesc("create_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }
    @GetMapping("/queryById") @RequiresPermissions("mes:collection:list")
    public Result<MesCollection> queryById(@RequestParam String id) { MesCollection e = service.getById(id); return e != null ? Result.ok(e) : Result.error("收款单不存在"); }
    @Operation(summary = "新增收款") @PostMapping("/add") @RequiresPermissions("mes:collection:add")
    public Result<String> add(@RequestBody MesCollection entity) { service.save(entity); return Result.ok("收款成功，应收已更新"); }
    @GetMapping("/queryAll") @RequiresPermissions("mes:collection:list")
    public Result<List<MesCollection>> queryAll() { if (service.count() > QUERY_ALL_MAX) throw new JeecgBootException("收款单超过" + QUERY_ALL_MAX + "条"); return Result.ok(service.list()); }
    @GetMapping("/exportXls") @RequiresPermissions("mes:collection:export")
    public ModelAndView exportXls(MesCollection entity, HttpServletRequest req) { return super.exportXls(req, entity, MesCollection.class, "收款单"); }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 收款单接口-----------

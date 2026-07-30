//update-begin---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次流水Controller-----------
package org.jeecg.modules.mes.batch.ledger.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.batch.ledger.entity.MesBatchLedger;
import org.jeecg.modules.mes.batch.ledger.service.IMesBatchLedgerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@Slf4j
@Tag(name = "MES-批次流水")
@RestController
@RequestMapping("/mes/batch/ledger")
public class MesBatchLedgerController extends JeecgController<MesBatchLedger, IMesBatchLedgerService> {
    @Autowired private IMesBatchLedgerService service;

    @GetMapping("/list")
    @RequiresPermissions("mes:batchLedger:list")
    public Result<IPage<MesBatchLedger>> queryPageList(MesBatchLedger entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<MesBatchLedger> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("occur_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }

    @GetMapping("/listByBatchId")
    @RequiresPermissions("mes:batchLedger:list")
    public Result<java.util.List<MesBatchLedger>> listByBatchId(@RequestParam String batchId) {
        return Result.ok(service.listByBatchId(batchId));
    }
}
//update-end---author:ruiwancheng---date:20260731---for: V8.0.0 MES批次管理-批次流水Controller-----------

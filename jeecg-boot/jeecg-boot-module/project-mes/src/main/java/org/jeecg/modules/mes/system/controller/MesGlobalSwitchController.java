//update-begin---author:ruiwancheng---date:20260731---for:【生产批次总开关】MES全局开关Controller（拆分查+写两个接口）-----------
package org.jeecg.modules.mes.system.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.system.entity.MesGlobalSwitch;
import org.jeecg.modules.mes.system.service.IMesGlobalSwitchService;
import org.jeecg.modules.mes.system.vo.CloseCheckResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@Tag(name = "MES-全局开关")
@RestController
@RequestMapping("/mes/system/globalSwitch")
public class MesGlobalSwitchController {

    @Autowired
    private IMesGlobalSwitchService service;

    @Operation(summary = "全局开关列表")
    @GetMapping("/list")
    @RequiresPermissions("mes:commonSetting:list")
    public Result<List<MesGlobalSwitch>> list(MesGlobalSwitch entity) {
        QueryWrapper<MesGlobalSwitch> qw = QueryGenerator.initQueryWrapper(entity, null);
        return Result.ok(service.list(qw));
    }

    @Operation(summary = "保存/更新全局开关")
    @PostMapping("/save")
    @RequiresPermissions("mes:commonSetting:edit")
    public Result<?> save(@RequestBody MesGlobalSwitch sw) {
        service.saveOrUpdate(sw);
        return Result.ok("保存成功");
    }

    @Operation(summary = "关闭开关前置检查（不执行关闭动作）")
    @GetMapping("/closeCheck")
    @RequiresPermissions("mes:commonSetting:edit")
    public Result<CloseCheckResult> closeCheck(@RequestParam String switchKey) {
        return Result.ok(service.checkCanClose(switchKey));
    }

    @Operation(summary = "关闭生产批次总开关（含原子操作：总开关置0 + 物料batch_enabled批量置0）")
    @PostMapping("/closeBatchSwitch")
    @RequiresPermissions("mes:commonSetting:edit")
    public Result<CloseCheckResult> closeBatchSwitch() {
        CloseCheckResult result = service.closeBatchSwitch();
        if (result.hasError()) {
            // 返回 200 + errors，前端弹窗展示清单
            return Result.ok(result);
        }
        return Result.ok(result);
    }
}
//update-end---author:ruiwancheng---date:20260731---for:【生产批次总开关】MES全局开关Controller（拆分查+写两个接口）-----------
//update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.0 物料成本价体系-成本日志Controller-----------
package org.jeecg.modules.mes.purchase.ledger.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.purchase.ledger.entity.MesCostLog;
import org.jeecg.modules.mes.purchase.ledger.service.IMesCostLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/mes/purchase/mesCostLog")
@Slf4j
public class MesCostLogController extends JeecgController<MesCostLog, IMesCostLogService> {

    @Autowired
    private IMesCostLogService mesCostLogService;

    @GetMapping("/list")
    @RequiresPermissions("mes:purchase:costLog:list")
    public Result<IPage<MesCostLog>> queryPageList(MesCostLog entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize,
            HttpServletRequest req) {
        QueryWrapper<MesCostLog> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        IPage<MesCostLog> page = mesCostLogService.page(new Page<>(pageNo, pageSize), qw);
        return Result.OK(page);
    }
}
//update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.0 物料成本价体系-成本日志Controller-----------

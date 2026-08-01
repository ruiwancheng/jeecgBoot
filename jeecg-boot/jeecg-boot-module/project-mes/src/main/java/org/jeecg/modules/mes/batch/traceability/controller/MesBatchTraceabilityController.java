//update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-Controller（切片1：列表查询）-----------
package org.jeecg.modules.mes.batch.traceability.controller;

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
import org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceability;
import org.jeecg.modules.mes.batch.traceability.service.IMesBatchTraceabilityService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 批次追溯 Controller。
 *
 * <p>切片 1（trace-1-list）只暴露列表分页 + 搜索：
 * <ul>
 *   <li>{@code GET /mes/batch/traceability/list} —— 分页 + 按批次号/业务类型搜索</li>
 * </ul>
 *
 * <p>数据源复用 {@code c_mes_batch_ledger}（{@link MesBatchTraceability} 实体
 * {@code @TableName} 指向 ledger 表）；权限码 {@code mes:batchTraceability:list}
 * 已在 {@code MesMenuRegistry} 注册。</p>
 *
 * <p>后续切片：trace-2-detail（按业务单据反查）、trace-3-export（导出）。</p>
 */
@Slf4j
@Tag(name = "MES-批次追溯")
@RestController
@RequestMapping("/mes/batch/traceability")
public class MesBatchTraceabilityController
        extends JeecgController<MesBatchTraceability, IMesBatchTraceabilityService> {

    @Autowired
    private IMesBatchTraceabilityService service;

    @GetMapping("/list")
    @RequiresPermissions("mes:batchTraceability:list")
    public Result<IPage<MesBatchTraceability>> queryPageList(
            MesBatchTraceability entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize,
            HttpServletRequest req) {
        QueryWrapper<MesBatchTraceability> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        qw.orderByDesc("occur_time");
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }
}
//update-end---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-Controller（切片1：列表查询）-----------
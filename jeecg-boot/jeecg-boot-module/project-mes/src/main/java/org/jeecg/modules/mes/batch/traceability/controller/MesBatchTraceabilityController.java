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
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceability;
import org.jeecg.modules.mes.batch.traceability.service.IMesBatchTraceabilityService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.ModelAndView;

/**
 * 批次追溯 Controller。
 *
 * <p>当前已实现的切片：
 * <ul>
 *   <li>{@code GET /mes/batch/traceability/list} —— 分页 + 按批次号/业务类型搜索（trace-1）</li>
 *   <li>{@code GET /mes/batch/traceability/exportXls} —— 导出全部追溯记录为 Excel（trace-3）</li>
 * </ul>
 *
 * <p>数据源复用 {@code c_mes_batch_ledger}（{@link MesBatchTraceability} 实体
 * {@code @TableName} 指向 ledger 表）；权限码 {@code mes:batchTraceability:list}
 * /{@code mes:batchTraceability:export} 已在 {@code MesMenuRegistry} 注册。</p>
 *
 * <p>导出模式严格对齐 {@code MesBatchLedgerController.exportXls}：超阈值（1000 条）
 * 抛错让前端走分页导出；否则调用父类 {@link JeecgController#exportXls}，
 * EasyPoi 按实体字段自动生成 xlsx。</p>
 */
@Slf4j
@Tag(name = "MES-批次追溯")
@RestController
@RequestMapping("/mes/batch/traceability")
public class MesBatchTraceabilityController
        extends JeecgController<MesBatchTraceability, IMesBatchTraceabilityService> {

    @Autowired
    private IMesBatchTraceabilityService service;

    //update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-导出端点（切片3：导出）-----------
    private static final int QUERY_ALL_MAX = 1000;
    //update-end---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-导出端点（切片3：导出）-----------

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

    //update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-导出端点（切片3：导出）-----------
    @GetMapping("/exportXls")
    @RequiresPermissions("mes:batchTraceability:export")
    public ModelAndView exportXls(MesBatchTraceability entity, HttpServletRequest req) {
        if (service.count(new QueryWrapper<>()) > QUERY_ALL_MAX) {
            throw new JeecgBootException("批次追溯记录超过" + QUERY_ALL_MAX + "条，请使用分页导出");
        }
        return super.exportXls(req, entity, MesBatchTraceability.class, "批次追溯");
    }
    //update-end---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-导出端点（切片3：导出）-----------
}
//update-end---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-Controller（切片1：列表查询）-----------
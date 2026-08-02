//update-begin---author:ruiwancheng---date:20260803---for: V10.0.3 MES批次追溯-Controller（列表改批次级 + exportXls 手写导出）-----------
package org.jeecg.modules.mes.batch.traceability.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.SecurityUtils;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.config.jeecgbase.JeecgBaseConfig;
import org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceability;
import org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceabilityVO;
import org.jeecg.modules.mes.batch.traceability.service.IMesBatchTraceabilityService;
import org.jeecgframework.poi.excel.def.NormalExcelConstants;
import org.jeecgframework.poi.excel.entity.ExportParams;
import org.jeecgframework.poi.excel.entity.enums.ExcelType;
import org.jeecgframework.poi.excel.view.JeecgEntityExcelView;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.ModelAndView;

import java.util.Collections;
import java.util.List;

/**
 * 批次追溯 Controller（V10.0.3 批次级列表改造）。
 *
 * <p>当前已实现的切片：
 * <ul>
 *   <li>{@code GET /mes/batch/traceability/list} —— 分页 + 按批次级聚合（list 改为批次级）</li>
 *   <li>{@code GET /mes/batch/traceability/exportXls} —— 手动导出批次级聚合 Excel（不能用 super.exportXls）</li>
 * </ul>
 *
 * <p>V10.0.3 改造：
 * <ul>
 *   <li>列表从 ledger 级 → batch 级（聚合自 c_mes_batch + c_mes_batch_ledger）</li>
 *   <li>{@code MesBatchTraceability} 旧实体仍保留（兼容未来 detail/export 端点）</li>
 *   <li>exportXls 改手写（super.exportXls 用的是 service.page()，无法跑自定义聚合 SQL）</li>
 * </ul>
 *
 * <p>权限码 {@code mes:batchTraceability:list} / {@code mes:batchTraceability:export}
 * 已在 {@code MesMenuRegistry} 注册。</p>
 */
@Slf4j
@Tag(name = "MES-批次追溯")
@RestController
@RequestMapping("/mes/batch/traceability")
public class MesBatchTraceabilityController
        extends JeecgController<MesBatchTraceability, IMesBatchTraceabilityService> {

    @Autowired
    private IMesBatchTraceabilityService service;

    @Autowired
    private JeecgBaseConfig jeecgBaseConfig;

    /**
     * 批次级聚合查询导出阈值（与项目其他模块一致）。
     */
    private static final int QUERY_ALL_MAX = 1000;

    /**
     * 批次级聚合列表（按 MesBatchTraceabilityVO 改造）。
     */
    @GetMapping("/list")
    @RequiresPermissions("mes:batchTraceability:list")
    public Result<IPage<MesBatchTraceabilityVO>> queryPageList(
            MesBatchTraceabilityVO entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize,
            HttpServletRequest req) {
        QueryWrapper<MesBatchTraceabilityVO> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        return Result.ok(service.queryBatchPage(new Page<>(pageNo, pageSize), qw));
    }

    /**
     * 批次级导出（手写：不能用 super.exportXls 因为 service.page() 走 MesBatchTraceability 实体表）。
     *
     * <p>查询全量（pageSize=QUERY_ALL_MAX）→ 用 EasyPoi + MesBatchTraceabilityVO 的 @Excel 注解导出。
     * 超过阈值抛错让前端走分页导出。</p>
     */
    @GetMapping("/exportXls")
    @RequiresPermissions("mes:batchTraceability:export")
    public ModelAndView exportXls(MesBatchTraceabilityVO entity, HttpServletRequest req) {
        // 阈值检查：调用专门的批次级计数方法
        long totalBatches = service.countBatchMasters();
        if (totalBatches > QUERY_ALL_MAX) {
            throw new JeecgBootException("批次追溯记录超过" + QUERY_ALL_MAX + "条，请使用分页导出");
        }
        // 查全量
        QueryWrapper<MesBatchTraceabilityVO> qw = QueryGenerator.initQueryWrapper(entity, req.getParameterMap());
        IPage<MesBatchTraceabilityVO> page = service.queryBatchPage(new Page<>(1, QUERY_ALL_MAX), qw);
        List<MesBatchTraceabilityVO> data = page.getRecords();
        // 导出参数
        LoginUser sysUser = (LoginUser) SecurityUtils.getSubject().getPrincipal();
        ExportParams exportParams = new ExportParams(
                "批次追溯报表",
                "导出人:" + (sysUser != null ? sysUser.getRealname() : ""),
                "批次追溯",
                jeecgBaseConfig.getPath().getUpload()
        );
        exportParams.setType(ExcelType.XSSF);
        // 用 JeecgEntityExcelView 渲染（参考 JeecgOrderMainController.exportXls 写法）
        ModelAndView mv = new ModelAndView(new JeecgEntityExcelView());
        mv.addObject(NormalExcelConstants.FILE_NAME, "批次追溯");
        mv.addObject(NormalExcelConstants.CLASS, MesBatchTraceabilityVO.class);
        mv.addObject(NormalExcelConstants.PARAMS, exportParams);
        mv.addObject(NormalExcelConstants.DATA_LIST, data == null ? Collections.emptyList() : data);
        return mv;
    }
}
//update-end---author:ruiwancheng---date:20260803---for: V10.0.3 MES批次追溯-Controller（列表改批次级 + exportXls 手写导出）-----------

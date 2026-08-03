package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import cn.hutool.core.util.StrUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.servlet.ModelAndView;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.modules.mes.basic.entity.MesCustomerFollowUp;
import org.jeecg.modules.mes.basic.service.IMesCustomerFollowUpService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Arrays;
import java.util.List;

@Slf4j
@Tag(name = "MES-客户跟进记录")
@RestController
@RequestMapping("/mes/basic/customer/followUp")
public class MesCustomerFollowUpController extends JeecgController<MesCustomerFollowUp, IMesCustomerFollowUpService> {
    @Autowired
    private IMesCustomerFollowUpService service;

    @GetMapping("/list")
    public Result<IPage<MesCustomerFollowUp>> queryPageList(MesCustomerFollowUp entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize) {
        LambdaQueryWrapper<MesCustomerFollowUp> qw = new LambdaQueryWrapper<>();
        qw.eq(StrUtil.isNotBlank(entity.getCustomerId()), MesCustomerFollowUp::getCustomerId, entity.getCustomerId());
        qw.orderByDesc(MesCustomerFollowUp::getFollowDate);
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }
    @PostMapping("/add") public Result<String> add(@RequestBody MesCustomerFollowUp e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") public Result<String> edit(@RequestBody MesCustomerFollowUp e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
    @DeleteMapping("/deleteBatch") public Result<String> deleteBatch(@RequestParam String ids) { service.removeByIds(Arrays.asList(ids.split(","))); return Result.ok("批量删除"); }

    @GetMapping("/exportXls")
    public ModelAndView exportXls(MesCustomerFollowUp entity, HttpServletRequest req) {
        return super.exportXls(req, entity, MesCustomerFollowUp.class, "客户跟进记录");
    }

    @PostMapping("/importExcel")
    public Result<?> importExcel(HttpServletRequest request) throws Exception {
        return super.importExcel(request, null, MesCustomerFollowUp.class);
    }
}

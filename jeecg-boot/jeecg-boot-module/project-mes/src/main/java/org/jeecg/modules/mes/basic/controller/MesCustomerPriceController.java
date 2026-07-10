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
import org.jeecg.modules.mes.basic.entity.MesCustomerPrice;
import org.jeecg.modules.mes.basic.service.IMesCustomerPriceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Arrays;
import java.util.List;

@Slf4j
@Tag(name = "MES-客户价格表")
@RestController
@RequestMapping("/mes/basic/customer/price")
public class MesCustomerPriceController extends JeecgController<MesCustomerPrice, IMesCustomerPriceService> {
    @Autowired
    private IMesCustomerPriceService service;

    @GetMapping("/list")
    public Result<IPage<MesCustomerPrice>> queryPageList(MesCustomerPrice entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize) {
        LambdaQueryWrapper<MesCustomerPrice> qw = new LambdaQueryWrapper<>();
        qw.eq(StrUtil.isNotBlank(entity.getCustomerId()), MesCustomerPrice::getCustomerId, entity.getCustomerId());
        qw.orderByAsc(MesCustomerPrice::getCustomerId);
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }
    @PostMapping("/add") public Result<String> add(@RequestBody MesCustomerPrice e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") public Result<String> edit(@RequestBody MesCustomerPrice e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
    @DeleteMapping("/deleteBatch") public Result<String> deleteBatch(@RequestParam String ids) { service.removeByIds(Arrays.asList(ids.split(","))); return Result.ok("批量删除"); }

    @GetMapping("/exportXls")
    public ModelAndView exportXls(MesCustomerPrice entity, HttpServletRequest req) {
        return super.exportXls(req, entity, MesCustomerPrice.class, "客户价格表");
    }

    @PostMapping("/importExcel")
    public Result<?> importExcel(HttpServletRequest request) throws Exception {
        return super.importExcel(request, null, MesCustomerPrice.class);
    }
}

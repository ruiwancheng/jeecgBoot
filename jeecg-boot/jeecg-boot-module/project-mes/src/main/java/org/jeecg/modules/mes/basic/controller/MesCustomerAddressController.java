//update-begin---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-地址管理接口-----------
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
import org.jeecg.modules.mes.basic.entity.MesCustomerAddress;
import org.jeecg.modules.mes.basic.service.IMesCustomerAddressService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Arrays;
import java.util.List;

@Slf4j
@Tag(name = "MES-客户地址")
@RestController
@RequestMapping("/mes/basic/customer/address")
public class MesCustomerAddressController extends JeecgController<MesCustomerAddress, IMesCustomerAddressService> {
    @Autowired
    private IMesCustomerAddressService service;

    @GetMapping("/list")
    public Result<IPage<MesCustomerAddress>> queryPageList(MesCustomerAddress entity,
            @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize) {
        LambdaQueryWrapper<MesCustomerAddress> qw = new LambdaQueryWrapper<>();
        qw.eq(StrUtil.isNotBlank(entity.getCustomerId()), MesCustomerAddress::getCustomerId, entity.getCustomerId());
        qw.orderByDesc(MesCustomerAddress::getIsDefault);
        return Result.ok(service.page(new Page<>(pageNo, pageSize), qw));
    }
    @PostMapping("/add") public Result<String> add(@RequestBody MesCustomerAddress e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") public Result<String> edit(@RequestBody MesCustomerAddress e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
    @DeleteMapping("/deleteBatch") public Result<String> deleteBatch(@RequestParam String ids) { service.removeByIds(Arrays.asList(ids.split(","))); return Result.ok("批量删除"); }

    @GetMapping("/exportXls")
    public ModelAndView exportXls(MesCustomerAddress entity, HttpServletRequest req) {
        return super.exportXls(req, entity, MesCustomerAddress.class, "客户地址");
    }

    @PostMapping("/importExcel")
    public Result<?> importExcel(HttpServletRequest request) throws Exception {
        return super.importExcel(request, null, MesCustomerAddress.class);
    }
}
//update-end---author:ruiwancheng---date:2026-07-10---for: MES客户模块升级-地址管理接口-----------

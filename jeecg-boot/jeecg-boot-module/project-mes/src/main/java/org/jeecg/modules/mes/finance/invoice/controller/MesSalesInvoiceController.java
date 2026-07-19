//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase3 销项发票接口-----------
package org.jeecg.modules.mes.finance.invoice.controller;
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
import org.jeecg.modules.mes.finance.invoice.entity.MesSalesInvoice;
import org.jeecg.modules.mes.finance.invoice.service.IMesSalesInvoiceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;
import java.util.*;
import java.util.stream.Collectors;
@Slf4j @Tag(name="MES-销项发票") @RestController @RequestMapping("/mes/finance/salesInvoice")
public class MesSalesInvoiceController extends JeecgController<MesSalesInvoice, IMesSalesInvoiceService> {
    @Autowired private IMesSalesInvoiceService service; private static final int QMAX=5000;
    @GetMapping("/list") @RequiresPermissions("mes:salesInvoice:list")
    public Result<IPage<MesSalesInvoice>> queryPageList(MesSalesInvoice e, @RequestParam(defaultValue="1") Integer pn, @RequestParam(defaultValue="10") Integer ps, HttpServletRequest req) {
        QueryWrapper<MesSalesInvoice> qw=QueryGenerator.initQueryWrapper(e,req.getParameterMap()); qw.orderByDesc("create_time"); return Result.ok(service.page(new Page<>(pn,ps),qw));
    }
    @GetMapping("/queryById") @RequiresPermissions("mes:salesInvoice:list") public Result<MesSalesInvoice> queryById(@RequestParam String id) { MesSalesInvoice e=service.getById(id); return e!=null?Result.ok(e):Result.error("不存在"); }
    @PostMapping("/add") @RequiresPermissions("mes:salesInvoice:add") public Result<String> add(@RequestBody MesSalesInvoice e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") @RequiresPermissions("mes:salesInvoice:edit") public Result<String> edit(@RequestBody MesSalesInvoice e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") @RequiresPermissions("mes:salesInvoice:delete") public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
    @GetMapping("/queryAll") @RequiresPermissions("mes:salesInvoice:list") public Result<List<MesSalesInvoice>> queryAll() { if(service.count()>QMAX) throw new JeecgBootException("超过"+QMAX+"条"); return Result.ok(service.list()); }
    @GetMapping("/exportXls") @RequiresPermissions("mes:salesInvoice:export") public ModelAndView exportXls(MesSalesInvoice e, HttpServletRequest req) { return super.exportXls(req,e,MesSalesInvoice.class,"销项发票"); }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase3 销项发票接口-----------

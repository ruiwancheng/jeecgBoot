//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase3 进项发票接口-----------
package org.jeecg.modules.mes.finance.purchaseInvoice.controller;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper; import com.baomidou.mybatisplus.core.metadata.IPage; import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.tags.Tag; import jakarta.servlet.http.HttpServletRequest; import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions; import org.jeecg.common.api.vo.Result; import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.base.controller.JeecgController; import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.mes.finance.purchaseInvoice.entity.MesPurchaseInvoice; import org.jeecg.modules.mes.finance.purchaseInvoice.service.IMesPurchaseInvoiceService;
import org.springframework.beans.factory.annotation.Autowired; import org.springframework.web.bind.annotation.*; import org.springframework.web.servlet.ModelAndView;
import java.util.*; import java.util.stream.Collectors;
@Slf4j @Tag(name="MES-进项发票") @RestController @RequestMapping("/mes/finance/purchaseInvoice")
public class MesPurchaseInvoiceController extends JeecgController<MesPurchaseInvoice, IMesPurchaseInvoiceService> {
    @Autowired private IMesPurchaseInvoiceService service; private static final int QMAX=5000;
    @GetMapping("/list") @RequiresPermissions("mes:purchaseInvoice:list") public Result<IPage<MesPurchaseInvoice>> queryPageList(MesPurchaseInvoice e, @RequestParam(defaultValue="1") Integer pn, @RequestParam(defaultValue="10") Integer ps, HttpServletRequest req) {
        QueryWrapper<MesPurchaseInvoice> qw=QueryGenerator.initQueryWrapper(e,req.getParameterMap()); qw.orderByDesc("create_time"); return Result.ok(service.page(new Page<>(pn,ps),qw)); }
    @GetMapping("/queryById") @RequiresPermissions("mes:purchaseInvoice:list") public Result<MesPurchaseInvoice> queryById(@RequestParam String id) { MesPurchaseInvoice e=service.getById(id); return e!=null?Result.ok(e):Result.error("不存在"); }
    @PostMapping("/add") @RequiresPermissions("mes:purchaseInvoice:add") public Result<String> add(@RequestBody MesPurchaseInvoice e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") @RequiresPermissions("mes:purchaseInvoice:edit") public Result<String> edit(@RequestBody MesPurchaseInvoice e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") @RequiresPermissions("mes:purchaseInvoice:delete") public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
    @GetMapping("/queryAll") @RequiresPermissions("mes:purchaseInvoice:list") public Result<List<MesPurchaseInvoice>> queryAll() { if(service.count()>QMAX) throw new JeecgBootException("超过"+QMAX+"条"); return Result.ok(service.list()); }
    @GetMapping("/exportXls") @RequiresPermissions("mes:purchaseInvoice:export") public ModelAndView exportXls(MesPurchaseInvoice e, HttpServletRequest req) { return super.exportXls(req,e,MesPurchaseInvoice.class,"进项发票"); }
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase3 进项发票接口-----------

//update-begin---author:admin---date:2026-07-05---for: demo客户-库位明细接口-----------
package org.jeecg.modules.customer.demo.controller;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.system.base.controller.JeecgController;
import org.jeecg.common.system.query.QueryGenerator;
import org.jeecg.modules.customer.demo.entity.DemoWarehouseLocation;
import org.jeecg.modules.customer.demo.service.IDemoWarehouseLocationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

@Slf4j
@Tag(name = "demo-库位明细管理")
@RestController
@RequestMapping("/customer/demo/warehouseLocation")
public class DemoWarehouseLocationController extends JeecgController<DemoWarehouseLocation, IDemoWarehouseLocationService> {
    @Autowired
    private IDemoWarehouseLocationService service;

    @GetMapping("/list")
    public Result<IPage<DemoWarehouseLocation>> queryPageList(DemoWarehouseLocation entity,
            @RequestParam(defaultValue = "1") Integer pageNo, @RequestParam(defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        return Result.ok(service.page(new Page<>(pageNo, pageSize), QueryGenerator.initQueryWrapper(entity, req.getParameterMap())));
    }
    @PostMapping("/add") public Result<String> add(@RequestBody DemoWarehouseLocation e) { service.save(e); return Result.ok("添加成功"); }
    @PutMapping("/edit") public Result<String> edit(@RequestBody DemoWarehouseLocation e) { service.updateById(e); return Result.ok("编辑成功"); }
    @DeleteMapping("/delete") public Result<String> delete(@RequestParam String id) { service.removeById(id); return Result.ok("删除成功"); }
    @DeleteMapping("/deleteBatch") public Result<String> deleteBatch(@RequestParam String ids) { service.removeByIds(Arrays.asList(ids.split(","))); return Result.ok("批量删除"); }

    @PostMapping("/generate")
    public Result<List<String>> generate(@RequestBody Map<String, Object> p) {
        return Result.ok(service.generateLocations((String)p.get("warehouseId"),
            Integer.parseInt(p.get("zones").toString()), Integer.parseInt(p.get("channelRows").toString()),
            Integer.parseInt(p.get("channelCols").toString()), Integer.parseInt(p.get("shelfRows").toString()),
            Integer.parseInt(p.get("shelfCols").toString())));
    }
}

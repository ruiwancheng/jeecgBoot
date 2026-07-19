//update-begin---author:ruiwancheng---date:2026-07-20---for: Phase3 库存预警接口-----------
package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.modules.mes.basic.entity.MesInventory;
import org.jeecg.modules.mes.basic.entity.MesMaterial;
import org.jeecg.modules.mes.basic.mapper.MesInventoryMapper;
import org.jeecg.modules.mes.basic.mapper.MesMaterialMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.*;

@Slf4j @Tag(name = "MES-库存预警") @RestController @RequestMapping("/mes/basic/inventoryAlert")
public class MesInventoryAlertController {
    @Autowired private MesInventoryMapper inventoryMapper;
    @Autowired private MesMaterialMapper materialMapper;

    @GetMapping("/list") @RequiresPermissions("mes:inventoryAlert:list")
    public Result<List<Map<String, Object>>> queryAlerts() {
        // 加载所有设了安全库存的物料
        LambdaQueryWrapper<MesMaterial> mqw = new LambdaQueryWrapper<>();
        mqw.isNotNull(MesMaterial::getSafetyStock).gt(MesMaterial::getSafetyStock, 0).eq(MesMaterial::getStatus, 1);
        List<MesMaterial> materials = materialMapper.selectList(mqw);
        // 加载所有库存快照
        List<MesInventory> invs = inventoryMapper.selectList(null);
        Map<String, BigDecimal> stockMap = new HashMap<>();
        for (MesInventory inv : invs) {
            stockMap.merge(inv.getMaterialId(), inv.getCurrentQty() != null ? inv.getCurrentQty() : BigDecimal.ZERO, BigDecimal::add);
        }
        // 筛选低于安全库存的
        List<Map<String, Object>> alerts = new ArrayList<>();
        for (MesMaterial m : materials) {
            BigDecimal current = stockMap.getOrDefault(m.getId(), BigDecimal.ZERO);
            if (current.compareTo(m.getSafetyStock()) < 0) {
                Map<String, Object> alert = new LinkedHashMap<>();
                alert.put("materialId", m.getId()); alert.put("materialCode", m.getCode()); alert.put("materialName", m.getName());
                alert.put("currentQty", current); alert.put("safetyStock", m.getSafetyStock()); alert.put("maxStock", m.getMaxStock());
                alert.put("shortage", m.getSafetyStock().subtract(current));
                alerts.add(alert);
            }
        }
        alerts.sort((a,b) -> ((BigDecimal)b.get("shortage")).compareTo((BigDecimal)a.get("shortage")));
        return Result.ok(alerts);
    }
}
//update-end---author:ruiwancheng---date:2026-07-20---for: Phase3 库存预警接口-----------

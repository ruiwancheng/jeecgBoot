//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 19 c_mes_stocktake_item（JOIN status!=2）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.stock.entity.MesStocktakeItem;
import org.jeecg.modules.mes.stock.mapper.MesStocktakeItemMapper;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class StocktakeItemReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesStocktakeItemMapper mapper;

    @Override public String describe() { return "c_mes_stocktake_item"; }

    @Override
    public void assertNotReferenced(String materialId) {
        QueryWrapper<MesStocktakeItem> qw = new QueryWrapper<>();
        qw.eq("material_id", materialId)
          .apply("take_id IN (SELECT id FROM c_mes_stocktake WHERE status <> '2')");
        Long cnt = mapper.selectCount(qw);
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料被 " + cnt + " 行未完结的盘点单引用，请先清理");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 19-----------

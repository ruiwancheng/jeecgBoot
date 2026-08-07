//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 18 c_mes_sales_outbound_item（JOIN status!=3）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.sales.entity.MesSalesOutboundItem;
import org.jeecg.modules.mes.sales.mapper.MesSalesOutboundItemMapper;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class SalesOutboundItemReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesSalesOutboundItemMapper mapper;

    @Override public String describe() { return "c_mes_sales_outbound_item"; }

    @Override
    public void assertNotReferenced(String materialId) {
        QueryWrapper<MesSalesOutboundItem> qw = new QueryWrapper<>();
        qw.eq("material_id", materialId)
          .apply("outbound_id IN (SELECT id FROM c_mes_sales_outbound WHERE status <> '3')");
        Long cnt = mapper.selectCount(qw);
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料被 " + cnt + " 行未发货完结的销售出库单引用，请先清理");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 18-----------

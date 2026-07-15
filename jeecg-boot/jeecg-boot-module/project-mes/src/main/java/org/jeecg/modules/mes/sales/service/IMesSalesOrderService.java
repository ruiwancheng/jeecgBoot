//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售订单Service接口-----------
package org.jeecg.modules.mes.sales.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.sales.entity.MesSalesOrder;

public interface IMesSalesOrderService extends IService<MesSalesOrder> {
    MesSalesOrder queryWithItems(String id);
    void saveWithItems(MesSalesOrder entity);
    void updateWithItems(MesSalesOrder entity);
    void removeWithItems(String id);
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售订单Service接口-----------

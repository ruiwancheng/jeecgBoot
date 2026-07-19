//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购订单Service接口-----------
package org.jeecg.modules.mes.purchase.order.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrder;

public interface IMesPurchaseOrderService extends IService<MesPurchaseOrder> {
    MesPurchaseOrder queryWithItems(String id);
    void saveWithItems(MesPurchaseOrder entity);
    void updateWithItems(MesPurchaseOrder entity);
    void removeWithItems(String id);
    void audit(String id);
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购订单Service接口-----------

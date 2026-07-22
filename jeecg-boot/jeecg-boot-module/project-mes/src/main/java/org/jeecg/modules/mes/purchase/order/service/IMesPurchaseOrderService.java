//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购订单Service接口-----------
package org.jeecg.modules.mes.purchase.order.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.purchase.order.entity.MesPurchaseApplyItemForOrder;
import org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrder;

import java.util.List;

public interface IMesPurchaseOrderService extends IService<MesPurchaseOrder> {
    MesPurchaseOrder queryWithItems(String id);
    void saveWithItems(MesPurchaseOrder entity);
    void updateWithItems(MesPurchaseOrder entity);
    void removeWithItems(String id);
    void audit(String id);
    //update-begin---author:ruisuyun---date:2026-07-22---for: 链路P1-订单反审核-----------
    void unaudit(String id);
    //update-end---author:ruisuyun---date:2026-07-22---for: 链路P1-订单反审核-----------
    //update-begin---author:ruisuyun---date:2026-07-22---for: 链路P0-从已审核申请加载明细-----------
    List<MesPurchaseApplyItemForOrder> loadApplyItemsForOrder(String applyId);
    //update-end---author:ruisuyun---date:2026-07-22---for: 链路P0-从已审核申请加载明细-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购订单Service接口-----------

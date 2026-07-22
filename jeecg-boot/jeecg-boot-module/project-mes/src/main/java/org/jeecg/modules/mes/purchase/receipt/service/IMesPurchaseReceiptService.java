//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库Service接口-----------
package org.jeecg.modules.mes.purchase.receipt.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.purchase.receipt.entity.MesPurchaseReceipt;

public interface IMesPurchaseReceiptService extends IService<MesPurchaseReceipt> {
    MesPurchaseReceipt queryWithItems(String id);
    void saveWithItems(MesPurchaseReceipt entity);
    void updateWithItems(MesPurchaseReceipt entity);
    void removeWithItems(String id);
    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 入库审核-采购收货-----------
    void audit(String id);
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 入库审核-采购收货-----------

    //update-begin---author:ruisuyun---date:2026-07-22---for: 采购入库单-选择采购单后从明细中选入库明细-----------
    java.util.List<org.jeecg.modules.mes.purchase.order.entity.MesPurchaseOrderItemForReceipt> loadOrderItemsForReceipt(String orderId);
    //update-end---author:ruisuyun---date:2026-07-22---for: 采购入库单-选择采购单后从明细中选入库明细-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库Service接口-----------

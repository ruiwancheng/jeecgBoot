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
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购入库Service接口-----------

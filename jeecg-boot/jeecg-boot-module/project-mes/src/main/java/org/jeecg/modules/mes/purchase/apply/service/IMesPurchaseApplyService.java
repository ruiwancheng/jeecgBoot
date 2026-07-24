//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请Service接口-----------
package org.jeecg.modules.mes.purchase.apply.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.purchase.apply.entity.MesPurchaseApply;

public interface IMesPurchaseApplyService extends IService<MesPurchaseApply> {
    MesPurchaseApply queryWithItems(String id);
    void saveWithItems(MesPurchaseApply entity);
    void updateWithItems(MesPurchaseApply entity);
    void removeWithItems(String id);
    //update-begin---author:ruiwancheng---date:2026-07-24---for: V9.7.1 采购链路-审核+驳回+反审核-----------
    void audit(String id);
    void reject(String id);
    void unaudit(String id);
    //update-end---author:ruiwancheng---date:2026-07-24---for: V9.7.1 采购链路-审核+驳回+反审核-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请Service接口-----------

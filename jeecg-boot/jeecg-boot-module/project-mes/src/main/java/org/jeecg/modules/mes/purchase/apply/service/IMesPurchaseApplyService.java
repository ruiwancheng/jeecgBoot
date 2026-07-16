//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请Service接口-----------
package org.jeecg.modules.mes.purchase.apply.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.purchase.apply.entity.MesPurchaseApply;

public interface IMesPurchaseApplyService extends IService<MesPurchaseApply> {
    MesPurchaseApply queryWithItems(String id);
    void saveWithItems(MesPurchaseApply entity);
    void updateWithItems(MesPurchaseApply entity);
    void removeWithItems(String id);
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请Service接口-----------

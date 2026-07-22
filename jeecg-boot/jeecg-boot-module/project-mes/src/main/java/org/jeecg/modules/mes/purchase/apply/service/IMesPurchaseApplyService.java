//update-begin---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请Service接口-----------
package org.jeecg.modules.mes.purchase.apply.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.purchase.apply.entity.MesPurchaseApply;

public interface IMesPurchaseApplyService extends IService<MesPurchaseApply> {
    MesPurchaseApply queryWithItems(String id);
    void saveWithItems(MesPurchaseApply entity);
    void updateWithItems(MesPurchaseApply entity);
    void removeWithItems(String id);
    //update-begin---author:ruisuyun---date:2026-07-22---for: 链路P0-申请审核端点-----------
    void audit(String id);
    //update-end---author:ruisuyun---date:2026-07-22---for: 链路P0-申请审核端点-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES采购管理-采购申请Service接口-----------

//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-完工入库Service接口-----------
package org.jeecg.modules.mes.manufacturing.completion.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.manufacturing.completion.entity.MesCompletionReceipt;

public interface ICompletionReceiptService extends IService<MesCompletionReceipt> {

    MesCompletionReceipt queryWithItems(String id);

    void saveWithItems(MesCompletionReceipt entity);

    void updateWithItems(MesCompletionReceipt entity);

    void removeWithItems(String id);

    boolean removeByIds(java.util.Collection<?> list);
    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 完工入库审核-----------
    void audit(String id);
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 完工入库审核-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-完工入库Service接口-----------

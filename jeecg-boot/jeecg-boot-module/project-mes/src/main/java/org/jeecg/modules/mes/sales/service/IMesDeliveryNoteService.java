//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单Service接口-----------
package org.jeecg.modules.mes.sales.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.sales.entity.MesDeliveryNote;

public interface IMesDeliveryNoteService extends IService<MesDeliveryNote> {
    MesDeliveryNote queryWithItems(String id);
    void saveWithItems(MesDeliveryNote entity);
    void updateWithItems(MesDeliveryNote entity);
    void removeWithItems(String id);
    //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-发货单-----------
    void submit(String id);
    void sign(String id);
    void cancel(String id);
    //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转API-发货单-----------
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单Service接口-----------

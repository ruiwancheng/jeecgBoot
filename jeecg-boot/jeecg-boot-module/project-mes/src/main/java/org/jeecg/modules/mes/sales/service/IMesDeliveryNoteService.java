//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单Service接口-----------
package org.jeecg.modules.mes.sales.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.sales.entity.MesDeliveryNote;

public interface IMesDeliveryNoteService extends IService<MesDeliveryNote> {
    MesDeliveryNote queryWithItems(String id);
    void saveWithItems(MesDeliveryNote entity);
    void updateWithItems(MesDeliveryNote entity);
    void removeWithItems(String id);
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-发货单Service接口-----------

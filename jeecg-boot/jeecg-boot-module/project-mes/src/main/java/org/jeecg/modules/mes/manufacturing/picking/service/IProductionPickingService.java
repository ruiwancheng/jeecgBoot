//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产领料Service接口-----------
package org.jeecg.modules.mes.manufacturing.picking.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.manufacturing.picking.entity.MesProductionPicking;

public interface IProductionPickingService extends IService<MesProductionPicking> {

    MesProductionPicking queryWithItems(String id);

    void saveWithItems(MesProductionPicking entity);

    void updateWithItems(MesProductionPicking entity);

    void removeWithItems(String id);

    boolean removeByIds(java.util.Collection<?> list);
    //update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 领料审核-----------
    void audit(String id);
    //update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step2 领料审核-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产领料Service接口-----------

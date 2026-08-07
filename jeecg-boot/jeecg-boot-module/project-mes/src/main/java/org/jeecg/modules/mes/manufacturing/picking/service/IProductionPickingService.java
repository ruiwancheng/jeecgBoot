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

    //update-begin---author:ruiwancheng---date:2026-08-08---for: slice-4 领料 generateByOrder：基于订单+BOM+已领累计生成补领草稿领料单-----------
    /**
     * 补领：按订单查 BOM 子件，结合 BOM 用量×planQty - 已领累计，仅生成"需补领"行
     * 同订单可多次补领（分批），已领完抛错
     * @param orderId 生产订单ID
     * @return 新领料单ID
     */
    String generateByOrder(String orderId);
    //update-end---author:ruiwancheng---date:2026-08-08---for: slice-4 领料 generateByOrder 补领-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产领料Service接口-----------

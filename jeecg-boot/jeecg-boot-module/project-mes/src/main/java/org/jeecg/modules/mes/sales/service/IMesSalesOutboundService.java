//update-begin---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Service接口-----------
package org.jeecg.modules.mes.sales.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.sales.entity.MesSalesOutbound;

public interface IMesSalesOutboundService extends IService<MesSalesOutbound> {
    MesSalesOutbound queryWithItems(String id);
    void saveWithItems(MesSalesOutbound entity);
    void updateWithItems(MesSalesOutbound entity);
    void removeWithItems(String id);
    void audit(String id);
    void cancel(String id);
}
//update-end---author:ruiwancheng---date:2026-07-15---for: MES销售管理-销售出库Service接口-----------

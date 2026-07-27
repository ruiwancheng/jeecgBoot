//update-begin---author:ruiwancheng---date:2026-07-28---for: V9.8.0 MES其它出入库-其它出库Service接口-----------
package org.jeecg.modules.mes.stock.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.stock.entity.MesOtherStockOut;

public interface IMesOtherStockOutService extends IService<MesOtherStockOut> {
    MesOtherStockOut queryWithItems(String id);
    void saveWithItems(MesOtherStockOut entity);
    void updateWithItems(MesOtherStockOut entity);
    void removeWithItems(String id);
    void audit(String id);
    void unaudit(String id);
}
//update-end---author:ruiwancheng---date:2026-07-28---for: V9.8.0 MES其它出入库-其它出库Service接口-----------

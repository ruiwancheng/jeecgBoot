//update-begin---author:ruiwancheng---date:2026-07-28---for: V9.8.0 MES其它出入库-其它入库Service接口-----------
package org.jeecg.modules.mes.stock.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.stock.entity.MesOtherStockIn;

public interface IMesOtherStockInService extends IService<MesOtherStockIn> {
    MesOtherStockIn queryWithItems(String id);
    void saveWithItems(MesOtherStockIn entity);
    void updateWithItems(MesOtherStockIn entity);
    void removeWithItems(String id);
    void audit(String id);
    void unaudit(String id);
}
//update-end---author:ruiwancheng---date:2026-07-28---for: V9.8.0 MES其它出入库-其它入库Service接口-----------

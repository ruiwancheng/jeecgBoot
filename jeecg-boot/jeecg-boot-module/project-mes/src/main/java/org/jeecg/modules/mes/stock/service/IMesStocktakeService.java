//update-begin---author:ruiwancheng---date:2026-07-28---for: V9.9.0 MES盘点单-Service接口-----------
package org.jeecg.modules.mes.stock.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.stock.entity.MesStocktake;

public interface IMesStocktakeService extends IService<MesStocktake> {
    MesStocktake queryWithItems(String id);
    void saveWithItems(MesStocktake entity);
    void updateWithItems(MesStocktake entity);
    void removeWithItems(String id);
    /** 审核：差异行自动生成盘盈入库/盘亏出库单并审核（同事务），返回摘要 */
    String audit(String id);
}
//update-end---author:ruiwancheng---date:2026-07-28---for: V9.9.0 MES盘点单-Service接口-----------

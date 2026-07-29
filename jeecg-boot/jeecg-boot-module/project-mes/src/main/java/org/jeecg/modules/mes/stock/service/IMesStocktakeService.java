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
    //update-begin---author:ruiwancheng---date:2026-07-29---for: 黄金模板重构 草稿态刷新账面快照-----------
    /** 草稿态重新快照账面数（快照过期一键刷新；仅草稿） */
    void refreshItems(String id);
    //update-begin---author:ruiwancheng---date:2026-07-29---for: 铁拳团V2 P0-3 批量审核单事务-----------
    /** 批量审核（单事务，任一失败全部回滚） */
    String batchAudit(java.util.List<String> ids);
    //update-end---author:ruiwancheng---date:2026-07-29---for: 铁拳团V2 P0-3-----------
    //update-end---author:ruiwancheng---date:2026-07-29---for: refreshItems-----------
}
//update-end---author:ruiwancheng---date:2026-07-28---for: V9.9.0 MES盘点单-Service接口-----------

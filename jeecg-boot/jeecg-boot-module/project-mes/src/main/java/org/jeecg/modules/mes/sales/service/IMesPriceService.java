//update-begin---author:ruiwancheng---date:2026-07-14---for: MES销售管理-价格Service接口-----------
package org.jeecg.modules.mes.sales.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.sales.entity.MesPrice;

import java.util.List;

public interface IMesPriceService extends IService<MesPrice> {
    void importFromExcel(List<MesPrice> list);
}
//update-end---author:ruiwancheng---date:2026-07-14---for: MES销售管理-价格Service接口-----------

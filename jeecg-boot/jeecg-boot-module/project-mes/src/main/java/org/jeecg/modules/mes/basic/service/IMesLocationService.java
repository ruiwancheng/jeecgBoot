//update-begin---author:admin---date:2026-07-06---for: MES基础设置-库位Service接口-----------
package org.jeecg.modules.mes.basic.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.basic.entity.MesLocation;
import java.util.List;

public interface IMesLocationService extends IService<MesLocation> {
    List<String> generateLocations(String warehouseId, int count);
}
//update-end---author:admin---date:2026-07-06---for: MES基础设置-库位Service接口-----------

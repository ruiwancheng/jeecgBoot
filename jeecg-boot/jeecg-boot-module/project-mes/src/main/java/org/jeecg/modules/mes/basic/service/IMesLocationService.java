//update-begin---author:admin---date:2026-07-06---for: MES基础设置-库位Service接口-----------
package org.jeecg.modules.mes.basic.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.basic.entity.MesLocation;
import java.util.List;

public interface IMesLocationService extends IService<MesLocation> {
    /**
     * 批量生成库位编码
     * @param shelfId 货架ID
     * @param rows 行数
     * @param cols 列数
     * @return 生成的库位编码列表
     */
    List<String> generateLocations(String shelfId, int rows, int cols);
}
//update-end---author:admin---date:2026-07-06---for: MES基础设置-库位Service接口-----------

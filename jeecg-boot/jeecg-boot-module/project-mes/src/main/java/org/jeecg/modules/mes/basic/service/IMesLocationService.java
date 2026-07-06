//update-begin---author:admin---date:2026-07-06---for: MES基础设置-库位Service接口-----------
package org.jeecg.modules.mes.basic.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.basic.entity.MesLocation;
import java.util.List;

public interface IMesLocationService extends IService<MesLocation> {
    /**
     * 批量生成库位编码
     * @param warehouseId 仓库ID
     * @param area 区域标识
     * @param channelRows 通道行数
     * @param channelCols 通道列数
     * @param shelfRows 货架行数
     * @param shelfCols 货架列数
     * @return 生成的库位编码列表
     */
    List<String> generateLocations(String warehouseId, String area, int channelRows, int channelCols, int shelfRows, int shelfCols);
}
//update-end---author:admin---date:2026-07-06---for: MES基础设置-库位Service接口-----------

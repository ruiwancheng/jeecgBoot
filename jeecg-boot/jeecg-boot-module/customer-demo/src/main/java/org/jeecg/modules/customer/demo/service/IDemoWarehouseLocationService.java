package org.jeecg.modules.customer.demo.service;
import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.customer.demo.entity.DemoWarehouseLocation;
import java.util.List;
public interface IDemoWarehouseLocationService extends IService<DemoWarehouseLocation> {
    List<String> generateLocations(String warehouseId, int zones, int channelRows, int channelCols, int shelfRows, int shelfCols);
}

package org.jeecg.modules.customer.demo.service.impl;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.modules.customer.demo.entity.DemoWarehouse;
import org.jeecg.modules.customer.demo.entity.DemoWarehouseLocation;
import org.jeecg.modules.customer.demo.mapper.DemoWarehouseLocationMapper;
import org.jeecg.modules.customer.demo.mapper.DemoWarehouseMapper;
import org.jeecg.modules.customer.demo.service.IDemoWarehouseLocationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.ArrayList;
import java.util.List;

@Service
public class DemoWarehouseLocationServiceImpl extends ServiceImpl<DemoWarehouseLocationMapper, DemoWarehouseLocation> implements IDemoWarehouseLocationService {
    @Autowired
    private DemoWarehouseMapper warehouseMapper;

    @Override
    public List<String> generateLocations(String warehouseId, int zones, int channelRows, int channelCols, int shelfRows, int shelfCols) {
        DemoWarehouse wh = warehouseMapper.selectById(warehouseId);
        String whCode = wh != null ? wh.getCode() : "WH";
        List<String> codes = new ArrayList<>();
        for (int z = 0; z < zones; z++) {
            String zone = String.valueOf((char) ('A' + z));
            for (int cr = 0; cr < channelRows; cr++) {
                for (int cc = 0; cc < channelCols; cc++) {
                    for (int sr = 0; sr < shelfRows; sr++) {
                        for (int sc = 0; sc < shelfCols; sc++) {
                            String code = String.format("%s-%s-%02d%02d-%02d%02d", whCode, zone, cr + 1, cc + 1, sr + 1, sc + 1);
                            DemoWarehouseLocation loc = new DemoWarehouseLocation();
                            loc.setWarehouseId(warehouseId);
                            loc.setCode(code);
                            loc.setStatus(1);
                            baseMapper.insert(loc);
                            codes.add(code);
                        }
                    }
                }
            }
        }
        return codes;
    }
}

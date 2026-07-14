//update-begin---author:admin---date:2026-07-06---for: MES基础设置-库位Service实现-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesWarehouse;
import org.jeecg.modules.mes.basic.entity.MesLocation;
import org.jeecg.modules.mes.basic.mapper.MesLocationMapper;
import org.jeecg.modules.mes.basic.mapper.MesWarehouseMapper;
import org.jeecg.modules.mes.basic.service.IMesLocationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.ArrayList;
import java.util.List;

@Service
public class MesLocationServiceImpl extends ServiceImpl<MesLocationMapper, MesLocation> implements IMesLocationService {
    @Autowired
    private MesWarehouseMapper warehouseMapper;

    private static final int GENERATE_MAX = 1000;

    @Override
    @Transactional
    public boolean save(MesLocation entity) {
        QueryWrapper<MesLocation> activeQw = new QueryWrapper<>();
        activeQw.eq("warehouse_id", entity.getWarehouseId()).eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) {
            throw new JeecgBootException("该仓库下已存在相同编码的库位");
        }
        MesLocation old = baseMapper.selectDeletedByWhAndCode(entity.getWarehouseId(), entity.getCode());
        if (old != null) {
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            baseMapper.resurrect(entity);
            return true;
        }
        return super.save(entity);
    }

    @Override
    public boolean updateById(MesLocation entity) {
        QueryWrapper<MesLocation> qw = new QueryWrapper<>();
        qw.eq("warehouse_id", entity.getWarehouseId()).eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) {
            throw new JeecgBootException("该仓库下已存在相同编码的库位");
        }
        return super.updateById(entity);
    }

    @Override
    @Transactional
    public List<String> generateLocations(String warehouseId, String area, int channelRows, int channelCols, int shelfRows, int shelfCols) {
        long total = (long) channelRows * channelCols * shelfRows * shelfCols;
        if (total <= 0 || total > GENERATE_MAX) {
            throw new JeecgBootException("生成总数必须在1到" + GENERATE_MAX + "之间，当前：" + total);
        }
        MesWarehouse wh = warehouseMapper.selectById(warehouseId);
        if (wh == null) throw new JeecgBootException("仓库不存在");

        List<MesLocation> batch = new ArrayList<>();
        for (int cr = 0; cr < channelRows; cr++) {
            for (int cc = 0; cc < channelCols; cc++) {
                for (int sr = 0; sr < shelfRows; sr++) {
                    for (int sc = 0; sc < shelfCols; sc++) {
                        String code = String.format("%s-%02d-%02d-%02d-%02d", area, cr + 1, cc + 1, sr + 1, sc + 1);
                        QueryWrapper<MesLocation> qw = new QueryWrapper<>();
                        qw.eq("warehouse_id", warehouseId).eq("code", code);
                        if (baseMapper.selectCount(qw) > 0) {
                            throw new JeecgBootException("库位编码 " + code + " 已存在");
                        }
                        MesLocation loc = new MesLocation();
                        loc.setWarehouseId(warehouseId);
                        loc.setCode(code);
                        loc.setName(code);
                        loc.setArea(area);
                        loc.setPassageRow(cr + 1);
                        loc.setPassageCol(cc + 1);
                        loc.setShelfRow(sr + 1);
                        loc.setShelfCol(sc + 1);
                        loc.setStatus(1);
                        batch.add(loc);
                    }
                }
            }
        }
        saveBatch(batch);
        List<String> codes = new ArrayList<>();
        for (MesLocation loc : batch) codes.add(loc.getCode());
        return codes;
    }

    @Override
    @Transactional
    public boolean removeByIds(java.util.Collection<?> list) {
        for (Object id : list) this.removeById((java.io.Serializable) id);
        return true;
    }
}
//update-end---author:admin---date:2026-07-06---for: MES基础设置-库位Service实现-----------

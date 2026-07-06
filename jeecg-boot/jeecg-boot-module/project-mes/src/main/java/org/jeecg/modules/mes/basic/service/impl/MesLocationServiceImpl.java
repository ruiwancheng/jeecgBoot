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

    @Override
    @Transactional
    public boolean save(MesLocation entity) {
        // 1. 查活跃记录（同仓库+同编码）→ 有则报错
        QueryWrapper<MesLocation> activeQw = new QueryWrapper<>();
        activeQw.eq("warehouse_id", entity.getWarehouseId()).eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) {
            throw new JeecgBootException("该仓库下已存在相同编码的库位");
        }
        // 2. 查软删除记录（绕开 @TableLogic）→ 有则复活
        MesLocation old = baseMapper.selectDeletedByWhAndCode(entity.getWarehouseId(), entity.getCode());
        if (old != null) {
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            // 绕开 @TableLogic：直接用原始 UPDATE
            baseMapper.resurrect(entity);
            return true;
        }
        // 3. 不存在 → 正常新增
        return super.save(entity);
    }

    @Override
    public boolean updateById(MesLocation entity) {
        // 编辑时排除自身
        QueryWrapper<MesLocation> qw = new QueryWrapper<>();
        qw.eq("warehouse_id", entity.getWarehouseId()).eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) {
            throw new JeecgBootException("该仓库下已存在相同编码的库位");
        }
        return super.updateById(entity);
    }

    @Override
    public List<String> generateLocations(String warehouseId, String area, int channelRows, int channelCols, int shelfRows, int shelfCols) {
        MesWarehouse wh = warehouseMapper.selectById(warehouseId);
        List<String> codes = new ArrayList<>();
        for (int cr = 0; cr < channelRows; cr++) {
            for (int cc = 0; cc < channelCols; cc++) {
                for (int sr = 0; sr < shelfRows; sr++) {
                    for (int sc = 0; sc < shelfCols; sc++) {
                        String code = String.format("%s-%02d-%02d-%02d-%02d", area, cr + 1, cc + 1, sr + 1, sc + 1);
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
                        loc.setFactory(wh != null ? wh.getFactory() : null);
                        loc.setWorkshop(wh != null ? wh.getWorkshop() : null);
                        baseMapper.insert(loc);
                        codes.add(code);
                    }
                }
            }
        }
        return codes;
    }
}
//update-end---author:admin---date:2026-07-06---for: MES基础设置-库位Service实现-----------

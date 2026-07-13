//update-begin---author:admin---date:2026-07-06---for: MES基础设置-库位Service实现-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesShelf;
import org.jeecg.modules.mes.basic.entity.MesLocation;
import org.jeecg.modules.mes.basic.mapper.MesLocationMapper;
import org.jeecg.modules.mes.basic.mapper.MesShelfMapper;
import org.jeecg.modules.mes.basic.service.IMesLocationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.ArrayList;
import java.util.List;

@Service
public class MesLocationServiceImpl extends ServiceImpl<MesLocationMapper, MesLocation> implements IMesLocationService {
    @Autowired
    private MesShelfMapper shelfMapper;

    @Override
    @Transactional
    public boolean save(MesLocation entity) {
        //update-begin---author:admin---date:2026-07-13---for: 唯一性校验改为(shelfId,code)维度-----------
        QueryWrapper<MesLocation> activeQw = new QueryWrapper<>();
        if (entity.getShelfId() != null) {
            activeQw.eq("shelf_id", entity.getShelfId());
        } else {
            activeQw.eq("warehouse_id", entity.getWarehouseId());
        }
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) {
            throw new JeecgBootException("该货架下已存在相同编码的库位");
        }
        MesLocation old = baseMapper.selectDeletedByWhAndCode(entity.getWarehouseId(), entity.getCode());
        if (old != null) {
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            baseMapper.resurrect(entity);
            return true;
        }
        //update-end---author:admin---date:2026-07-13---for: 唯一性校验改为(shelfId,code)维度-----------
        return super.save(entity);
    }

    @Override
    public boolean updateById(MesLocation entity) {
        //update-begin---author:admin---date:2026-07-13---for: 编辑时唯一性校验-----------
        QueryWrapper<MesLocation> qw = new QueryWrapper<>();
        if (entity.getShelfId() != null) {
            qw.eq("shelf_id", entity.getShelfId());
        } else {
            qw.eq("warehouse_id", entity.getWarehouseId());
        }
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) {
            throw new JeecgBootException("该货架下已存在相同编码的库位");
        }
        //update-end---author:admin---date:2026-07-13---for: 编辑时唯一性校验-----------
        return super.updateById(entity);
    }

    @Override
    public List<String> generateLocations(String shelfId, int rows, int cols) {
        //update-begin---author:admin---date:2026-07-13---for: 生成规则适配货架模型-----------
        MesShelf shelf = shelfMapper.selectById(shelfId);
        if (shelf == null) {
            throw new JeecgBootException("货架不存在");
        }
        List<String> codes = new ArrayList<>();
        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                String code = String.format("%s-%02d-%02d", shelf.getCode(), r + 1, c + 1);
                MesLocation loc = new MesLocation();
                loc.setWarehouseId(shelf.getWarehouseId());
                loc.setZoneId(shelf.getZoneId());
                loc.setShelfId(shelfId);
                loc.setCode(code);
                loc.setName(code);
                loc.setStatus(1);
                baseMapper.insert(loc);
                codes.add(code);
            }
        }
        return codes;
        //update-end---author:admin---date:2026-07-13---for: 生成规则适配货架模型-----------
    }
}
//update-end---author:admin---date:2026-07-06---for: MES基础设置-库位Service实现-----------

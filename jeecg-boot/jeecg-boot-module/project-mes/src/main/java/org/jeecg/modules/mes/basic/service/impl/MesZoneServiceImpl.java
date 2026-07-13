//update-begin---author:admin---date:2026-07-13---for: MES基础设置-库区Service实现-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesZone;
import org.jeecg.modules.mes.basic.entity.MesShelf;
import org.jeecg.modules.mes.basic.entity.MesLocation;
import org.jeecg.modules.mes.basic.mapper.MesZoneMapper;
import org.jeecg.modules.mes.basic.mapper.MesShelfMapper;
import org.jeecg.modules.mes.basic.mapper.MesLocationMapper;
import org.jeecg.modules.mes.basic.service.IMesZoneService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MesZoneServiceImpl extends ServiceImpl<MesZoneMapper, MesZone> implements IMesZoneService {
    @Autowired
    private MesShelfMapper shelfMapper;
    @Autowired
    private MesLocationMapper locationMapper;

    @Override
    @Transactional
    public boolean save(MesZone entity) {
        QueryWrapper<MesZone> activeQw = new QueryWrapper<>();
        activeQw.eq("warehouse_id", entity.getWarehouseId()).eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) {
            throw new JeecgBootException("该仓库下已存在相同编码的库区");
        }
        MesZone old = baseMapper.selectDeletedByWhAndCode(entity.getWarehouseId(), entity.getCode());
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
    public boolean updateById(MesZone entity) {
        QueryWrapper<MesZone> qw = new QueryWrapper<>();
        qw.eq("warehouse_id", entity.getWarehouseId()).eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) {
            throw new JeecgBootException("该仓库下已存在相同编码的库区");
        }
        return super.updateById(entity);
    }

    @Override
    @Transactional
    public boolean removeById(java.io.Serializable id) {
        // 二级级联校验：货架 → 库位
        QueryWrapper<MesShelf> qwShelf = new QueryWrapper<>();
        qwShelf.eq("zone_id", id);
        if (shelfMapper.selectCount(qwShelf) > 0) {
            throw new JeecgBootException("该库区下还有货架，请先删除货架");
        }
        QueryWrapper<MesLocation> qwLoc = new QueryWrapper<>();
        qwLoc.eq("zone_id", id);
        if (locationMapper.selectCount(qwLoc) > 0) {
            throw new JeecgBootException("该库区下还有库位，请先删除库位");
        }
        return super.removeById(id);
    }

    //update-begin---author:admin---date:2026-07-13---for: P1-004批量删除走逐条校验-----------
    @Override
    @Transactional
    public boolean removeByIds(java.util.Collection<?> list) {
        for (Object id : list) {
            this.removeById((java.io.Serializable) id);
        }
        return true;
    }
    //update-end---author:admin---date:2026-07-13---for: P1-004批量删除走逐条校验-----------
}
//update-end---author:admin---date:2026-07-13---for: MES基础设置-库区Service实现-----------

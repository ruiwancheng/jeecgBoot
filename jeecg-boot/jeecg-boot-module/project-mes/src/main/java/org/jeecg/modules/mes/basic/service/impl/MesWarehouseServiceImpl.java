//update-begin---author:admin---date:2026-07-06---for: MES基础设置-仓库Service实现-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesWarehouse;
import org.jeecg.modules.mes.basic.entity.MesLocation;
import org.jeecg.modules.mes.basic.entity.MesZone;
import org.jeecg.modules.mes.basic.entity.MesShelf;
import org.jeecg.modules.mes.basic.mapper.MesWarehouseMapper;
import org.jeecg.modules.mes.basic.mapper.MesLocationMapper;
import org.jeecg.modules.mes.basic.mapper.MesZoneMapper;
import org.jeecg.modules.mes.basic.mapper.MesShelfMapper;
import org.jeecg.modules.mes.basic.service.IMesWarehouseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MesWarehouseServiceImpl extends ServiceImpl<MesWarehouseMapper, MesWarehouse> implements IMesWarehouseService {
    @Autowired
    private MesLocationMapper locationMapper;
    @Autowired
    private MesZoneMapper zoneMapper;
    //update-begin---author:admin---date:2026-07-13---for: P1-001停用校验库区/货架-----------
    @Autowired
    private MesShelfMapper shelfMapper;
    //update-end---author:admin---date:2026-07-13---for: P1-001停用校验库区/货架-----------

    @Override
    @Transactional
    public boolean save(MesWarehouse entity) {
        QueryWrapper<MesWarehouse> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) {
            throw new JeecgBootException("仓库编码已存在，请使用其他编码");
        }
        MesWarehouse old = baseMapper.selectDeletedByCode(entity.getCode());
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
    public boolean updateById(MesWarehouse entity) {
        QueryWrapper<MesWarehouse> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) {
            throw new JeecgBootException("仓库编码已存在，请使用其他编码");
        }
        //update-begin---author:admin---date:2026-07-13---for: P1-001停用校验库区+货架+库位-----------
        if (entity.getStatus() != null && entity.getStatus() == 0) {
            QueryWrapper<MesZone> qwZone = new QueryWrapper<>();
            qwZone.eq("warehouse_id", entity.getId());
            if (zoneMapper.selectCount(qwZone) > 0) {
                throw new JeecgBootException("该仓库下存在库区，无法停用。请先清理库区数据");
            }
            QueryWrapper<MesShelf> qwShelf = new QueryWrapper<>();
            qwShelf.eq("warehouse_id", entity.getId());
            if (shelfMapper.selectCount(qwShelf) > 0) {
                throw new JeecgBootException("该仓库下存在货架，无法停用。请先清理货架数据");
            }
            QueryWrapper<MesLocation> qwLoc = new QueryWrapper<>();
            qwLoc.eq("warehouse_id", entity.getId());
            if (locationMapper.selectCount(qwLoc) > 0) {
                throw new JeecgBootException("该仓库下存在库位，无法停用。请先清理库位数据");
            }
        }
        //update-end---author:admin---date:2026-07-13---for: P1-001停用校验库区+货架+库位-----------
        return super.updateById(entity);
    }

    @Override
    @Transactional
    public boolean removeById(java.io.Serializable id) {
        // 三级级联校验：库区 → 货架 → 库位
        QueryWrapper<MesZone> qwZone = new QueryWrapper<>();
        qwZone.eq("warehouse_id", id);
        if (zoneMapper.selectCount(qwZone) > 0) {
            throw new JeecgBootException("该仓库下还有库区，请先删除库区");
        }
        QueryWrapper<MesShelf> qwShelf = new QueryWrapper<>();
        qwShelf.eq("warehouse_id", id);
        if (shelfMapper.selectCount(qwShelf) > 0) {
            throw new JeecgBootException("该仓库下还有货架，请先删除货架");
        }
        QueryWrapper<MesLocation> qwLoc = new QueryWrapper<>();
        qwLoc.eq("warehouse_id", id);
        if (locationMapper.selectCount(qwLoc) > 0) {
            throw new JeecgBootException("该仓库下还有库位，请先删除库位");
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
//update-end---author:admin---date:2026-07-06---for: MES基础设置-仓库Service实现-----------

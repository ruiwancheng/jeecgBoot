//update-begin---author:admin---date:2026-07-13---for: MES基础设置-货架Service实现-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesShelf;
import org.jeecg.modules.mes.basic.entity.MesLocation;
import org.jeecg.modules.mes.basic.mapper.MesShelfMapper;
import org.jeecg.modules.mes.basic.mapper.MesLocationMapper;
import org.jeecg.modules.mes.basic.service.IMesShelfService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MesShelfServiceImpl extends ServiceImpl<MesShelfMapper, MesShelf> implements IMesShelfService {
    @Autowired
    private MesLocationMapper locationMapper;

    @Override
    @Transactional
    public boolean save(MesShelf entity) {
        QueryWrapper<MesShelf> activeQw = new QueryWrapper<>();
        activeQw.eq("zone_id", entity.getZoneId()).eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) {
            throw new JeecgBootException("该库区下已存在相同编码的货架");
        }
        MesShelf old = baseMapper.selectDeletedByZoneAndCode(entity.getZoneId(), entity.getCode());
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
    public boolean updateById(MesShelf entity) {
        QueryWrapper<MesShelf> qw = new QueryWrapper<>();
        qw.eq("zone_id", entity.getZoneId()).eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) {
            throw new JeecgBootException("该库区下已存在相同编码的货架");
        }
        return super.updateById(entity);
    }

    @Override
    @Transactional
    public boolean removeById(java.io.Serializable id) {
        QueryWrapper<MesLocation> qwLoc = new QueryWrapper<>();
        qwLoc.eq("shelf_id", id);
        if (locationMapper.selectCount(qwLoc) > 0) {
            throw new JeecgBootException("该货架下还有库位，请先删除库位");
        }
        return super.removeById(id);
    }
}
//update-end---author:admin---date:2026-07-13---for: MES基础设置-货架Service实现-----------

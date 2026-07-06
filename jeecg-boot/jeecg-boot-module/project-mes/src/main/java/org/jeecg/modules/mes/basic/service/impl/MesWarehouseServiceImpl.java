//update-begin---author:admin---date:2026-07-06---for: MES基础设置-仓库Service实现-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.entity.MesWarehouse;
import org.jeecg.modules.mes.basic.entity.MesLocation;
import org.jeecg.modules.mes.basic.mapper.MesWarehouseMapper;
import org.jeecg.modules.mes.basic.mapper.MesLocationMapper;
import org.jeecg.modules.mes.basic.service.IMesWarehouseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MesWarehouseServiceImpl extends ServiceImpl<MesWarehouseMapper, MesWarehouse> implements IMesWarehouseService {
    @Autowired
    private MesLocationMapper locationMapper;

    @Override
    @Transactional
    public boolean save(MesWarehouse entity) {
        // 1. 先查是否存在活跃记录（@TableLogic 自动加 del_flag=0）
        QueryWrapper<MesWarehouse> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) {
            throw new JeecgBootException("仓库编码已存在，请使用其他编码");
        }
        // 2. 查是否存在软删除记录（绕开 @TableLogic，用原始 SQL）→ 有则复活
        MesWarehouse old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            // 绕开 @TableLogic：直接用原始 UPDATE，不被 WHERE del_flag=0 拦截
            baseMapper.resurrect(entity);
            return true;
        }
        // 3. 完全不存在 → 正常新增
        return super.save(entity);
    }

    @Override
    public boolean updateById(MesWarehouse entity) {
        // 编辑时排除自身，校验编码唯一
        QueryWrapper<MesWarehouse> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) {
            throw new JeecgBootException("仓库编码已存在，请使用其他编码");
        }
        return super.updateById(entity);
    }

    @Override
    @Transactional
    public boolean removeById(java.io.Serializable id) {
        QueryWrapper<MesLocation> qwLoc = new QueryWrapper<>();
        qwLoc.eq("warehouse_id", id);
        if (locationMapper.selectCount(qwLoc) > 0) {
            throw new JeecgBootException("该仓库下还有库位，请先删除库位");
        }
        return super.removeById(id);
    }
}
//update-end---author:admin---date:2026-07-06---for: MES基础设置-仓库Service实现-----------

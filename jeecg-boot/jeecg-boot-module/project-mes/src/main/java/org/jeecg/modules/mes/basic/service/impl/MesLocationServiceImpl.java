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

    //update-begin---author:admin---date:2026-07-13---for: P0-003批量生成上限-----------
    private static final int GENERATE_MAX = 1000;
    //update-end---author:admin---date:2026-07-13---for: P0-003批量生成上限-----------

    @Override
    @Transactional
    public boolean save(MesLocation entity) {
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
        //update-begin---author:admin---date:2026-07-13---for: P0-004复活维度修正为shelfId+code-----------
        MesLocation old = null;
        if (entity.getShelfId() != null) {
            old = baseMapper.selectDeletedByShelfAndCode(entity.getShelfId(), entity.getCode());
        } else {
            old = baseMapper.selectDeletedByWhAndCode(entity.getWarehouseId(), entity.getCode());
        }
        if (old != null) {
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            // 强制更新shelfId/zoneId为当前提交值，防止层级漂移
            baseMapper.resurrect(entity);
            return true;
        }
        //update-end---author:admin---date:2026-07-13---for: P0-004复活维度修正为shelfId+code-----------
        return super.save(entity);
    }

    @Override
    public boolean updateById(MesLocation entity) {
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
        return super.updateById(entity);
    }

    @Override
    @Transactional
    public List<String> generateLocations(String shelfId, int rows, int cols) {
        //update-begin---author:admin---date:2026-07-13---for: P0-003事务+上限+批量插入-----------
        if (rows <= 0 || cols <= 0) {
            throw new JeecgBootException("行数和列数必须大于0");
        }
        long total = (long) rows * cols;
        if (total > GENERATE_MAX) {
            throw new JeecgBootException("单次生成数量不能超过" + GENERATE_MAX + "，当前：" + total);
        }
        MesShelf shelf = shelfMapper.selectById(shelfId);
        if (shelf == null) {
            throw new JeecgBootException("货架不存在");
        }
        // 预检：检查目标编码是否已存在
        List<MesLocation> batch = new ArrayList<>();
        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                String code = String.format("%s-%02d-%02d", shelf.getCode(), r + 1, c + 1);
                QueryWrapper<MesLocation> qw = new QueryWrapper<>();
                qw.eq("shelf_id", shelfId).eq("code", code);
                if (baseMapper.selectCount(qw) > 0) {
                    throw new JeecgBootException("库位编码 " + code + " 已存在，请勿重复生成");
                }
                MesLocation loc = new MesLocation();
                loc.setWarehouseId(shelf.getWarehouseId());
                loc.setZoneId(shelf.getZoneId());
                loc.setShelfId(shelfId);
                loc.setCode(code);
                loc.setName(code);
                loc.setStatus(1);
                batch.add(loc);
            }
        }
        // 批量插入
        saveBatch(batch);
        List<String> codes = new ArrayList<>();
        for (MesLocation loc : batch) {
            codes.add(loc.getCode());
        }
        return codes;
        //update-end---author:admin---date:2026-07-13---for: P0-003事务+上限+批量插入-----------
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
//update-end---author:admin---date:2026-07-06---for: MES基础设置-库位Service实现-----------

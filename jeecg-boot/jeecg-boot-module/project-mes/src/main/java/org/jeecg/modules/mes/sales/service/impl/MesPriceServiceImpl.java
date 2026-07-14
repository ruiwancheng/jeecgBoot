//update-begin---author:ruiwancheng---date:2026-07-14---for: MES销售管理-价格Service实现-----------
package org.jeecg.modules.mes.sales.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.shiro.SecurityUtils;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.common.system.vo.LoginUser;
import org.jeecg.modules.mes.sales.entity.MesPrice;
import org.jeecg.modules.mes.sales.mapper.MesPriceMapper;
import org.jeecg.modules.mes.sales.service.IMesPriceService;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.*;

@Service
public class MesPriceServiceImpl extends ServiceImpl<MesPriceMapper, MesPrice> implements IMesPriceService {

    private static final Set<String> VALID_TYPES = new HashSet<>(Arrays.asList("1", "2"));

    @Override
    @Transactional
    public boolean save(MesPrice entity) {
        validateEntity(entity);
        QueryWrapper<MesPrice> activeQw = new QueryWrapper<>();
        activeQw.eq("code", entity.getCode());
        if (baseMapper.selectCount(activeQw) > 0) {
            throw new JeecgBootException("价格编码已存在，请使用其他编码");
        }
        MesPrice old = baseMapper.selectDeletedByCode(entity.getCode());
        if (old != null) {
            entity.setId(old.getId());
            entity.setCreateBy(old.getCreateBy());
            entity.setCreateTime(old.getCreateTime());
            entity.setUpdateBy(getCurrentUsername());
            entity.setUpdateTime(new Date());
            baseMapper.resurrect(entity);
            return true;
        }
        try {
            return super.save(entity);
        } catch (DuplicateKeyException e) {
            throw new JeecgBootException("价格编码已存在，请使用其他编码");
        }
    }

    @Override
    @Transactional
    public boolean updateById(MesPrice entity) {
        validateEntity(entity);
        QueryWrapper<MesPrice> qw = new QueryWrapper<>();
        qw.eq("code", entity.getCode()).ne("id", entity.getId());
        if (baseMapper.selectCount(qw) > 0) {
            throw new JeecgBootException("价格编码已存在，请使用其他编码");
        }
        try {
            return super.updateById(entity);
        } catch (DuplicateKeyException e) {
            throw new JeecgBootException("价格编码已存在，请使用其他编码");
        }
    }

    @Override
    @Transactional
    public boolean removeById(Serializable id) {
        return super.removeById(id);
    }

    @Override
    @Transactional
    public boolean removeByIds(Collection<?> list) {
        if (list == null || list.isEmpty()) return false;
        return super.removeByIds(list);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void importFromExcel(List<MesPrice> list) {
        for (MesPrice entity : list) {
            save(entity);
        }
    }

    private void validateEntity(MesPrice entity) {
        if (!StringUtils.hasText(entity.getCode())) {
            throw new JeecgBootException("价格编码不能为空");
        }
        if (entity.getCode().length() > 50) {
            throw new JeecgBootException("价格编码长度不能超过50个字符");
        }
        if (!StringUtils.hasText(entity.getMaterialId())) {
            throw new JeecgBootException("物料不能为空");
        }
        if (entity.getPrice() == null) {
            throw new JeecgBootException("价格不能为空");
        }
        if (entity.getPrice().compareTo(BigDecimal.ZERO) < 0) {
            throw new JeecgBootException("价格不能为负数");
        }
        if (entity.getType() != null && !VALID_TYPES.contains(entity.getType())) {
            throw new JeecgBootException("价格类型值无效");
        }
    }

    private String getCurrentUsername() {
        try {
            LoginUser user = (LoginUser) SecurityUtils.getSubject().getPrincipal();
            return user != null ? user.getUsername() : "system";
        } catch (Exception e) {
            return "system";
        }
    }
}
//update-end---author:ruiwancheng---date:2026-07-14---for: MES销售管理-价格Service实现-----------

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

    //update-begin---author:ruiwancheng---date:2026-07-14---for: 审计修复-价格业务校验-----------
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
        // 日期校验：结束日期不能早于开始日期
        if (entity.getBeginDate() != null && entity.getEndDate() != null
                && entity.getEndDate().before(entity.getBeginDate())) {
            throw new JeecgBootException("失效日期不能早于生效日期");
        }
        // 客户协议价必须绑定客户
        if ("2".equals(entity.getType()) && !StringUtils.hasText(entity.getCustomerId())) {
            throw new JeecgBootException("客户协议价必须选择客户");
        }
        // 价格重叠校验
        checkPriceOverlap(entity);
    }

    private void checkPriceOverlap(MesPrice entity) {
        if (entity.getMaterialId() == null || entity.getBeginDate() == null) return;
        QueryWrapper<MesPrice> qw = new QueryWrapper<>();
        qw.eq("material_id", entity.getMaterialId());
        qw.eq("status", "1");
        // 同样客户ID（都为null也视为同一组）
        if (entity.getCustomerId() != null) {
            qw.eq("customer_id", entity.getCustomerId());
        } else {
            qw.isNull("customer_id");
        }
        // 日期范围重叠：(A.begin <= B.end) AND (A.end >= B.begin)
        qw.le("begin_date", entity.getEndDate() != null ? entity.getEndDate() : entity.getBeginDate());
        if (entity.getEndDate() != null) {
            qw.ge("end_date", entity.getBeginDate());
        } else {
            // 无结束日期视为永久有效
            qw.and(w -> w.isNull("end_date").or().ge("end_date", entity.getBeginDate()));
        }
        if (entity.getId() != null) {
            qw.ne("id", entity.getId()); // 排除自己
        }
        if (baseMapper.selectCount(qw) > 0) {
            throw new JeecgBootException("该物料+客户在相同时间段内已有价格记录，请检查日期范围");
        }
    }
    //update-end---author:ruiwancheng---date:2026-07-14---for: 审计修复-价格业务校验-----------

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

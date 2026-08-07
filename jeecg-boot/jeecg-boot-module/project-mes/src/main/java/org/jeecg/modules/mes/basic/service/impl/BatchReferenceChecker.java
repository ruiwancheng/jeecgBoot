//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 03 c_mes_batch（del_flag=0 计数）-----------
package org.jeecg.modules.mes.basic.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.batch.master.entity.MesBatch;
import org.jeecg.modules.mes.batch.master.mapper.MesBatchMapper;
import org.jeecg.modules.mes.basic.service.MaterialReferenceChecker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class BatchReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesBatchMapper mapper;

    @Override public String describe() { return "c_mes_batch"; }

    @Override
    public void assertNotReferenced(String materialId) {
        // 排除软删批次，只统计未删的活跃批次
        Long cnt = mapper.selectCount(
            new QueryWrapper<MesBatch>().eq("material_id", materialId).eq("del_flag", 0));
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料被 " + cnt + " 个批次（c_mes_batch, del_flag=0）引用，请先归档");
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫表 03-----------

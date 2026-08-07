//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】阶段 4 关键表行锁：CriticalTableLockService（防守卫→删除窗口的并发漏判）-----------
package org.jeecg.modules.mes.basic.service;

import lombok.extern.slf4j.Slf4j;
import org.jeecg.common.exception.JeecgBootException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 守卫→删除窗口的关键表行锁重检（防并发漏判）。
 * <p>
 * 19 张表中，仅对 8 张"直接表"（无 JOIN、无 status 过滤）做 FOR UPDATE 行锁重检；
 * 11 张 JOIN 父单 + status 过滤的明细表由 MaterialReferenceAggregator 的 UNION ALL 聚合 + 事务隔离保证。
 */
@Slf4j
@Component
public class CriticalTableLockService {

    @Autowired private NamedParameterJdbcTemplate jdbc;

    /** 8 张直接表（无 JOIN、无 status 过滤） */
    private static final Set<String> DIRECT_TABLES = Set.of(
        "c_mes_inventory",
        "c_mes_inventory_ledger",
        "c_mes_batch",
        "c_mes_batch_inventory",
        "c_mes_batch_ledger",
        "c_mes_bom_item",
        "c_mes_cost_log",
        "c_mes_price"
    );

    /**
     * 关键表行锁 + 重检。
     *
     * @param materialId 物料 ID
     * @param tables    所有 19 张表名（来自 aggregator 聚合 keySet）
     */
    @Transactional(rollbackFor = Exception.class)
    public void lockAndRecheck(String materialId, Set<String> tables) {
        if (tables == null || tables.isEmpty()) return;
        for (String tbl : tables) {
            if (!DIRECT_TABLES.contains(tbl)) continue;  // 只锁直接表；JOIN 表由聚合事务保证
            String sql = "SELECT id FROM " + tbl + " WHERE material_id = :materialId FOR UPDATE";
            List<Map<String, Object>> locked = jdbc.queryForList(sql,
                Collections.singletonMap("materialId", materialId));
            if (!locked.isEmpty()) {
                throw new JeecgBootException(
                    "并发检测：" + tbl + " 守卫通过后又有 " + locked.size() + " 行被创建，删除拒绝");
            }
        }
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】CriticalTableLockService 关键表行锁-----------

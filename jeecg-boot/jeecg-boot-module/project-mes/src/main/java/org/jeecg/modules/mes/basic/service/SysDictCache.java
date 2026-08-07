//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】阶段 4 字典缓存：SysDictCache（@PostConstruct + @Scheduled 60s）-----------
package org.jeecg.modules.mes.basic.service;

import lombok.extern.slf4j.Slf4j;
import org.jeecg.common.system.vo.DictModel;
import org.jeecg.modules.system.service.ISysDictService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * 字典缓存：未完结业务单据状态集，用于 MaterialReferenceAggregator 的 JOIN status 过滤。
 * <p>
 * - @PostConstruct：启动时初始化一次
 * - @Scheduled fixedRate=60s：每 60 秒刷新（应对字典热更）
 * - 降级：缓存为空时返回 ["UNKNOWN"]，放行守卫 + log.warn（避免启动早期误阻断）
 */
@Slf4j
@Component
public class SysDictCache {

    /** 字典 code → 未完结状态值列表（缓存） */
    private final Map<String, List<String>> openStatusCache = new ConcurrentHashMap<>();

    @Autowired private ISysDictService dictService;

    @PostConstruct
    public void init() {
        log.info("[SysDictCache] 启动初始化...");
        refresh();
    }

    @Scheduled(fixedRate = 60_000)  // 每 60s 刷新
    public void refresh() {
        try {
            // 11 张业务单据的状态字典（"未完结"状态值的列表）
            openStatusCache.put("mes_production_order_status", getOpenItems("mes_production_order_status", "已完结"));
            openStatusCache.put("mes_completion_receipt_status", getOpenItems("mes_completion_receipt_status", "已入库"));
            openStatusCache.put("mes_production_picking_status", getOpenItems("mes_production_picking_status", "已审核"));
            openStatusCache.put("mes_purchase_apply_status", getOpenItems("mes_purchase_apply_status", "已入库"));
            openStatusCache.put("mes_purchase_order_status", getOpenItems("mes_purchase_order_status", "已关闭"));
            openStatusCache.put("mes_purchase_receipt_status", getOpenItems("mes_purchase_receipt_status", "已入库"));
            openStatusCache.put("mes_sales_order_status", getOpenItems("mes_sales_order_status", "已关闭"));
            openStatusCache.put("mes_sales_outbound_status", getOpenItems("mes_sales_outbound_status", "已审核"));
            openStatusCache.put("mes_delivery_note_status", getOpenItems("mes_delivery_note_status", "已发货"));
            openStatusCache.put("mes_other_stock_in_status", getOpenItems("mes_other_stock_in_status", "已入库"));
            openStatusCache.put("mes_other_stock_out_status", getOpenItems("mes_other_stock_out_status", "已出库"));
            openStatusCache.put("mes_stocktake_status", getOpenItems("mes_stocktake_status", "已审核"));
            log.debug("[SysDictCache] 刷新完成，缓存字典数={}", openStatusCache.size());
        } catch (Exception e) {
            log.warn("[SysDictCache] 字典缓存刷新失败，使用上次缓存", e);
        }
    }

    /**
     * 取某字典的"未完结"状态值列表（排除 closedText 对应的状态）。
     * closedText 对应业务上的"完结/关闭/审核"终态。
     */
    private List<String> getOpenItems(String dictCode, String closedText) {
        List<DictModel> items = dictService.queryDictItemsByCode(dictCode);
        if (items == null) return List.of();
        return items.stream()
            .filter(i -> !closedText.equals(i.getText()))
            .map(DictModel::getValue)
            .collect(Collectors.toList());
    }

    /**
     * 取某字典的"未完结"状态值列表（公开方法）。
     * 缓存为空时返回 ["UNKNOWN"]，放行守卫 + log.warn，避免启动早期误阻断。
     */
    public List<String> getOpenStatuses(String dictCode) {
        List<String> v = openStatusCache.get(dictCode);
        if (v == null || v.isEmpty()) {
            log.warn("[SysDictCache] 字典 {} 缓存为空，返回 UNKNOWN 放行守卫（可能字典未配置）", dictCode);
            return List.of("UNKNOWN");
        }
        return v;
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】SysDictCache 字典缓存-----------

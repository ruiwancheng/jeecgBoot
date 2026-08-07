//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】阶段 4 守卫接口（19 个 checker bean 列表模式）-----------
package org.jeecg.modules.mes.basic.service;

/**
 * 物料删除守卫（Codex v3 P0：19 张引用表全覆盖）
 * <p>
 * 每张含 material_id 的表一个 @Component 实现，Spring 自动收集到 List&lt;MaterialReferenceChecker&gt;。
 * MesMaterialServiceImpl.removeById 注入 List 遍历，preCheckDelete 同理用于 UI 预检。
 *
 * <p>语义分级：
 * <ul>
 * <li>完全无行：含零库存行（避免软删后产生新孤儿）</li>
 * <li>del_flag=0 计数：排除已软删的业务数据</li>
 * <li>JOIN parent + status 过滤：只统计未完结单据</li>
 * </ul>
 */
public interface MaterialReferenceChecker {
    /** 短表名（c_mes_xxx），用于错误信息与启动自检比对 */
    String describe();

    /**
     * 校验物料在对应表是否仍被引用；若被引用，抛 JeecgBootException 包含表名+行数。
     * 调用方负责捕获异常以提取行数。
     */
    void assertNotReferenced(String materialId);
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】守卫接口-----------

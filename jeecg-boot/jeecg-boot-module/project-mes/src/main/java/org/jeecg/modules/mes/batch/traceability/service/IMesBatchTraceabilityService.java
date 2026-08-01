//update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-Service接口（复用 c_mes_batch_ledger）-----------
package org.jeecg.modules.mes.batch.traceability.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.batch.traceability.entity.MesBatchTraceability;

/**
 * 批次追溯视图 Service 接口。
 *
 * <p>当前切片（trace-1-list）只暴露基础 CRUD（继承自 IService），
 * 后续切片（trace-2-detail / trace-3-export）按需补充追溯专有方法。Service 接口本身
 * 不写业务方法——列表搜索走 Controller 层 QueryGenerator + BaseMapper 组合（与
 * ledger/inventory 模块的列表查询保持一致）。</p>
 */
public interface IMesBatchTraceabilityService extends IService<MesBatchTraceability> {
}
//update-end---author:ruiwancheng---date:20260803---for: V10.0.2 MES批次追溯-Service接口（复用 c_mes_batch_ledger）-----------
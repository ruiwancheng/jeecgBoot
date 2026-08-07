//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产订单Service接口-----------
package org.jeecg.modules.mes.manufacturing.order.service;
import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.manufacturing.order.entity.MesProductionOrder;

public interface IProductionOrderService extends IService<MesProductionOrder> {
    //update-begin---author:ruiwancheng---date:2026-08-08---for: slice-3 订单状态机 5 端点 + generatePicking（决策表 E 复用 edit 权限）-----------
    /** 审核：草稿→已审核，校验 BOM 生效 */
    void audit(String id);
    /** 下达：已审核→已下达，同事务内 BOM 子件×planQty 库存校验（C 硬阻止），生成草稿领料单（alpha=B 保留草稿） */
    String release(String id);
    /** 完工：已下达→已完工，要求 completedQty≥planQty（决策 F 允许超量报工） */
    void complete(String id);
    /** 关闭：任意非终态→已关闭（5/6/7 终态抛错） */
    void close(String id);
    /** 取消：仅草稿/已审核可取消（1/2），其余抛错 */
    void cancel(String id);
    /** 手动生成草稿领料单（订单已下达后补领场景；alpha=B 保留草稿） */
    String generatePicking(String orderId);
    //update-end---author:ruiwancheng---date:2026-08-08---for: slice-3 订单状态机 5 端点 + generatePicking-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-生产订单Service接口-----------
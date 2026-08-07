//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM Service接口-----------
package org.jeecg.modules.mes.manufacturing.bom.service;
import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.manufacturing.bom.entity.MesBom;
public interface IMesBomService extends IService<MesBom> {
    MesBom queryWithItems(String id);
    void saveWithItems(MesBom entity);
    void updateWithItems(MesBom entity);
    void removeWithItems(String id);
    //update-begin---author:ruiwancheng---date:2026-08-07---for: slice-1 BOM状态机 approve/disable（同产品一生效 FOR UPDATE 加固）-----------
    /** BOM 生效：同事务内 SELECT COUNT FOR UPDATE 校验该产品已无生效BOM，再更新status='2' */
    void approve(String id);
    /** BOM 失效：任意非失效状态→失效；已失效抛错 */
    void disable(String id);
    //update-end---author:ruiwancheng---date:2026-08-07---for: slice-1 BOM状态机 approve/disable（同产品一生效 FOR UPDATE 加固）-----------
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM Service接口-----------

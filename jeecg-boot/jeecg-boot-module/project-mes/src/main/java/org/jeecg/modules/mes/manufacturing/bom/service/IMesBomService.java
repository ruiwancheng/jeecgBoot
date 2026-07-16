//update-begin---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM Service接口-----------
package org.jeecg.modules.mes.manufacturing.bom.service;
import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.manufacturing.bom.entity.MesBom;
public interface IMesBomService extends IService<MesBom> {
    MesBom queryWithItems(String id);
    void saveWithItems(MesBom entity);
    void updateWithItems(MesBom entity);
    void removeWithItems(String id);
}
//update-end---author:ruiwancheng---date:2026-07-16---for: MES生产制造-BOM Service接口-----------

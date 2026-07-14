//update-begin---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商Service接口-----------
//update-begin---author:ruiwancheng---date:2026-07-14---for: 审计修复#3-导入事务接口定义-----------
package org.jeecg.modules.mes.basic.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.basic.entity.MesSupplier;

import java.util.List;

public interface IMesSupplierService extends IService<MesSupplier> {
    void importFromExcel(List<MesSupplier> list);
}
//update-end---author:ruiwancheng---date:2026-07-14---for: 审计修复#3-导入事务接口定义-----------
//update-end---author:ruiwancheng---date:2026-07-14---for: MES基础设置-供应商Service接口-----------

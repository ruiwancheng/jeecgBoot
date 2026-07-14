//update-begin---author:ruiwancheng---date:2026-07-14---for: MES基础设置-物料Service接口-----------
package org.jeecg.modules.mes.basic.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.basic.entity.MesMaterial;

import java.util.List;

public interface IMesMaterialService extends IService<MesMaterial> {
    void importFromExcel(List<MesMaterial> list);
}
//update-end---author:ruiwancheng---date:2026-07-14---for: MES基础设置-物料Service接口-----------

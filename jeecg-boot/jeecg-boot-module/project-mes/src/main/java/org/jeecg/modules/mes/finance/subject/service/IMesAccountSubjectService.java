//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 会计科目Service接口-----------
package org.jeecg.modules.mes.finance.subject.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.finance.subject.entity.MesAccountSubject;

import java.util.List;

public interface IMesAccountSubjectService extends IService<MesAccountSubject> {
    List<MesAccountSubject> queryTree();
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 Step3 会计科目Service接口-----------

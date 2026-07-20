//update-begin---author:ruiwancheng---date:2026-07-21  for：【编码规则】Service接口-----------
package org.jeecg.modules.mes.basic.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.basic.entity.MesCodeRule;

public interface IMesCodeRuleService extends IService<MesCodeRule> {
    /** 获取下一个编码 */
    String nextCode(String ruleCode);
}
//update-end---author:ruiwancheng---date:2026-07-21  for：【编码规则】Service接口-----------

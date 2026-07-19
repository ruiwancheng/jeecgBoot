//update-begin---author:ruiwancheng---date:2026-07-19---for: Phase2 凭证Service接口-----------
package org.jeecg.modules.mes.finance.voucher.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.jeecg.modules.mes.finance.voucher.entity.MesVoucher;

public interface IMesVoucherService extends IService<MesVoucher> {
    MesVoucher queryWithItems(String id);
    void saveWithItems(MesVoucher entity);
    void updateWithItems(MesVoucher entity);
    void removeWithItems(String id);
    void audit(String id);
}
//update-end---author:ruiwancheng---date:2026-07-19---for: Phase2 凭证Service接口-----------

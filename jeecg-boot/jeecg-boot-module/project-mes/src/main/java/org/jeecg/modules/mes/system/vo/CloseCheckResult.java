//update-begin---author:ruiwancheng---date:20260731---for:【生产批次总开关】关闭检查结果VO-----------
package org.jeecg.modules.mes.system.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

/**
 * 关闭检查结果
 * 用于通用设置关闭开关前的业务规则校验
 */
@Data
@Schema(description = "关闭检查结果")
public class CloseCheckResult implements Serializable {
    private static final long serialVersionUID = 1L;

    @Schema(description = "是否可以关闭")
    private boolean canClose;

    @Schema(description = "错误清单（每项包含 layer/title/detail）")
    private List<CheckError> errors = new ArrayList<>();

    public boolean hasError() {
        return errors != null && !errors.isEmpty();
    }

    public CloseCheckResult addError(String layer, String title, String detail) {
        if (this.errors == null) this.errors = new ArrayList<>();
        this.errors.add(new CheckError(layer, title, detail));
        this.canClose = false;
        return this;
    }

    public static CloseCheckResult ok() {
        CloseCheckResult r = new CloseCheckResult();
        r.canClose = true;
        return r;
    }

    @Data
    @Schema(description = "检查错误项")
    public static class CheckError implements Serializable {
        private static final long serialVersionUID = 1L;
        @Schema(description = "检查层（L1/L2/L3）")
        private String layer;
        @Schema(description = "错误标题")
        private String title;
        @Schema(description = "错误详情")
        private String detail;

        public CheckError() {}
        public CheckError(String layer, String title, String detail) {
            this.layer = layer;
            this.title = title;
            this.detail = detail;
        }
    }
}
//update-end---author:ruiwancheng---date:20260731---for:【生产批次总开关】关闭检查结果VO-----------
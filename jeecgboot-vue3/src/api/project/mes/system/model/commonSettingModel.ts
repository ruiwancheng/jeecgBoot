//update-begin---author:ruiwancheng---date:20260731---for:【生产批次总开关】前端 API 类型定义（MesGlobalSwitch + CloseCheckResult）-----------
/** MES 全局开关（对应后端 c_mes_global_switch 表） */
export interface MesGlobalSwitch {
  id?: string;
  /** 开关标识（如 mes_batch_enabled） */
  switchKey: string;
  /** 开关值：0 关闭 / 1 开启 */
  switchValue: number;
  /** 开关名称（前端展示用） */
  switchName?: string;
  /** 开关说明 */
  description?: string;
  createBy?: string;
  createTime?: string;
  updateBy?: string;
  updateTime?: string;
}

/** 关闭检查结果中的一项错误 */
export interface CloseCheckError {
  layer: string;
  title: string;
  detail: string;
}

/** 关闭检查结果 */
export interface CloseCheckResult {
  canClose: boolean;
  errors: CloseCheckError[];
}
//update-end---author:ruiwancheng---date:20260731---for:【生产批次总开关】前端 API 类型定义-----------

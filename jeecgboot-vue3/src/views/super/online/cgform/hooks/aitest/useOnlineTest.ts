import { FormActionType, JCodeEditor } from '/@/components/Form';
import { ref } from 'vue';

export function useOnlineTest(_data, _methods, _form: Nullable<FormActionType>) {
  // Online单元测试开关
  const aiTestMode = ref(false);
  const aiTestTable = ref<any>([]);
  const aiTableList = ref<any>([]);

  function initVirtualData() {
  }

  // 自定义按钮
  function genButtons(_code) {
  }

  // 生成java增强
  function genEnhanceJavaData(_code) {
  }

  // 生成js增强
  function genEnhanceJsData(_tableName, _type, _codeEditor: InstanceType<typeof JCodeEditor>) {
  }

  // 自定义sql增强
  function genEnhanceSqlData(_code, _tableName) {
  }

  /**
   * 加载配置信息
   */
  function setTaleConfig() {
  }

  function tableJsonGetHelper(pickAfter) {
    console.log('表的配置信息', JSON.stringify(pickAfter));
    console.log('---------------------------------------');
  }

  /**
   * json 获取小助手
   * @param fields
   */
  function fieldsJsonGetHelper(_fields) {
  }

  function refreshCacheTableName(_oldValue, _newValue) {
  }

  function getCacheTableName(_name) {
  }

  // noinspection JSUnusedGlobalSymbols
  return {
    aiTestMode,
    aiTestTable,
    aiTableList,
    initVirtualData,
    genButtons,
    genEnhanceJavaData,
    genEnhanceJsData,
    genEnhanceSqlData,
    setTaleConfig,
    tableJsonGetHelper,
    fieldsJsonGetHelper,
    refreshCacheTableName,
    getCacheTableName,
  };
}
# defHttp 拦截器自动成功横幅：长文本接口必须 successMessageMode:'none'

**场景**：审核/批量审核返回较长的业务文案（含单号、多条摘要），JeecgBoot 的 defHttp 全局拦截器对 `success && message` 自动弹**顶部通栏横幅**（`createMessage.success`），长文本一行塞不下就向右溢出滚动。页面同时又弹自定义 Modal → 用户看到"两个提示"，且横幅滚动难看。

**根因**：jeecg axios 封装默认 `successMessageMode: 'success'`——只要后端返回 success+message 就自动 toast，**和消息长短无关，和页面是否自己处理无关**。

**标准做法**：
- 返回**短提示**的接口：保持默认（拦截器弹"添加成功"很合适）
- 返回**长文案/结构化结果**（审核摘要、批量结果）的接口：调用时加 `successMessageMode: 'none'`，由页面自己用 Modal/页面内展示

```ts
defHttp.put({ url, params }, { joinParamsToUrl: true, successMessageMode: 'none' })
```

**判断信号**：顶部出现通栏长文本横幅 = 拦截器自动弹的，不是页面代码弹的——去 api.ts 加 'none'，别在页面组件里找。

**实证**：2026-07-29 盘点审核"提示向右滚动"，两次修 Modal 无效后截图实锤是拦截器横幅。

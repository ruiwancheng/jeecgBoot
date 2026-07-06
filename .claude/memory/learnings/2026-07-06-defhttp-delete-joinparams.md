---
name: defhttp-delete-joinparams
description: defHttp.delete 默认参数在请求体，需 joinParamsToUrl 才能拼到 URL 上
metadata:
  type: reference
---

# defHttp.delete 参数传递：必须加 joinParamsToUrl

## 问题

前端调用删除 API 报错：`Required request parameter 'id' is not present`

## 根因

`defHttp.delete()` 默认把参数放在请求体（Request Body）中，但后端 `@DeleteMapping` + `@RequestParam` 要求参数在 URL 查询串上。

## 修复

```typescript
// ❌ 错误：参数在 body，后端 @RequestParam 收不到
export const deleteXxx = (params) => defHttp.delete({ url: Api.delete, params });

// ✅ 正确：加 joinParamsToUrl，拼成 ?id=xxx
export const deleteXxx = (params) => defHttp.delete({ url: Api.delete, params }, { joinParamsToUrl: true });
```

**Why:** `defHttp` 是 JeecgBoot 封装的 Axios，DELETE 请求的 params 默认走 body，`joinParamsToUrl: true` 强制拼到 URL 后面。

**How to apply:** 所有 `defHttp.delete` 调用，如果后端用 `@RequestParam`，都加 `{ joinParamsToUrl: true }`。

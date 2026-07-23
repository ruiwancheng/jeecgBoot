# [2026-07-24] [Vue/Pinia] Pinia getter 是属性不是方法——userStore.getUserInfo?.realname 而非 getUserInfo()?.realname

## 触发条件
前端代码中调用 `useUserStore().getUserInfo()` 获取用户信息，值始终为空。

## 根因
Pinia Options API 的 `getters` 定义为方法签名 `getUserInfo(): UserInfo`，但实际访问时是**计算属性**，不加 `()`。加了 `()` 会把返回的 UserInfo 对象当函数调用，静默失败（TypeError swallowed by optional chaining）。

## 处理方式
```typescript
// ❌ 错误
const name = useUserStore().getUserInfo()?.realname;
const name = userStore.getUserInfo()?.realname;

// ✅ 正确
const name = userStore.getUserInfo?.realname;
```

## 关联
- 同类型错误：Pinia `computed` 属性同样不加 `()`
- 排查方法：检查 `?.` 后面的值是 `undefined` → 大概率是 getter 被当作方法调了

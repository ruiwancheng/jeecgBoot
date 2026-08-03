//update-begin---author:mes-shiro-fix-2026-08-03---for: 修复 mes controller 上 @RequiresPermissions 注解不生效（Shiro AOP 根因）-----------
package org.jeecg.modules.mes.security;

import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.spring.security.interceptor.AuthorizationAttributeSourceAdvisor;
import org.springframework.aop.Advisor;
import org.springframework.aop.framework.Advised;
import org.springframework.aop.support.AopUtils;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * MES 模块 Shiro Advisor 注入器（临时 hotfix）
 *
 * <p>背景: 2026-08-03 渗透测试 strix 发现 mes controller (H-1~H-4 + BONUS)
 * 缺 @RequiresPermissions,提交 b538075/53c6627 加注解后,运行时验证发现注解
 * 未生效 — ceshi 仍能越权调用。
 *
 * <p>根因: jeecg-boot-base-core/src/main/java/org/jeecg/config/shiro/ShiroConfig.java
 * 的 DefaultAdvisorAutoProxyCreator 配置 setUsePrefix(true) + advisorBeanNamePrefix
 * ("_no_advisor"),导致 Shiro 的 AuthorizationAttributeSourceAdvisor (bean name
 * 不以 _no_advisor 开头) 不被织入到 org.jeecg.modules.mes.* controller 的 CGLIB
 * 代理中(实测 mes controller 拦截链中无 AopAllianceAnnotationsAuthorizingMethodInterceptor
 * 节点;sys controller 拦截链有)。
 *
 * <p>修法: 在 mes 模块内添加 BeanPostProcessor, 强制将 Shiro Advisor 注入到
 * 已代理的 mes controller 的 advisor chain 中。仅作用于 org.jeecg.modules.mes.*
 * 包下的 @RestController bean,不影响 sys controller 或其他模块。
 *
 * <p>边界: 因 boundary.md 禁止写入 jeecg-boot-base-core/,此为唯一可行的
 * 边界内修法。
 */
@Slf4j
@Component
public class MesShiroAdvisorInjector implements BeanPostProcessor, ApplicationContextAware {

    private static final String MES_PACKAGE_PREFIX = "org.jeecg.modules.mes.";

    private ApplicationContext applicationContext;

    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
        try {
            // 1) 只处理 mes 包下的 @RestController bean
            Class<?> targetClass = AopUtils.getTargetClass(bean);
            if (!targetClass.getName().startsWith(MES_PACKAGE_PREFIX)) {
                return bean;
            }
            if (targetClass.getAnnotation(RestController.class) == null) {
                return bean;
            }

            // 2) bean 必须是 Advised (已经被 CGLIB/JDK 代理过)
            if (!(bean instanceof Advised)) {
                log.warn("[mes-shiro-injector] {} not Advised, skip Shiro injection", beanName);
                return bean;
            }
            Advised advised = (Advised) bean;

            // 3) 获取 Shiro Advisor
            Map<String, AuthorizationAttributeSourceAdvisor> advisors =
                    applicationContext.getBeansOfType(AuthorizationAttributeSourceAdvisor.class);
            if (advisors.isEmpty()) {
                log.warn("[mes-shiro-injector] no Shiro AuthorizationAttributeSourceAdvisor found in container, skip");
                return bean;
            }
            AuthorizationAttributeSourceAdvisor shiroAdvisor =
                    advisors.values().iterator().next();

            // 4) 检查是否已经注入 (避免重复,例如同一 bean 被多次后处理)
            for (Advisor existing : advised.getAdvisors()) {
                if (existing == shiroAdvisor) {
                    return bean;
                }
            }

            // 5) 注入 Shiro Advisor 到 advisor chain 开头 (高优先级, 业务方法前执行)
            advised.addAdvisor(0, shiroAdvisor);
            log.warn("[mes-shiro-injector] \u2713 Shiro Advisor injected into {} (bean={}, targetClass={})",
                    targetClass.getSimpleName(), beanName, targetClass.getName());
            return bean;

        } catch (Throwable t) {
            // 任何异常都不能影响 bean 初始化,仅记录
            log.error("[mes-shiro-injector] failed to inject into {}: {}", beanName, t.getMessage(), t);
            return bean;
        }
    }

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        this.applicationContext = applicationContext;
    }
}
//update-end---author:mes-shiro-fix-2026-08-03---for: 修复 mes controller 上 @RequiresPermissions 注解不生效（Shiro AOP 根因）-----------
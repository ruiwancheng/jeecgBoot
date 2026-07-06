[2026-07-05] [测试] JeecgBoot API 自动化测试需要关闭验证码
触发：编写调用后端 API 的自动化测试
处理：application-dev.yml 加 enableLoginCaptcha: false。测试先调 /sys/login 取 X-Access-Token。测试文件放 harness/tests/<客户名>/<功能名>.test.js。

import type { Page } from '@playwright/test'
import { expect } from '@playwright/test'

export class BasePage {
  readonly usernameInput: ReturnType<Page['getByRole']>
  readonly passwordInput: ReturnType<Page['getByRole']>
  readonly loginBtn: ReturnType<Page['getByRole']>

  constructor(public readonly page: Page) {
    this.usernameInput = page.getByRole('textbox', { name: '账号' })
    this.passwordInput = page.getByRole('textbox', { name: '密码' })
    this.loginBtn = page.getByRole('button', { name: '登 录' })
  }

  async login(username = 'admin', password = '123456') {
    await this.page.goto('/login')
    await expect(this.loginBtn).toBeVisible()
    if ((await this.usernameInput.inputValue().catch(() => '')) === '') await this.usernameInput.fill(username)
    if ((await this.passwordInput.inputValue().catch(() => '')) === '') await this.passwordInput.fill(password)
    await this.loginBtn.click()
    await this.page.waitForURL(url => !url.pathname.includes('/login'), { timeout: 30000 })
  }
}

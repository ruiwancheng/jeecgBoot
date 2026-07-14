import { expect, type Page, type Locator } from '@playwright/test'

export class WarehousePage {
  readonly addBtn: Locator
  readonly searchCodeInput: Locator
  readonly searchBtn: Locator
  readonly resetBtn: Locator
  readonly table: Locator
  readonly drawer: Locator
  readonly drawerConfirmBtn: Locator
  readonly drawerCloseBtn: Locator

  constructor(public readonly page: Page) {
    this.addBtn = page.getByRole('button', { name: '新增仓库' })
    this.searchCodeInput = page.getByRole('textbox', { name: '仓库编码' }).first()
    this.searchBtn = page.getByRole('button', { name: '查询' })
    this.resetBtn = page.getByRole('button', { name: '重置' })
    this.table = page.locator('.ant-table')
    this.drawer = page.locator('.ant-drawer')
    this.drawerConfirmBtn = page.getByRole('button', { name: '确 认' })
    this.drawerCloseBtn = page.locator('.ant-drawer-close').first()
  }

  async goto() {
    await this.page.click('text=MES系统')
    await this.page.click('text=基础设置')
    await this.page.click('text=仓库管理')
    await this.page.waitForSelector('.jeecg-basic-table')
  }

  getDrawerBody(): Locator { return this.drawer.locator('.ant-drawer-body') }

  getDrawerFormItem(label: string): Locator {
    return this.getDrawerBody().locator('.ant-form-item').filter({ hasText: label })
  }

  async openCreateForm() {
    await this.addBtn.click()
    await this.page.waitForSelector('.ant-drawer')
  }

  async fillDrawerField(label: string, value: string) {
    await this.getDrawerFormItem(label).locator('input').fill(value)
  }

  async getDrawerFieldValue(label: string): Promise<string> {
    return this.getDrawerFormItem(label).locator('input').inputValue()
  }

  async submitDrawer() { await this.drawerConfirmBtn.click() }

  async closeDrawer() { await this.drawerCloseBtn.click() }

  async searchTable(code: string) {
    await this.searchCodeInput.fill(code)
    await this.searchBtn.click()
    await this.page.waitForResponse(r => r.url().includes('/list') && r.status() === 200)
  }

  getTableRow(code: string): Locator {
    return this.table.locator('tr.ant-table-row', { hasText: code })
  }

  async clickEditOnRow(code: string) {
    await this.getTableRow(code).getByRole('button', { name: '编辑' }).click()
    await this.page.waitForSelector('.ant-drawer')
  }

  async clickDeleteOnRow(code: string) {
    await this.getTableRow(code).getByRole('button', { name: '删除' }).click()
  }

  async confirmDelete() {
    await this.page.locator('.ant-modal-confirm-body').getByRole('button', { name: '确 认' }).click()
  }

  async expectSuccessMessage(text: string) {
    await expect(this.page.locator('.ant-message-success').filter({ hasText: text }).first()).toBeVisible()
  }

  async expectEmptyTable() {
    await expect(this.page.locator('.ant-empty-description').filter({ hasText: '暂无数据' })).toBeVisible()
  }
}

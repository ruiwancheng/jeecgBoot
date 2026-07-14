export interface WarehouseData {
  id?: string
  code: string
  name: string
  status?: number
  createBy?: string
  createTime?: string
}

let counter = 0

export function createWarehouse(overrides: Partial<WarehouseData> = {}): WarehouseData {
  counter++
  return { id: `warehouse-${counter}`, code: `WH-TEST-${String(counter).padStart(3, '0')}`, name: `测试仓库${counter}`, status: 1, createBy: 'admin', createTime: new Date().toISOString(), ...overrides }
}

export function createWarehouseList(count: number, overrides: Partial<WarehouseData> = {}): WarehouseData[] {
  return Array.from({ length: count }, (_, i) => createWarehouse({ id: `${i + 1}`, ...overrides }))
}

export function resetCounter() { counter = 0 }

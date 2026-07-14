import { setupServer } from 'msw/node'
import { warehouseHandlers } from './handlers/warehouse'

export const server = setupServer(...warehouseHandlers)

beforeAll(() => server.listen({ onUnhandledRequest: 'bypass' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

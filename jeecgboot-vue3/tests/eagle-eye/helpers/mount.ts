import { createPinia, setActivePinia } from 'pinia'
import type { Component } from 'vue'

export function createTestPinia() {
  const pinia = createPinia()
  setActivePinia(pinia)
  return pinia
}

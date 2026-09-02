import { describe, it, expect } from 'vitest'
import { greet } from '../src/greeting.js'

describe('greet', () => {
  it('greets by name', () => {
    expect(greet('Ada')).toBe('Hello, Ada.')
  })
  it('trims whitespace', () => {
    expect(greet('  Ada ')).toBe('Hello, Ada.')
  })
  it('rejects an empty name', () => {
    expect(() => greet('')).toThrow('name is required')
  })
})

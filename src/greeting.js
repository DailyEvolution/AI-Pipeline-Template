import { GREETING } from './copy/strings.js'

export function greet(name) {
  if (typeof name !== 'string' || name.trim() === '') {
    throw new Error('name is required')
  }
  return `${GREETING}, ${name.trim()}.`
}

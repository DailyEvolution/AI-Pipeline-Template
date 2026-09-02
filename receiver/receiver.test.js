import { test } from 'node:test'
import assert from 'node:assert/strict'
import { createHmac } from 'node:crypto'
import handler, { verify } from './receiver.js'

const env = { SENTRY_CLIENT_SECRET: 's3cret', GITHUB_REPO: 'org/repo', GITHUB_DISPATCH_TOKEN: 'tok' }
const payload = JSON.stringify({
  action: 'triggered',
  data: { issue: { id: 4242, title: 'TypeError: x is undefined', culprit: 'src/a.js', permalink: 'https://s/4242' } },
})
const sign = (body, secret) => createHmac('sha256', secret).update(body).digest('hex')
const req = (body, sig) => new Request('https://r/', { method: 'POST', body, headers: { 'sentry-hook-signature': sig } })

test('verify: constant-time compare accepts the right signature and rejects others', () => {
  assert.equal(verify(payload, sign(payload, 's3cret'), 's3cret'), true)
  assert.equal(verify(payload, sign(payload, 'wrong'), 's3cret'), false)
  assert.equal(verify(payload, '', 's3cret'), false)
})

test('bad signature: 401, and GitHub is never called', async () => {
  let called = false
  const res = await handler(req(payload, 'deadbeef'), env, async () => { called = true })
  assert.equal(res.status, 401)
  assert.equal(called, false)
})

test('good signature: dispatches exactly the allowed fields', async () => {
  let sent
  const res = await handler(req(payload, sign(payload, 's3cret')), env, async (url, init) => {
    sent = { url, init }
    return new Response('', { status: 204 })
  })
  assert.equal(res.status, 200)
  assert.equal(sent.url, 'https://api.github.com/repos/org/repo/dispatches')
  const body = JSON.parse(sent.init.body)
  assert.equal(body.event_type, 'sentry-alert')
  assert.deepEqual(Object.keys(body.client_payload).sort(), ['culprit', 'issue_id', 'release', 'title', 'url'])
  assert.equal(body.client_payload.issue_id, '4242')
})

test('title is bounded even when Sentry sends something enormous', async () => {
  const big = JSON.stringify({ data: { issue: { id: 1, title: 'x'.repeat(10000) } } })
  let body
  await handler(req(big, sign(big, 's3cret')), env, async (_u, init) => { body = JSON.parse(init.body); return new Response('', { status: 204 }) })
  assert.equal(body.client_payload.title.length, 200)
})

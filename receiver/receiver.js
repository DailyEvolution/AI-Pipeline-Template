// Sentry "issue alert" webhook -> GitHub repository_dispatch.
// Verifies the signature, forwards a fixed set of fields, returns.
// Deploy as a serverless function on whatever host you already use.
import { createHmac, timingSafeEqual } from 'node:crypto'

export function verify(raw, given, secret) {
  const expected = createHmac('sha256', secret).update(raw).digest('hex')
  const a = Buffer.from(given ?? '', 'utf8')
  const b = Buffer.from(expected, 'utf8')
  return a.length === b.length && timingSafeEqual(a, b)
}

export default async function handler(req, env = process.env, fetchImpl = fetch) {
  const raw = await req.text()
  if (!verify(raw, req.headers.get('sentry-hook-signature'), env.SENTRY_CLIENT_SECRET)) {
    return new Response('bad signature', { status: 401 })
  }

  const { data } = JSON.parse(raw)
  const issue = data?.issue ?? data?.event?.issue // shape varies by webhook type
  if (!issue?.id) return new Response('no issue in payload', { status: 400 })

  const res = await fetchImpl(`https://api.github.com/repos/${env.GITHUB_REPO}/dispatches`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.GITHUB_DISPATCH_TOKEN}`,
      Accept: 'application/vnd.github+json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      event_type: 'sentry-alert',
      client_payload: {
        issue_id: String(issue.id),
        title: String(issue.title ?? '').slice(0, 200),
        culprit: String(issue.culprit ?? ''),
        release: String(issue.firstRelease?.version ?? ''),
        url: String(issue.permalink ?? ''),
      },
    }),
  })
  return new Response(res.ok ? 'ok' : 'dispatch failed', { status: res.ok ? 200 : 502 })
}

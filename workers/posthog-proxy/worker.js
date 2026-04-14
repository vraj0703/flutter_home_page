/**
 * Cloudflare Worker — PostHog reverse proxy
 *
 * Routes: vishalraj.space/ingest/* → us.i.posthog.com/*
 * This bypasses ad blockers since requests go to the first-party domain.
 *
 * Deploy: wrangler deploy --name posthog-proxy
 * Route:  vishalraj.space/ingest/*
 */

const POSTHOG_HOST = 'us.i.posthog.com'

export default {
  async fetch(request) {
    const url = new URL(request.url)

    // Rewrite /ingest/... → us.i.posthog.com/...
    const pathname = url.pathname.replace(/^\/ingest/, '')
    const search = url.search

    const targetUrl = `https://${POSTHOG_HOST}${pathname}${search}`

    // Clone headers, set correct Host
    const headers = new Headers(request.headers)
    headers.set('Host', POSTHOG_HOST)

    const response = await fetch(targetUrl, {
      method: request.method,
      headers,
      body: request.method !== 'GET' ? request.body : undefined,
    })

    // CORS: allow both production and localhost origins
    const origin = request.headers.get('Origin') || ''
    const allowedOrigin = origin.includes('localhost') || origin.includes('vishalraj.space')
      ? origin
      : 'https://vishalraj.space'

    // Handle preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': allowedOrigin,
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
          'Access-Control-Max-Age': '86400',
        },
      })
    }

    const responseHeaders = new Headers(response.headers)
    responseHeaders.set('Access-Control-Allow-Origin', allowedOrigin)

    return new Response(response.body, {
      status: response.status,
      headers: responseHeaders,
    })
  },
}

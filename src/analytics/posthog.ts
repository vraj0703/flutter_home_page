/**
 * PostHog analytics — 5 core funnel events for portfolio conversion tracking.
 *
 * Setup: Sign up at https://app.posthog.com, create a project,
 * and replace the API key below.
 */
import posthog from 'posthog-js'

const POSTHOG_KEY = 'phc_yKgFcN6iPFfEXnSyJuVEfEpBvapnVs7J6JBGWyuvQvud'
const POSTHOG_HOST = 'https://us.i.posthog.com'

let initialized = false

/** Initialize PostHog — call once at app startup */
export function initAnalytics() {
  if (initialized || POSTHOG_KEY.startsWith('__')) return
  posthog.init(POSTHOG_KEY, {
    api_host: POSTHOG_HOST,
    capture_pageview: false,  // We track manually
    capture_pageleave: true,
    persistence: 'localStorage',
    autocapture: false,       // Manual events only
  })
  initialized = true
}

/** Track when the landing page (Flutter) is first seen */
export function trackLandingViewed() {
  if (!initialized) return
  posthog.capture('landing_viewed')
}

/** Track when user enters the 3D gallery (React) */
export function trackGalleryEntered() {
  if (!initialized) return
  posthog.capture('gallery_entered')
}

/** Track when a project frame is clicked in the gallery */
export function trackProjectClicked(projectId: string, projectTitle: string) {
  if (!initialized) return
  posthog.capture('project_clicked', { project_id: projectId, project_title: projectTitle })
}

/** Track when contact section is viewed */
export function trackContactViewed() {
  if (!initialized) return
  posthog.capture('contact_viewed')
}

/** Track when contact form is submitted */
export function trackContactSubmitted() {
  if (!initialized) return
  posthog.capture('contact_submitted')
}

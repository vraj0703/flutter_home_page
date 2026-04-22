/// <reference types="vite/client" />

// Injected by vite.config.ts `define` at build time — a short per-build
// identifier we append to the Flutter iframe src as a cache-busting query.
declare const __BUILD_ID__: string

declare module '*.frag?raw' {
  const value: string
  export default value
}

declare module '*.vert?raw' {
  const value: string
  export default value
}

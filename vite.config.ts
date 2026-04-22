import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { createReadStream, existsSync, statSync } from 'fs'
import { resolve } from 'path'

// Build-time constant injected into src/App.tsx's iframe src:
//   <FlutterEmbed src={`/flutter/index.html?v=${__BUILD_ID__}`} ... />
// Cache-busts the iframe request whenever we deploy — otherwise browsers
// that cached the pre-fix /flutter/index.html (the React fallback) under
// the previous 3600s max-age would keep serving the stale response for up
// to an hour even after we shortened Cache-Control. A new string per build
// forces a new URL, which forces a fresh request.
const BUILD_ID = Date.now().toString(36)

export default defineConfig({
  define: {
    __BUILD_ID__: JSON.stringify(BUILD_ID),
  },
  plugins: [
    react(),
    tailwindcss(),
    // Serve flutter/ files with correct MIME types before Vite's SPA fallback.
    // Without this, Vite serves index.html for .js/.wasm requests under /flutter/,
    // causing "Unexpected token '<'" errors.
    {
      name: 'serve-flutter-static',
      configureServer(server) {
        const mimeTypes: Record<string, string> = {
          html: 'text/html',
          js: 'application/javascript',
          mjs: 'application/javascript',
          json: 'application/json',
          wasm: 'application/wasm',
          css: 'text/css',
          png: 'image/png',
          jpg: 'image/jpeg',
          svg: 'image/svg+xml',
          ttf: 'font/ttf',
          otf: 'font/otf',
          woff: 'font/woff',
          woff2: 'font/woff2',
          mp3: 'audio/mpeg',
          ogg: 'audio/ogg',
          frag: 'text/plain',
        }

        server.middlewares.use((req, res, next) => {
          // Strip query params for file resolution (e.g. ?v=123 on service worker)
          const urlPath = (req.url || '').split('?')[0]

          // 1. Serve /flutter/* paths directly
          if (urlPath.startsWith('/flutter/')) {
            const filePath = resolve(__dirname, 'public', urlPath.slice(1))
            if (existsSync(filePath) && statSync(filePath).isFile()) {
              const ext = filePath.split('.').pop()
              res.setHeader('Content-Type', mimeTypes[ext || ''] || 'application/octet-stream')
              createReadStream(filePath).pipe(res)
              return
            }
          }

          // 2. Catch Flutter assets requested at root due to iframe base-href
          //    resolution issues (e.g. /main.dart.js, /flutter_service_worker.js).
          //    Redirect them to /flutter/ prefix.
          if (urlPath.match(/^\/(main\.dart\.(js|wasm)|flutter_service_worker\.js|flutter_bootstrap\.js|canvaskit\/)/)) {
            const flutterPath = resolve(__dirname, 'public/flutter', urlPath.slice(1))
            if (existsSync(flutterPath) && statSync(flutterPath).isFile()) {
              const ext = flutterPath.split('.').pop()
              res.setHeader('Content-Type', mimeTypes[ext || ''] || 'application/octet-stream')
              createReadStream(flutterPath).pipe(res)
              return
            }
          }

          next()
        })
      },
    },
  ],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes('three') || id.includes('@react-three')) return 'three'
          if (id.includes('gsap')) return 'gsap'
          if (id.includes('react-dom') || id.includes('react/')) return 'react'
        }
      }
    }
  },
  assetsInclude: ['**/*.frag', '**/*.vert'],
})

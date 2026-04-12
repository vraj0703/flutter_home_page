import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { createReadStream, existsSync, statSync } from 'fs'
import { resolve } from 'path'

export default defineConfig({
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
        manualChunks: {
          three: ['three', '@react-three/fiber', '@react-three/drei'],
          gsap: ['gsap'],
          react: ['react', 'react-dom']
        }
      }
    }
  },
  assetsInclude: ['**/*.frag', '**/*.vert'],
})

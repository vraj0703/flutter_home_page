import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { createReadStream, existsSync, statSync } from 'fs'
import { resolve } from 'path'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
    // Serve flutter/ files as raw static without Vite HTML transformation
    {
      name: 'serve-flutter-static',
      configureServer(server) {
        server.middlewares.use((req, res, next) => {
          if (req.url?.startsWith('/flutter/')) {
            const filePath = resolve(__dirname, 'public', req.url.slice(1))
            if (existsSync(filePath) && statSync(filePath).isFile()) {
              const ext = filePath.split('.').pop()
              const mimeTypes: Record<string, string> = {
                html: 'text/html',
                js: 'application/javascript',
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
                frag: 'text/plain',
              }
              res.setHeader('Content-Type', mimeTypes[ext || ''] || 'application/octet-stream')
              createReadStream(filePath).pipe(res)
              return
            }
          }
          next()
        })
      },
    },
  ],
  assetsInclude: ['**/*.frag', '**/*.vert'],
})

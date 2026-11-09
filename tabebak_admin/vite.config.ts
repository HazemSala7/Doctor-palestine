import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  // Served from a sub-folder on the same host as the Laravel backend.
  base: './',
  server: { port: 5173 },
})

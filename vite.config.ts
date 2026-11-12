import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  base: '/lms/',
  plugins: [react(), tailwindcss()],
  server: {
    proxy: {
      '/lms/api': {
        target: 'http://127.0.0.1',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/lms\/api/, '/LMS/public/api'),
      },
    },
  },
})
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  base: '/b1-learning-management/',
  plugins: [react(), tailwindcss()],
  server: {
    proxy: {
      '/b1-learning-management/api': {
        target: 'http://127.0.0.1',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/b1-learning-management\/api/, '/LMS/public/api'),
      },
    },
  },
})
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    proxy: {
      // Toutes les requêtes /api/* sont redirigées vers Spring Boot
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        // withCredentials côté axios suffit pour les cookies de session
      }
    }
  }
})

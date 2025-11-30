import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path' // ⬅️ Importa el módulo 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  
  // ⬅️ AÑADE ESTA SECCIÓN PARA EL ALIAS DE VITE 
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  // ---------------------------------------------
})
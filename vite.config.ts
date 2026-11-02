import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(), // <-- TailwindCSS v4 plugin
  ],
  resolve: {
    alias: {
      "@": import.meta.dirname + '/src',
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    minify: 'terser',
    terserOptions: {
      compress: { drop_console: true, drop_debugger: true },
    },
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (!id.includes('node_modules')) return
          if (id.includes('@supabase/')) return 'supabase-vendor'
          if (id.includes('react') || id.includes('scheduler')) return 'react-vendor'
          if (id.includes('lucide-react') || id.includes('sonner')) return 'ui-vendor'
        },
      },
    },
  },
})

import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { readFileSync } from 'node:fs'

const packageMetadata = JSON.parse(readFileSync(new URL('./package.json', import.meta.url), 'utf8'))

export default defineConfig({
  define: {
    'import.meta.env.ASE_WORK_VERSION': JSON.stringify(packageMetadata.version),
  },
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
    target: 'baseline-widely-available',
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

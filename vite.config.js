import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Tauri-recommended Vite settings: fixed dev port (tauri.conf.json's devUrl points at it), and
// don't let Vite obscure Rust build errors by clearing the terminal.
export default defineConfig({
  plugins: [react()],
  clearScreen: false,
  server: {
    port: 5183,
    strictPort: true,
  },
  envPrefix: ['VITE_', 'TAURI_'],
  build: {
    outDir: 'dist',
    target: 'es2021',
    minify: !process.env.TAURI_DEBUG ? 'esbuild' : false,
    sourcemap: !!process.env.TAURI_DEBUG,
  },
});

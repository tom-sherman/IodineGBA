import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { vanillaExtractPlugin } from '@vanilla-extract/vite-plugin';
import path from 'path';

export default defineConfig({
  root: './frontend',
  plugins: [react(), vanillaExtractPlugin()],
  resolve: {
    alias: {
      'sku/treat': path.resolve(__dirname, 'sku-treat-stub'),
      'sku/react-treat': 'react-treat',
    },
  },
  define: {
    'process.env': {},
  },
});

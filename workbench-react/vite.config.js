// vite.config.js - Optimized for GCP Workbench
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ mode }) => {
    const port = parseInt(process.env.VITE_PORT) || 3000

    return {
        plugins: [react()],

        server: {
            port: port,
            host: '0.0.0.0',
            strictPort: true,

            // HMR Configuration for GCP Workbench Proxy
            hmr: {
                // WebSocket through HTTPS proxy
                protocol: 'wss',
                clientPort: 443,
                // Let the proxy handle the path
                host: undefined,
                // Fallback to polling if WebSocket fails
                overlay: true,
            },

            // CORS for proxy compatibility
            cors: {
                origin: '*',
                methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
                credentials: true,
            },

            // Headers for proxy
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            },

            // Watch configuration
            watch: {
                usePolling: true,  // More reliable in container environments
                interval: 1000,
            },
        },

        // Preview server (for production builds)
        preview: {
            port: port,
            host: '0.0.0.0',
            strictPort: true,
        },

        // Build configuration
        build: {
            outDir: 'dist',
            sourcemap: mode === 'development',
            minify: mode === 'production' ? 'terser' : false,
        },

        // Resolve configuration
        resolve: {
            alias: {
                '@': '/src',
            },
        },

        // Define environment variables
        define: {
            __DEV__: mode === 'development',
        },
    }
})
# TalkDeskly Frontend Console Dashboard Deployment Guide

This guide details how to build and deploy the React-based administration dashboard and agent console.

---

## 🛠️ Compiling the Frontend Assets

The frontend is a React application built using Vite.

### Step 1: Install Dependencies
```bash
cd frontend
npm install
```

### Step 2: Compile Production Bundles
```bash
npm run build
```
*This compiles optimized static html, js, and css files inside the `frontend/dist/` directory.*

---

## 🚀 Deployment Options

### Option A: Served by Go Backend (Recommended)
If you deploy using the single-binary VM method or Docker stack, the Go backend is preconfigured to serve the compiled frontend folder from `./public/app/`.
1. Copy the contents of `frontend/dist/` into the backend server's `public/app/` folder.
2. The dashboard will be accessible directly on the root path of the Go backend:
   `https://chat.yourdomain.com/`

### Option B: Independent Static Web Hosting / CDN
To optimize delivery and reduce server resource usage, you can host the `frontend/dist/` files on a static provider (e.g. AWS S3, Cloudflare Pages, Netlify, or Nginx static server blocks):
1. Upload the files in `frontend/dist/` to your hosting provider.
2. Configure routing to rewrite all requests back to `/index.html` (since React uses client-side routing).
3. The dashboard will query the Go backend endpoint (`https://api.yourdomain.com`) over HTTP and WebSockets.

---

## 🌐 API Endpoint Resolution Flow

The frontend console connects to the backend dynamically based on compile-time environment modes:

* **Development Mode (`npm run dev`)**: Connects to the local host port `6721`.
  - API endpoint: `http://localhost:6721/api`
  - WebSockets endpoint: `ws://localhost:6721/ws`
* **Production Mode (`npm run build`)**: Uses relative paths to target the domain hosting the console:
  - API endpoint: `/api` (resolves relatively to `https://your-domain.com/api`)
  - WebSockets endpoint: `/ws` (resolves to `wss://your-domain.com/ws`)

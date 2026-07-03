# TalkDeskly Chat Bubble SDK & Demo Page Deployment Guide

This guide details how to build, deploy, and integrate both the **Chat Widget SDK Bundle** and its **Interactive Demo Testing Page** (whose content matches `docs/error.txt`).

---

## 📦 Anatomy of the Chat Bubble Build

When you compile the `chat-bubble` project (`npm run build`), the build system generates two key components inside the `chat-bubble/dist/` directory:

1. **The SDK Bundle (`sdk.js`)**: The compiled IIFE library that website owners load via `<script>` tags to inject the floating chat widget.
2. **The Demo testing page (`index.html`)**: The interactive HTML index page (containing the feature descriptions and instructions in `docs/error.txt`) used by developers and admins to test widget connectivity.

---

## 🛠️ Step 1: Compiling the SDK and Demo Page

To build both assets, navigate to the `chat-bubble` folder:
```bash
cd chat-bubble
npm install
npm run build
```
Vite will output:
* `dist/sdk.js` (The JavaScript library)
* `dist/index.html` (The interactive demo landing page)

---

## 🚀 Step 2: Hosting and Deployment Options

Depending on your production topology, select one of the following hosting models:

### Option A: Served by the Go Backend (Default / Automated)
The Go backend server is pre-configured to host both the SDK bundle and the demo page from its local `./public/sdk/` folder:
1. **Compilation**: Run the release CLI from the backend to automatically build and copy assets:
   ```bash
   cd backend
   go run main.go release --skip-docker --skip-version --force
   ```
2. **End-user URLs**:
   - **Demo Testing Page**: Accessible at `https://chat.yourdomain.com/sdk` (serves `index.html` which shows the welcome guides).
   - **SDK Bundle Script**: Embedded on client sites from `https://chat.yourdomain.com/sdk/sdk.js`.

### Option B: Standalone Static Web Hosting / CDN (e.g. AWS S3, Cloudflare Pages)
To decrease load on the backend VM, you can host the files in `chat-bubble/dist/` on a static platform:
1. Upload the entire `chat-bubble/dist/` folder to your CDN container (e.g. AWS S3 bucket).
2. **End-user URLs**:
   - **Demo Page**: `https://cdn.yourdomain.com/index.html`
   - **SDK Bundle**: `https://cdn.yourdomain.com/sdk.js`
3. Configure **CORS** headers on your Go backend server to accept requests originating from the CDN domain (see Nginx Reverse Proxy settings).

---

## 🔌 Step 3: Embedding the Chat Widget on Client Websites

### 🎯 Purpose
Once the TalkDeskly server is running (from Step 1-2), you need to **paste a code snippet into any website** so that visitors to that site will see a chat button in the corner of their screen → click it → chat directly with your support agents.

### 📋 Prerequisites Before Embedding

You need **2 values** before embedding:

| Value | Where to Find It | Example |
| :--- | :--- | :--- |
| **`inboxId`** | Admin Panel → Inboxes → Select an inbox → Copy UUID | `0831c7a7-bd57-4b05-a108-8b250f9abd6f` |
| **`baseUrl`** | The address of your running TalkDeskly server | Dev: `http://localhost:8080` · Prod: `https://chat.yourdomain.com` |

### 📝 Code Snippet to Copy

Copy only the block below (from `<div>` to `</script>`):

```html
<!-- TalkDeskly Chat Widget -->
<div id="talkdeskly-root"></div>
<script src="http://localhost:8080/sdk/sdk.js"></script>
<script>
  window.onload = function() {
    if (window.talkDeskly) {
      window.talkDeskly.init({
        inboxId: "0831c7a7-bd57-4b05-a108-8b250f9abd6f",
        baseUrl: "http://localhost:8080",
        position: "bottom-right",
        primaryColor: "#dc0462",
        zIndex: 9999
      });
    }
  };
</script>
```

> **Note**: The example above uses local development values. For production, replace `http://localhost:8080` with your real domain (e.g. `https://chat.yourdomain.com`).

### 📍 Where to Paste in Your HTML File

Open the HTML source of your website (e.g. `index.html`), find the closing `</body>` tag at the bottom, and paste the code snippet **directly above** it:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Your Website</title>
  </head>
  <body>

    <!-- Your existing website content (header, products, footer...) -->
    <header>...</header>
    <main>...</main>
    <footer>...</footer>

    <!-- ======================================================= -->
    <!-- PASTE THE TALKDESKLY CODE SNIPPET HERE                  -->
    <!-- ======================================================= -->
    <div id="talkdeskly-root"></div>
    <script src="http://localhost:8080/sdk/sdk.js"></script>
    <script>
      window.onload = function() {
        if (window.talkDeskly) {
          window.talkDeskly.init({
            inboxId: "0831c7a7-bd57-4b05-a108-8b250f9abd6f",
            baseUrl: "http://localhost:8080",
            position: "bottom-right",
            primaryColor: "#dc0462",
            zIndex: 9999
          });
        }
      };
    </script>
    <!-- ======================================================= -->

  </body>
</html>
```

### ✅ Expected Result

Save the file → refresh the page in your browser → you will see a **round chat button in the bottom-right corner** of the screen. Click it → the chat window opens → visitors can send messages → support agents receive them on the Agent Console (`http://localhost:3001`).

---

## ⚙️ `talkDeskly.init()` Configuration Parameters

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :---: | :--- | :--- |
| **`inboxId`** | `string` | **Yes** | *(None)* | The UUID of your inbox channel (found in Admin Panel → Inboxes). |
| **`baseUrl`** | `string` | **Yes** | *(None)* | The TalkDeskly server address (e.g. `http://localhost:8080` or `https://chat.yourdomain.com`). |
| **`position`** | `string` | No | `bottom-right` | Chat button placement: `bottom-right` or `bottom-left`. |
| **`primaryColor`** | `string` | No | `#dc0462` | Hex color code for the widget theme (e.g. `#0066ff` for blue). |
| **`zIndex`** | `number` | No | `9999` | CSS stacking order (higher number = displayed on top). |


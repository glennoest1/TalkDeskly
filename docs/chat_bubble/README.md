# TalkDeskly Chat Bubble (SDK) Deployment & Integration Guide

The `chat-bubble` is the customer-facing chat widget. It is compiled into static JavaScript and CSS assets, loaded directly on third-party websites, and queries the Go backend server over WebSockets and REST APIs to provide real-time messaging capabilities.

---

## 🏛️ SDK Integration Architecture

The widget connects directly to the central TalkDeskly backend server from the client's web browser:

```
+------------------+                    +--------------------+
|  Client Website  |                    | TalkDeskly Server  |
|  (Customer UI)   |                    | (Central Backend)  |
|                  |                    |                    |
|  +------------+  |  Loads Script File |  +--------------+  |
|  | Widget JS  |<-+--------------------+--| /sdk/index.js|  |
|  +-----+------+  |                    |  +--------------+  |
|        |         |                    |                    |
|        +---------+------------------->|  /api/ (HTTP)      |
|                  |   Queries & WS     |  /ws (WebSockets)  |
+------------------+                    +--------------------+
```

---

## 🛠️ Compiling the Chat Widget

The widget must be built before hosting. You can build it standalone or let the backend bundle it.

### Option 1: Standalone Compilation
If you are deploying the widget statically on a separate web server or CDN (e.g. AWS S3, Cloudflare Pages):
```bash
cd chat-bubble
npm install
npm run build
```
*This generates compiled production assets (HTML, CSS, JS, Assets) in the `chat-bubble/dist/` directory.*

### Option 2: Backend CLI Bundler (Recommended)
If you deploy using the single-binary VM method, the backend CLI handles building and copying:
```bash
cd backend
go run main.go release --skip-docker --skip-version --force
```
*This compiles the widget and places the static assets directly under the backend's `public/sdk/` folder.*

---

## 🚀 Hosting Options in Production

### Option A: Hosted by the Go Backend (Default)
When deploying via Docker Compose or Systemd, the Go server automatically mounts the `./public/` directory. The widget script is served at:
`https://chat.yourdomain.com/sdk/index.js` (or `/sdk/assets/...`)

### Option B: Independent CDN / Static Hosting (High Performance)
To decrease the load on your Go server and leverage low-latency edge servers, host the compiled contents of `chat-bubble/dist/` on a static web service:
1. Upload the files in `chat-bubble/dist/` to **AWS S3**, **Cloudflare Pages**, **Netlify**, or **Vercel**.
2. Configure your CDN to allow public access.
3. Access the widget script from your CDN URL (e.g. `https://cdn.yourdomain.com/index.js`).

---

## 🔌 Integrating the Widget on Client Websites

To embed the live chat widget on a website, paste the following HTML integration script block before the closing `</body>` tag:

```html
<!-- TalkDeskly Live Chat Widget -->
<div id="talkdeskly-root"></div>
<script src="https://chat.yourdomain.com/sdk/index.js"></script>
<script>
  window.onload = function() {
    if (window.talkDeskly) {
      window.talkDeskly.init({
        inboxId: "YOUR_INBOX_UUID_TOKEN",
        baseUrl: "https://chat.yourdomain.com",
        position: "bottom-right",
        primaryColor: "#dc0462",
        zIndex: 9999
      });
    }
  };
</script>
```

---

## ⚙️ Initialization Parameters Reference

The `window.talkDeskly.init` function accepts the following config properties:

| Parameter | Type | Required | Default Value | Description |
| :--- | :--- | :---: | :--- | :--- |
| **`inboxId`** | `string` | **Yes** | *(None)* | The unique UUID token representing your inbox channel (generated inside the Admin Panel). |
| **`baseUrl`** | `string` | **Yes** | *(None)* | The base endpoint domain of the TalkDeskly Go backend server. |
| **`position`** | `string` | No | `bottom-right` | Widget position on screen: `bottom-right` or `bottom-left`. |
| **`primaryColor`** | `string` | No | `#dc0462` | Brand color hex code applied to the widget elements. |
| **`zIndex`** | `number` | No | `9999` | Layer ordering index on the website. |

---

## 🔒 Security & CORS configuration

Since the chat bubble is embedded on a external website, browser security (CORS) rules require that:
1. The backend server permits Cross-Origin Requests. The Go application router is preconfigured with CORS support.
2. In Nginx, make sure the reverse proxy forwards the options requests:
   ```nginx
   add_header 'Access-Control-Allow-Origin' '*';
   add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';
   ```

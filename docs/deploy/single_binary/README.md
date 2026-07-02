# TalkDeskly VM & Single-Binary Deployment Guide

This guide walks through compiling all TalkDeskly components from source and deploying them as a single Go binary on a Linux VM using Systemd.

---

## Prerequisites

- A Linux VM (Ubuntu 22.04+ recommended)
- Go 1.21+ installed on the build machine
- Node.js 18+ & npm installed on the build machine
- PostgreSQL 16+ and Redis 7+ running on the target server

---

## Step 1: Compile Client Assets (Frontend & Chat Widget)

The backend includes a release CLI that compiles both the frontend dashboard and the chat widget SDK:

```bash
cd backend
go run main.go release --skip-docker --skip-version --force
```

**What this does:**
- Runs `npm install && npm run build` in [frontend/](../../../frontend/) → copies output to `backend/public/app/`
- Runs `npm install && npm run build` in [chat-bubble/](../../../chat-bubble/) → copies output to `backend/public/sdk/`

> **Alternative (manual build):**
> ```bash
> cd frontend && npm install && npm run build
> cp -r dist/ ../backend/public/app/
>
> cd ../chat-bubble && npm install && npm run build
> cp -r dist/ ../backend/public/sdk/
> ```

---

## Step 2: Compile the Go Backend Binary

From the `backend/` folder:
```bash
cd backend
go build -o talkdeskly main.go
```

**Output:** A `talkdeskly` binary in the `backend/` folder.

---

## Step 3: Prepare the Server Directory

Create the application directory on your target VM:
```bash
sudo mkdir -p /var/www/talkdeskly
```

Required directory structure:
```
/var/www/talkdeskly/
├── talkdeskly            # Compiled Go binary (Step 2)
├── .env                  # Environment config (Step 4)
├── public/               # Client assets (Step 1)
│   ├── app/              # Agent Console dashboard
│   └── sdk/              # Chat Widget SDK bundle
├── templates/            # Email HTML templates
└── i18n/                 # Translation files
```

Copy files from your build machine:
```bash
scp backend/talkdeskly user@server:/var/www/talkdeskly/
scp -r backend/public/ user@server:/var/www/talkdeskly/
scp -r backend/templates/ user@server:/var/www/talkdeskly/
scp -r backend/i18n/ user@server:/var/www/talkdeskly/
```

---

## Step 4: Create the Environment File

**File to create:** `/var/www/talkdeskly/.env`

```ini
PORT=8080
BASE_URL=https://chat.yourdomain.com
GO_ENV=production
LOG_LEVEL=info
JWT_SECRET=your-strong-random-secret-here
DATABASE_URL=postgres://user:password@localhost:5432/talkdeskly
REDIS_URL=redis://:password@localhost:6379/0
EMAIL_PROVIDER=smtp
EMAIL_HOST=smtp.mailgun.org
EMAIL_PORT=587
EMAIL_USERNAME=postmaster@yourdomain.com
EMAIL_PASSWORD=your-smtp-password
EMAIL_FROM=support@yourdomain.com
DEFAULT_LANGUAGE=en
SUPPORTED_LANGUAGES=en,vi
```

See the [Operations Guide](../operations/README.md) for a full list of all configuration variables.

---

## Step 5: Choose a Hosting Strategy

### Option A: All-in-One (Recommended)
The Go binary serves everything from a single process:
- **Agent Console:** `https://chat.yourdomain.com/` (serves `public/app/index.html`)
- **Chat Widget SDK:** `https://chat.yourdomain.com/sdk/sdk.js`
- **API:** `https://chat.yourdomain.com/api/...`
- **WebSocket:** `wss://chat.yourdomain.com/ws/...`

### Option B: CDN-Offloaded Static Assets
Host static folders on a CDN:
1. Upload `public/app/` to CDN (e.g. `https://console.yourdomain.com`)
2. Upload `public/sdk/` to CDN (e.g. `https://cdn.yourdomain.com`)
3. Configure CORS on backend to allow CDN origins

See the [Chat Widget Deployment Guide](../chat_bubble/README.md) for embedding instructions.

---

## Step 6: Create a Systemd Service

**File to create:** `/etc/systemd/system/talkdeskly.service`

```ini
[Unit]
Description=TalkDeskly Customer Support Platform
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/talkdeskly
ExecStart=/var/www/talkdeskly/talkdeskly
Restart=always
RestartSec=5
EnvironmentFile=/var/www/talkdeskly/.env
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

---

## Step 7: Start the Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable talkdeskly
sudo systemctl start talkdeskly
```

Verify:
```bash
sudo systemctl status talkdeskly
journalctl -u talkdeskly.service -f
```

---

## Step 8: Set Up Nginx Reverse Proxy

See the full Nginx configuration in the [Operations Guide](../operations/README.md#-2-nginx-reverse-proxy-ssl--websockets).

---

## Files Referenced in This Guide

| File | Purpose |
| :--- | :--- |
| [backend/](../../../backend/) | Go API server source code |
| [frontend/](../../../frontend/) | Agent Console React app |
| [chat-bubble/](../../../chat-bubble/) | Embeddable chat widget |
| `/var/www/talkdeskly/.env` | Production configuration |
| `/etc/systemd/system/talkdeskly.service` | Systemd process manager |
| [Operations Guide](../operations/README.md) | Nginx, backups, troubleshooting |
| [Chat Widget Guide](../chat_bubble/README.md) | Widget embedding instructions |

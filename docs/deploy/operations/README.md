# TalkDeskly Configuration, Proxy & Operations Guide

This guide covers environment configuration, Nginx reverse proxy setup, database CLI tools, backup scripts, and troubleshooting.

---

## 1. Environment Configuration

TalkDeskly reads configuration at startup in this priority order:
`Code Defaults` → `.env` file → `storage/config.json` override

### Environment Variable Reference

| Variable | Required | Default | Description |
| :--- | :---: | :--- | :--- |
| `PORT` | No | `8080` | HTTP server port |
| `BASE_URL` | **Yes** | — | Public URL of the backend (e.g. `https://chat.yourdomain.com`) |
| `GO_ENV` | No | `development` | `development` or `production` |
| `LOG_LEVEL` | No | `debug` | Log verbosity: `debug`, `info`, `warn`, `error` |
| `JWT_SECRET` | **Yes** | — | Secret key for JWT tokens (use `openssl rand -hex 32`) |
| `DATABASE_URL` | **Yes** | — | PostgreSQL connection string |
| `REDIS_URL` | **Yes** | — | Redis connection string |
| `EMAIL_PROVIDER` | No | `smtp` | Email backend (`smtp`) |
| `EMAIL_HOST` | **Yes** | — | SMTP server hostname |
| `EMAIL_PORT` | No | `587` | SMTP server port |
| `EMAIL_USERNAME` | No | — | SMTP authentication username |
| `EMAIL_PASSWORD` | No | — | SMTP authentication password |
| `EMAIL_FROM` | No | — | Sender "From" address |
| `DEFAULT_LANGUAGE` | No | `en` | Default UI language |
| `SUPPORTED_LANGUAGES` | No | `en` | Comma-separated language codes |

---

### Local Development `.env`

**File to edit:** [backend/.env](../../../backend/.env)

```ini
PORT=6721
BASE_URL=http://localhost:6721
GO_ENV=development
JWT_SECRET=secret
DATABASE_URL=postgres://postgres:postgres@localhost:5433/talkdeskly
REDIS_URL=localhost:6379
EMAIL_PROVIDER=smtp
EMAIL_HOST=localhost
EMAIL_PORT=1025
SUPPORTED_LANGUAGES=en,vi
DEFAULT_LANGUAGE=en
```

---

### Production `.env`

**File to create:** `.env` in the VM application directory (e.g. `/var/www/talkdeskly/.env`)

```ini
PORT=8080
BASE_URL=https://chat.yourdomain.com
GO_ENV=production
LOG_LEVEL=info
JWT_SECRET=f3b55c5e8de95821c97a5b399203a3d5e2e8b28cf9b3f4621cba1b9d4a8e2689
DATABASE_URL=postgres://talkdeskly_user:secure_pwd@db_ip:5432/talkdeskly_db
REDIS_URL=redis://:redis_pwd@cache_ip:6379/0
EMAIL_PROVIDER=smtp
EMAIL_HOST=smtp.mailgun.org
EMAIL_PORT=587
EMAIL_USERNAME=postmaster@yourdomain.com
EMAIL_PASSWORD=smtp_password_here
EMAIL_FROM=support@yourdomain.com
DEFAULT_LANGUAGE=en
SUPPORTED_LANGUAGES=en,vi
```

> **Important:** Replace all placeholder values with real credentials. Generate secrets with `openssl rand -hex 32`.

---

### Hardcoded Client URLs (Source Code)

When running in development mode, some connection URLs are hardcoded in the source code. If you change the backend port, you need to update these files:

| Component | File | Line | Default Value | What to Change |
| :--- | :--- | :---: | :--- | :--- |
| Chat Widget | [chat-bubble/app/sdk.tsx](../../../chat-bubble/app/sdk.tsx) | 44-55 | `ws://localhost:8080` (falls back to `VITE_WS_URL`) | `baseUrl` in the `import.meta.env.DEV` block |
| Chat Widget | [chat-bubble/app/lib/api/client.ts](../../../chat-bubble/app/lib/api/client.ts) | 8 | `http://localhost:8080/api` (falls back to `VITE_API_URL`) | Axios `baseURL` dev fallback |
| Agent Console | [frontend/src/lib/api/client.ts](../../../frontend/src/lib/api/client.ts) | 14 | `http://localhost:8080/api` (falls back to `VITE_API_URL`) | Axios `baseURL` dev fallback |
| Agent Console | [frontend/src/context/websocket-context.tsx](../../../frontend/src/context/websocket-context.tsx) | 13 | `ws://localhost:8080/ws` (falls back to `VITE_WS_URL`) | WebSocket URL dev fallback |

> **Note:** These files only affect **local development** mode. They dynamically read `VITE_API_URL` and `VITE_WS_URL` env variables from your `.env` files. In production, the frontend and widget automatically resolve URLs relatively from the server they are served from.

---

## 2. Nginx Reverse Proxy (SSL & WebSockets)

### Step 1: Install Nginx and Certbot

```bash
sudo apt install nginx certbot python3-certbot-nginx -y
```

### Step 2: Obtain SSL Certificate

```bash
sudo certbot --nginx -d chat.yourdomain.com
```

### Step 3: Create the Nginx Configuration

**File to create:** `/etc/nginx/sites-available/talkdeskly`

```nginx
limit_req_zone $binary_remote_addr zone=chat_limit:10m rate=15r/s;

server {
    listen 80;
    server_name chat.yourdomain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name chat.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/chat.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/chat.yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    # CORS Headers for chat-bubble embedding on external sites
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';

    # API & Static files
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket connections
    location /ws {
        limit_req zone=chat_limit burst=30 nodelay;
        proxy_pass http://localhost:8080/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
```

### Step 4: Enable the Site and Reload

```bash
sudo ln -s /etc/nginx/sites-available/talkdeskly /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 3. Database CLI Commands

The TalkDeskly binary includes built-in database management commands:

| Command | Description |
| :--- | :--- |
| `./talkdeskly migrate run` | Run all pending database migrations |
| `./talkdeskly db status` | Check database connection status |
| `./talkdeskly db info` | Show table names and row counts |
| `./talkdeskly migrate reset --force` | **Drop all tables** and re-run migrations (destructive!) |
| `./talkdeskly seed run` | Populate database with sample test data |

**In Docker dev mode**, prefix with `docker compose exec`:
```bash
docker compose -f docker-compose.dev.yml exec backend go run main.go migrate run
docker compose -f docker-compose.dev.yml exec backend go run main.go seed run
docker compose -f docker-compose.dev.yml exec backend go run main.go db info
```

---

## 4. Database Backups

### Step 1: Create the Backup Directory

```bash
sudo mkdir -p /var/backups/talkdeskly
```

### Step 2: Create the Backup Script

**File to create:** `/usr/local/bin/talkdeskly-backup.sh`

```bash
#!/bin/bash
pg_dump -U postgres -d talkdeskly | gzip > "/var/backups/talkdeskly/db_backup_$(date +%Y-%m-%d).sql.gz"
# Delete backups older than 30 days
find "/var/backups/talkdeskly" -type f -mtime +30 -name "*.sql.gz" -delete
```

### Step 3: Schedule with Cron

```bash
chmod +x /usr/local/bin/talkdeskly-backup.sh
crontab -e
# Add this line for daily backups at 2 AM:
0 2 * * * /usr/local/bin/talkdeskly-backup.sh
```

---

## 5. Troubleshooting

### Health Endpoint

Check if the backend is healthy:
```bash
curl https://chat.yourdomain.com/health
```
- **HTTP 200** = All systems operational
- **HTTP 503** = PostgreSQL or Redis connection failure

---

### WebSocket Disconnections (Error 1006)

**Symptom:** Chat widget or Agent Console loses connection intermittently.

**Cause:** Nginx closes idle connections too early.

**Fix:** Ensure these values are set in the Nginx `/ws` location block:
```nginx
proxy_read_timeout 86400s;
proxy_send_timeout 86400s;
```

---

### CORS Errors When Embedding Widget

**Symptom:** Browser console shows `Access-Control-Allow-Origin` errors.

**Fix:** Ensure the Nginx config includes CORS headers:
```nginx
add_header 'Access-Control-Allow-Origin' '*';
add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';
```

Or, if you want to restrict to specific domains:
```nginx
add_header 'Access-Control-Allow-Origin' 'https://yourwebsite.com';
```

---

### Database Connection Refused

**Symptom:** Backend logs show `connection refused` to PostgreSQL.

**Fix:**
1. Check that PostgreSQL is running: `sudo systemctl status postgresql`
2. Verify the `DATABASE_URL` in your `.env` file matches the actual host/port/credentials
3. Check PostgreSQL `pg_hba.conf` allows connections from the backend host

---

## Files Referenced in This Guide

| File | Purpose |
| :--- | :--- |
| [backend/.env](../../../backend/.env) | Backend environment configuration |
| [chat-bubble/app/sdk.tsx](../../../chat-bubble/app/sdk.tsx) | Chat widget WebSocket URL (dev mode) |
| [chat-bubble/app/lib/api/client.ts](../../../chat-bubble/app/lib/api/client.ts) | Chat widget API URL (dev mode) |
| [frontend/src/lib/api/client.ts](../../../frontend/src/lib/api/client.ts) | Agent Console API URL (dev mode) |
| [frontend/src/context/websocket-context.tsx](../../../frontend/src/context/websocket-context.tsx) | Agent Console WebSocket URL (dev mode) |
| `/etc/nginx/sites-available/talkdeskly` | Nginx reverse proxy config |
| `/usr/local/bin/talkdeskly-backup.sh` | Database backup cron script |

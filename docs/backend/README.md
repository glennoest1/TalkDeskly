# TalkDeskly Backend API Domain Deployment Guide

This guide details how to compile, configure, run, and maintain the TalkDeskly Go Backend API server in production.

---

## 🛠️ Compiling from Source

The backend is built as a compiled Go binary. 

### Step 1: Prepare Static Assets
Before compiling, ensure the frontend dashboard and chat-widget assets have been built and copied into the backend's `public/` directory (you can do this automatically via the release tool):
```bash
cd backend
go run main.go release --skip-docker --skip-version --force
```

### Step 2: Compile Go Binary
Statically build the Go executable:
```bash
go build -o talkdeskly main.go
```
*This compiles a `talkdeskly` binary (or `talkdeskly.exe` on Windows) in the current directory.*

---

## 📦 Required Production Directory Structure

Unlike standalone executables, the backend server serving routes expects specific assets at runtime. Ensure your deployment folder on the server contains the following structure:

```
/var/www/talkdeskly/
├── talkdeskly            # The compiled Go executable
├── .env                  # Environment configurations
├── public/               # Static UI assets (built in Step 1)
│   ├── app/              # React Agent Dashboard
│   └── sdk/              # Embeddable Chat Widget
├── templates/            # Email templates (HTML/MJML files)
└── i18n/                 # Backend translation files
```

---

## ⚙️ Lifecycle Service Config (Systemd)

On Linux virtual machines, configure a systemd daemon at `/etc/systemd/system/talkdeskly.service`:

```ini
[Unit]
Description=TalkDeskly Go API Daemon
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

Enable and start the service:
```bash
systemctl daemon-reload
systemctl enable talkdeskly
systemctl start talkdeskly
```

---

## 🗄️ Database Operations CLI

Manage your database schemas and initial seeds using CLI arguments:
```bash
# Run GORM AutoMigrations
./talkdeskly migrate run

# Check migration status
./talkdeskly migrate status

# Reset migrations (Drops all tables and data!)
./talkdeskly migrate reset --force

# Seed database with sample companies, admins, and chats
./talkdeskly seed run
```

---

## 🔍 Health Checks & Monitoring

The Go server exposes a lightweight health check endpoint at `/health`.
* **Request**: `GET http://localhost:8080/health`
* **Response**: Returns HTTP `200 OK` with connection statistics for PostgreSQL and Redis.
* **Failure**: Returns HTTP `503 Service Unavailable` if SQL or Redis fails to ping.

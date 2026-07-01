# TalkDeskly Single Binary Compilation & VM Deployment

This guide explains how to bundle the entire TalkDeskly system (Frontend React modules, widget, and Go APIs) into a single executable binary, and deploy it using Systemd on Linux servers.

---

## 🛠️ Compiling from Source

TalkDeskly provides a convenient release management CLI command that automatically compiles the frontend React dashboard and embeddable chat-bubble widget and bundles them in the backend's public directory. Follow these steps to generate the executable binary:

### Step 1: Run the Assets Bundler
The release utility automatically changes directory to the frontend and chat-bubble folders, installs dependencies, builds optimized bundles, and copies them to the backend's `public/` directory:
```bash
cd backend
go run main.go release --skip-docker --skip-version --force
```

### Step 2: Compile the Go Binary
Compile the Go backend into a statically-linked, high-performance executable:
```bash
go build -o talkdeskly main.go
```
*This compiles a `talkdeskly` binary (or `talkdeskly.exe` on Windows) in the `backend` folder.*

---

## 📦 Preparing the Deployment Directory

Unlike embedded-asset binaries, the Go web server dynamically serves UI assets, emails, and translations from local files. Therefore, your production deployment folder **must** contain the following structure:

```
/var/www/talkdeskly/
├── talkdeskly            # The compiled Go executable
├── .env                  # Production environmental configurations
├── public/               # Static client assets (built in Step 1)
│   ├── app/              # React Agent Dashboard
│   └── sdk/              # Embeddable Chat Widget
├── templates/            # Email templates (HTML/MJML files)
└── i18n/                 # Backend translations files
```

---

## ⚙️ Deploying on a Linux Virtual Machine (e.g. EC2, DigitalOcean)

### Step 1: Copy Assets to Host
Transfer the binary (`talkdeskly`) and `.env` file to your server folder (e.g. `/var/www/talkdeskly`).

### Step 2: Establish Service Daemon (Systemd)
Configure the operating system to manage the lifecycle of the process. Create a configuration file:

`/etc/systemd/system/talkdeskly.service`
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

### Step 3: Enable and Start Daemon
Run administrative terminal commands:
```bash
# Reload systemd configuration
systemctl daemon-reload

# Start the service
systemctl start talkdeskly

# Enable automatic boot-time launch
systemctl enable talkdeskly
```

### Step 4: Inspect Lifecycle logs
```bash
journalctl -u talkdeskly.service -f
```

# TalkDeskly Deployment Center

This directory contains configuration entry points and references for deploying TalkDeskly.

---

## 🚀 Quick Production Start (Docker Compose)

The fastest way to get TalkDeskly up and running in production is using Docker Compose:

1. **Configure Environment**: Create a `.env` file in the root directory:
   ```ini
   JWT_SECRET=use-a-strong-random-key
   POSTGRES_PASSWORD=use-a-secure-database-password
   BASE_URL=https://chat.yourdomain.com
   PORT=8080
   EMAIL_HOST=smtp.mailgun.org
   EMAIL_PORT=587
   EMAIL_USERNAME=postmaster@yourdomain.com
   EMAIL_PASSWORD=smtp-password
   EMAIL_FROM=support@yourdomain.com
   ```

2. **Launch Services**:
   ```bash
   docker compose -f docker-compose.prod.yml up -d
   ```

3. **Verify Containers**:
   ```bash
   docker compose -f docker-compose.prod.yml ps
   ```

---

## 📚 Detailed Deployment Documentation

The deployment documentation is split into modular guides located in the `docs` folder. Click on any link below to view:

* **[Local Development Setup](development.md)**: Setup Postgres, Redis, Mailhog, Go server, React dashboard, and chat widget locally.
* **[Docker Compose Deployment Guide](deployment_docker.md)**: Guide on pulling images, managing data persistent mounts, and starting compose stacks.
* **[Single Binary & VM Deployment Guide](deployment_binary.md)**: Steps to package front-end code and compile Go executable into a single binary, plus Linux Systemd scripts.
* **[Configuration Settings Reference](configuration.md)**: List of all env variable parameters and configuration priority details.
* **[Nginx Reverse Proxy & WebSocket Guide](nginx_proxy.md)**: Config for Nginx ssl certifications, security headers, rate limiting, and websocket upgrades.
* **[Maintenance, Backups & Troubleshooting](maintenance.md)**: Database migrations CLI, backup cron scripts, health monitoring, and standard error resolution guide.

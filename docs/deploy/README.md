# TalkDeskly Master Deployment Guide

Welcome to the TalkDeskly Deployment Center. This document serves as the master index for configuring and deploying TalkDeskly across different environments and component domains.

---

## 🗺️ Deployment Workflows (By Environment)

Select the setup workflow that matches your targeted environment:

### 1. [Local Development (Hybrid Setup)](../development/README.md)
* **What it does**: Runs PostgreSQL, Redis, and Mailhog in Docker, while running Go (via `air` hot-reloading) and React applications directly on your host machine.
* **Best for**: Active software development, debugging with breakpoints (Delve on port `2345`), and writing code.

### 2. [Dev/Staging Stack (Full Docker Dev Setup)](../development/README.md#🐳-approach-b-full-stack-dockerized-development-deploy-mode-dev)
* **What it does**: Runs the *entire* development stack (databases, backend server, frontend UI console, and widget script) inside container environments.
* **Best for**: Rapid setup without installing Go or Node.js on the host machine.

### 3. [Production Deployment (Docker Compose)](../deployment_docker/README.md)
* **What it does**: Spins up production-hardened PostgreSQL, Redis, and backend API containers. Exposes ports and mounts persistent volumes on the host system.
* **Best for**: Hosting on dedicated servers or containerized cloud infrastructure.

---

## 🏛️ Component Domain Guides (By Directory)

For details on compiling, packaging, and deploying individual domains, view their dedicated README folders:

### ⚙️ [Backend Go API Domain Deployment](../backend/README.md)
* **Contents**: Compiling the Go executable, structuring production folders (public assets, templates, translations), establishing VM Systemd services, database migration CLI subcommands, and health endpoints.

### 💻 [Frontend Dashboard React Domain Deployment](../frontend/README.md)
* **Contents**: Compiling React assets using Vite, serving static dashboard packages via the Go backend, deploying to separate CDN/Static servers, and client API endpoint resolution routing.

### 💬 [Chat Bubble SDK Widget Domain Deployment](../chat_bubble/README.md)
* **Contents**: Compiling the widget SDK script, Edge CDN and static hosting configurations, HTML website integration scripts, initialization parameters, and CORS security.

---

## 🔧 Global Server References

* **[Configuration Matrix & Files](../configuration/README.md)**: Templates for `.env` and `storage/config.json` parameters.
* **[Nginx Reverse Proxy Block](../nginx_proxy/README.md)**: Production configurations for SSL protocols, rate limits, and WebSocket connections.
* **[Maintenance, Backups & Recovery](../maintenance/README.md)**: Database migrations CLI, automatic backup cron scripts, health checks, and standard troubleshooting.

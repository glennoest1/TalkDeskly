# TalkDeskly Quick Deployment Index

This folder contains the complete configuration and deployment files for TalkDeskly.

---

## 🗺️ Deployment Workflows (By Setup Type)

Select the setup workflow that matches your targeted environment:

### 1. [Local Development (Hybrid Setup)](./local_development/README.md)
* **What it does**: Runs PostgreSQL, Redis, and Mailhog in Docker, while running Go (via `air` hot-reloading) and React applications directly on your host machine.
* **Best for**: Active software development, debugging with breakpoints (Delve on port `2345`), and writing code.

### 2. [Dev/Staging Stack (Full Docker Setup)](./local_development/README.md#🐳-approach-b-full-stack-dockerized-development-deploy-mode-dev)
* **What it does**: Runs the *entire* development stack (databases, backend server, frontend UI console, and widget script) inside container environments.
* **Best for**: Rapid setup without installing Go or Node.js on the host machine.

### 3. [Production Deployment (Docker Compose)](./docker_compose/README.md)
* **What it does**: Spins up production-hardened PostgreSQL, Redis, and backend API containers. Exposes ports and mounts persistent volumes on the host system.
* **Best for**: Hosting on dedicated servers or containerized cloud infrastructure.

### 4. [Production Deployment (Single Binary & VM)](./single_binary/README.md)
* **What it does**: Compiles client-side React bundles, triggers backend compilation, assets packaging, and runs via Systemd service daemons on VMs.
* **Best for**: Bare metal instances, VMs, or custom OS setups.

---

## 🏛️ Configuration & Operations

### 💬 [Chat Widget SDK Domain Deployment](./chat_bubble/README.md)
* **Contents**: Compiling the widget SDK script, Edge CDN and static hosting configurations, HTML website integration scripts, initialization parameters, and CORS security.

### 🔧 [Configuration, Proxy & Operations Guide](./operations/README.md)
* **Contents**: Detailed `.env` configuration files, Nginx SSL reverse proxy blocks, database CLI commands (migrations, seeds), backup cron scripts, and common troubleshooting solutions.

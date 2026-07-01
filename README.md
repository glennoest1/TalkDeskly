# TalkDeskly

Modern, real-time chat application with embeddable components. Built for scalability and seamless integration.

TalkDeskly is a single-binary application built with Go and React.

![TalkDeskly Demo](docs/images/hero.png)

Visit [talkdeskly.com](https://talkdeskly.com) for more info. Check out the [**Live demo**](https://demo.talkdeskly.com/).

> **CAUTION:** This project is currently in **development**. Features and APIs may change and are not yet fully tested.

## Features

- **Multi Channel Support**  
  Support for multiple communication channels. Currently live chat is available with more channels coming soon.
- **Admin/Agent Roles**  
  Role-based access control with distinct permissions for administrators and support agents.
- **Internationalization Support**  
  Multi-language support for global customer support teams and customers.
- **Canned Responses**  
  Save frequently used messages as templates for quick and consistent customer responses.
- **Live Chat SDK**  
  Easy-to-integrate SDK for embedding live chat functionality into any web application.
- **Audit System**  
  Complete activity tracking and logging for compliance, accountability, and performance monitoring.
- **Live Chat Widget Customization**  
  Fully customizable chat widget to match your brand colors, styling, and user experience.
- **Auto Assignments**  
  Intelligent conversation routing and automatic assignment to available agents based on custom rules.
- **Out of Hours Message**  
  Automated responses for customers contacting support outside business hours.
- **Pre-Chat Form**  
  Customizable forms to collect customer information before starting a chat session.

## 🚀 Deployment & Guides

TalkDeskly's deployment documentation is split into modular environment workflows and component domain folders:

### 🗺️ Environment Workflows
* **[Local Development Setup](docs/development/README.md)**: Instructions on running Postgres, Redis, Mailhog, Go server (`air`), React dashboard, and chat widget on localhost.
* **[Production Docker Compose Guide](docs/deployment_docker/README.md)**: Guide on pulling containers, configuring persistent mounts, and starting the production stack.

### 🏛️ Component Domain Guides
* **[Backend Go API Domain](docs/backend/README.md)**: Compiling Go, production folder structure, systemd configuration, migrations CLI, and monitoring.
* **[Frontend Dashboard React Domain](docs/frontend/README.md)**: Compiling Vite bundles, static hosting options (Go server vs CDN), and endpoint resolution flow.
* **[Chat Bubble SDK Widget Domain](docs/chat_bubble/README.md)**: Compiling, Edge CDN hosting, HTML integration snippet, configuration variables, and CORS.

### 🔧 Global Server References
* **[Configuration reference guide](docs/configuration/README.md)**: Templates for `.env` and `storage/config.json`.
* **[Nginx Reverse Proxy block](docs/nginx_proxy/README.md)**: Production settings for SSL, rate-limiting, and WebSockets.
* **[System Maintenance guide](docs/maintenance/README.md)**: CLI database commands, database backup cron tasks, and troubleshooting.


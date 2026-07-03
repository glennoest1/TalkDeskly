# TalkDeskly

Modern, real-time chat application with embeddable components. Built for scalability and seamless integration.

TalkDeskly is a single-binary application built with Go and React.

![TalkDeskly Demo](docs/images/hero.png)

Visit [talkdeskly.com](https://talkdeskly.com) for more info. Check out the [**Live demo**](https://demo.talkdeskly.com/).

> **CAUTION:** This project is currently in **development**. Features and APIs may change and are not yet fully tested.

## Deploy And Run

Run deployment commands through the root `Makefile`. This is the supported entry point for every mode.

```bash
make local
make dev
make prod
```

Choose the mode from the deployment guide that matches what you need:

| Mode | Main command | Use when | Guide |
| --- | --- | --- | --- |
| Local host-run | `make local` | Backend, frontend, and chat widget run as host processes; dependency services run in Docker. | [Local deployment](docs/local/local-deployment.md) |
| Docker development | `make dev` | Backend, frontend, chat widget, Postgres, Redis, and MailHog all run in Docker for development. | [Development deployment](docs/dev/development-deployment.md) |
| Production-style | `make prod` | Frontend and widget assets are built into the backend image and run with production Compose. | [Production deployment](docs/prod/production-deployment.md) |

Common Makefile commands:

```bash
make local-status
make dev-logs
make dev-seed
make dev-restart
make dev-reset SERVICE=backend
make prod-build
make deploy MODE=dev ACTION=status
```

## Deployment Documentation

Start with [docs/README.md](docs/README.md) if you are not sure which mode to use.

| Document | What it covers |
| --- | --- |
| [Deployment overview](docs/README.md) | Mode comparison, communication architecture, quick commands, and first-run paths. |
| [Deployment scripts](docs/deployment-scripts.md) | Makefile targets, script modules, supported options, E2E checks, and troubleshooting. |
| [Local deployment](docs/local/local-deployment.md) | Host-run local setup and testing flow. |
| [Development deployment](docs/dev/development-deployment.md) | Docker Compose development setup and chat widget test flow. |
| [Production deployment](docs/prod/production-deployment.md) | Production-style Compose setup, build flow, config requirements, and validation. |

The Makefile calls `scripts/deploy-dispatcher.sh`, which routes to the Bash mode scripts in `scripts/deploy-local.sh`, `scripts/deploy-dev.sh`, and `scripts/deploy-prod.sh`.

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
